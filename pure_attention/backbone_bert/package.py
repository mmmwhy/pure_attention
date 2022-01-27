# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/25
#
""""""
import json
from typing import Optional, Tuple

import torch


class BertConfig:
    def __init__(self, vocab_size_or_config_json_file):
        """
        定制化的 config，__getattr__ 处进行判断
        """
        with open(vocab_size_or_config_json_file, "r", encoding='utf-8') as reader:
            json_config = json.loads(reader.read())
        for key, value in json_config.items():
            self.__dict__[key] = value

    def __getattr__(self, key):
        if key in self.__dict__:
            return self.__dict__[key]
        return None


class BertOutput:
    last_hidden_state: torch.FloatTensor = None
    pooler_output: torch.FloatTensor = None
    attentions: Optional[Tuple[torch.FloatTensor]] = None

    def __init__(self, last_hidden_state, pooler_output, attentions):
        self.last_hidden_state = last_hidden_state
        self.pooler_output = pooler_output
        self.attentions = attentions
