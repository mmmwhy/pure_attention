# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/08
#
""""""
import json

import torch
from torch.utils.data import Dataset

from pure_attention.common.nlp_tokenization import Tokenizer
from pure_attention.utils.logger import init_logger


class DatasetOut:
    def __init__(self, src_text, src_mask, tgt_text, tgt_true, tgt_mask):
        # 需要返回这些
        self.src_text = src_text
        self.src_mask = src_mask
        self.tgt_text = tgt_text
        self.tgt_true = tgt_true
        self.tgt_mask = tgt_mask


class ChineseNMTDataset(Dataset):
    def __init__(self, mode: str = None):
        super(ChineseNMTDataset).__init__()
        self.logger = init_logger(__name__)
        self.tokenizer = Tokenizer("/data/pretrain_modal/bert-base-chinese/vocab.txt")
        self.sentence_pair = json.load(open(f"/data/WMT_2018_Chinese_English/json/{mode}.json", 'r'))

    def __len__(self) -> int:
        return len(self.sentence_pair)

    def __getitem__(self, idx: int):
        english_tokenizer = self.tokenizer.encode(self.sentence_pair[idx][0], max_len=64)
        chinese_tokenizer = self.tokenizer.encode(self.sentence_pair[idx][1], max_len=64)

        src_text = english_tokenizer.input_ids[0]
        src_mask = (1.0 - english_tokenizer.attention_mask) * -10000.0

        # decode 的时候 target 的输入部分
        tgt_text = chinese_tokenizer.input_ids[0, :-1]
        # decode 的时候应预测输入的 target 结果
        tgt_true = chinese_tokenizer.input_ids[0, 1:]
        # 只有输入的部分需要 attention_mask
        tgt_mask = (1 - (chinese_tokenizer.attention_mask[:, :-1] & self.subsequent_mask(tgt_text.size(-1)))) * -10000.0

        return {"src_text": src_text, "src_mask": src_mask,
                "tgt_text": tgt_text, "tgt_true": tgt_true, "tgt_mask": tgt_mask}

    @classmethod
    def subsequent_mask(cls, size):
        # 下三角结构
        return (torch.triu(torch.ones((size, size), dtype=torch.long))).transpose(0, 1)
