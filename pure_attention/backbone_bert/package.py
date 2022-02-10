# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/25
#
""""""
import json

import torch


class BertConfig:
    def __init__(self, config_json_file):
        """
        定制化的 config，__getattr__ 处进行判断，可以方便的进行 config.xxx 操作，并兼容不存在的情况。
        """
        with open(config_json_file, "r", encoding='utf-8') as reader:
            json_config = json.loads(reader.read())
        for key, value in json_config.items():
            self.__dict__[key] = value

    def __getattr__(self, key):
        if key in self.__dict__:
            return self.__dict__[key]
        return None


class BertOutput:
    def __init__(self, last_hidden_state: torch.FloatTensor, pooler_output: torch.FloatTensor):
        self.last_hidden_state = last_hidden_state
        self.pooler_output = pooler_output


class TokenizerOutput:
    def __init__(self, token_ids, segment_ids=None, attention_mask=None):
        # 以下写法是等价的
        self.input_ids = token_ids
        self.token_type_ids = segment_ids
        self.attention_mask = attention_mask
