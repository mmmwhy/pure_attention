# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/19
#
"""
我们自己实现一个 layerNorm， 注意 layerNorm 是对每一条数据进行 Norm，而不是每一批数据，这两个很像，但是作用纬度不一样。
在 NLP 任务中，我们使用 layerNorm 比较多，因为是：

1、文本自身是变长的，max_length 为 512 的话，可能大部分的数据都只有几十个字。那么让这几十个字以及大批的 padding 进行 norm 是不合理的。
2、batchNorm 中的 平均值 和 方差，是在训练任务中学到的。 然后推理的时候，根据训练任务中学到的平均值和方法来使用，比如 cv 中常见的 transforms.Normalize。
如果使用 layerNorm 的话，就不需要提前计算好平均值和方法，每句话输入进来的时候，单独计算就可以了。
对于变长文本预测来说，这样其实更合理一些。
3、自己实现 layerNorm 还可以方便后续进行一些细小的优化。
4、参考 https://iii.run/archives/fae41911210f.html 实现

"""

import torch
import torch.nn as nn


class LayerNorm(nn.Module):
    def __init__(self, hidden_size, eps=1e-12):
        super(LayerNorm, self).__init__()
        self.weight = nn.Parameter(torch.ones(hidden_size))
        self.bias = nn.Parameter(torch.zeros(hidden_size))
        self.eps = eps

    def forward(self, x):
        u = x.mean(-1, keepdim=True)
        s = (x - u).pow(2).mean(-1, keepdim=True)
        x = (x - u) / torch.sqrt(s + self.eps)
        return self.weight * x + self.bias
