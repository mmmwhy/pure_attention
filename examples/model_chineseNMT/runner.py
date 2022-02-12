# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/08
#
""""""
import os
import sys
# 寻找根目录
sys.path.append(os.path.abspath(__file__).split("examples")[0])  # noqa E402

import argparse
import numpy as np
import torch
import torch.distributed as dist
from torch.cuda.amp import autocast, GradScaler
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.utils.data import DataLoader
from torch.utils.data.distributed import DistributedSampler

from examples.model_chineseNMT.datasets import ChineseNMTDataset
from examples.model_chineseNMT.model import Seq2SeqModel
from pure_attention.backbone_bert.package import BertConfig
from pure_attention.common.schedule import get_cosine_schedule_with_warmup
from pure_attention.utils.logger import init_logger

# DDP：从外部得到local_rank参数
parser = argparse.ArgumentParser()
parser.add_argument("--local_rank", default=-1, type=int)
FLAGS = parser.parse_args()
local_rank = FLAGS.local_rank

# DDP：DDP backend初始化
torch.cuda.set_device(local_rank)
dist.init_process_group(backend='nccl')  # nccl是GPU设备上最快、最推荐的后端


class Runner:
    def __init__(self, config):
        self.logger = init_logger(self.__class__.__name__)

        self.train_epochs_num = 15
        self.batch_size = 64

        self.device = 'cuda:0' if torch.cuda.is_available() else 'cpu'
        self.gpu_list = list(range(torch.cuda.device_count()))

        self.num_works = len(self.gpu_list) * 4

        train_dataset = ChineseNMTDataset("train")
        train_sampler = DistributedSampler(train_dataset)
        self.train_dataloader = DataLoader(train_dataset, batch_size=self.batch_size,
                                           sampler=train_sampler, num_workers=self.num_works, pin_memory=True)

        eval_dataset = ChineseNMTDataset("dev")
        eval_sampler = DistributedSampler(eval_dataset)
        self.eval_dataloader = DataLoader(eval_dataset, batch_size=self.batch_size,
                                          sampler=eval_sampler, num_workers=self.num_works)

        self.total_step = len(self.train_dataloader) * self.train_epochs_num
        model = Seq2SeqModel(config).to(local_rank)
        self.ddp_model = DDP(model, device_ids=[local_rank], output_device=local_rank)
        self.optimizer = torch.optim.Adam(self.ddp_model.parameters(), lr=0.0001, betas=(0.9, 0.98), eps=1e-9)
        self.scheduler = get_cosine_schedule_with_warmup(
            optimizer=self.optimizer,
            num_warmup_steps=int(0.1 * self.total_step),
            num_training_steps=self.total_step
        )
        self.criterion = torch.nn.CrossEntropyLoss(ignore_index=0).to(local_rank)
        self.scaler = GradScaler()
        self.start_epoch = 0

    def run_epoch(self, dataloader, now_epoch, all_epoch):
        # let all processes sync up before starting with a new epoch of training
        # 不清楚 dist.barrier() 和 trainloader.sampler.set_epoch 的差异 todo @mmmwhy
        dataloader.sampler.set_epoch(now_epoch)
        for step, row in enumerate(dataloader):
            self.optimizer.zero_grad()
            with autocast():
                result = self.ddp_model(
                    row["src_text"].to(local_rank), row["tgt_text"].to(local_rank),
                    row["src_mask"].unsqueeze(1).to(local_rank), row["tgt_mask"].unsqueeze(1).to(local_rank)
                )
                loss = self.criterion(result.view(-1, result.size(-1)), row["tgt_true"].view(-1).to(local_rank))
            self.scaler.scale(loss).backward()
            self.scaler.step(self.optimizer)
            self.scaler.update()

            self.scheduler.step()

            self.logger.info((
                "Epoch: {epoch:03d} / {all_epoch:03d},"
                "Step: {step:04d} / {all_step:04d},"
                "Loss: {loss:.04f},"
                "Lr: {lr:.08f}".format(epoch=now_epoch, all_epoch=all_epoch,
                                       step=step, all_step=len(dataloader),
                                       loss=np.mean(loss.item()),
                                       lr=self.optimizer.param_groups[0]['lr'])))

    def train(self):
        for now_epoch in range(self.start_epoch, self.train_epochs_num):

            # 训练模型
            self.ddp_model.train()
            self.run_epoch(self.train_dataloader, now_epoch, self.train_epochs_num)

            # 验证模型效果
            self.ddp_model.eval()
            self.run_epoch(self.eval_dataloader, 1, 1)

    def run(self):
        self.train()


# nohup python -m examples.model_chineseNMT.runner 1>train.log 2>&1 &
# python -m torch.distributed.launch --nproc_per_node 8 examples/model_chineseNMT/runner.py
# tail -f train.log
if __name__ == "__main__":
    config = BertConfig("/data/pretrain_modal/bert-base-chinese/config.json")
    runner = Runner(config)
    runner.run()
