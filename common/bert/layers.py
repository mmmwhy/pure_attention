# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/19
#
""""""
import torch
from torch import nn

class LayerNorm(nn.Module):
    def __init__(self, hidden_size, eps=1e-12):
        """ layernorm 层，也可使用 pytorch 自带的 layernorm。
        可参考 https://iii.run/archives/fae41911210f.html 实现
        """
        super(LayerNorm, self).__init__()
        self.weight = nn.Parameter(torch.ones(hidden_size))
        self.bias = nn.Parameter(torch.zeros(hidden_size))
        self.eps = eps

    def forward(self, x):
        mean = x.mean(-1, keepdim=True)
        std = x.std(-1, keepdim=True)
        return self.weight * (x - mean) / torch.sqrt(std + self.eps) + self.bias
