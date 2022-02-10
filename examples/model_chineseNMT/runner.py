# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/08
#
""""""
import numpy as np
import torch
from torch.cuda.amp import autocast, GradScaler
from torch.utils.data import DataLoader

from examples.model_chineseNMT.datasets import ChineseNMTDataset
from examples.model_chineseNMT.model import Seq2SeqModel
from pure_attention.backbone_bert.package import BertConfig
from pure_attention.utils.logger import init_logger


class Runner:
    def __init__(self, config):
        self.logger = init_logger(self.__class__.__name__)

        self.train_epochs_num = 15

        self.dataloader = DataLoader(
            ChineseNMTDataset(),
            shuffle=True,
            batch_size=256,
            num_workers=16,
            pin_memory=True
        )
        self.device = 'cuda:0' if torch.cuda.is_available() else 'cpu'
        self.model = torch.nn.DataParallel(Seq2SeqModel(config), device_ids=list(range(torch.cuda.device_count()))).to(
            self.device)
        self.optimizer = torch.optim.Adam(self.model.parameters(), lr=0.0001, betas=(0.9, 0.98), eps=1e-9)
        self.criterion = torch.nn.CrossEntropyLoss(ignore_index=0).cuda()

    def train(self):
        scaler = GradScaler()
        for epoch in range(self.train_epochs_num):
            for step, row in enumerate(self.dataloader):
                self.optimizer.zero_grad()
                with autocast():
                    result = self.model(
                        row["src_text"].to(self.device), row["tgt_text"].to(self.device),
                        row["src_mask"].unsqueeze(1).to(self.device), row["tgt_mask"].unsqueeze(1).to(self.device)
                    )
                    loss = self.criterion(result.view(-1, result.size(-1)), row["tgt_true"].view(-1).to(self.device))
                scaler.scale(loss).backward()
                scaler.step(self.optimizer)
                scaler.update()

                self.logger.info(
                    f"Epoch: {epoch} / {self.train_epochs_num}, "
                    f"Step: {step} / {len(self.dataloader)}, "
                    f"Loss: {np.mean(loss.item())}, "
                    f"Lr: {self.optimizer.param_groups[0]['lr']}"
                )

    def run(self):
        self.train()


# python -m model_chineseNMT.runner
if __name__ == "__main__":
    config = BertConfig("/data/pretrain_modal/bert-base-chinese/config.json")
    runner = Runner(config)
    runner.run()
