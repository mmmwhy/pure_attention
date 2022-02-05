# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/08
#
"""
实现 transformer 的 encode 部分
"""
from torch import nn

from pure_attention.base_transformer.layers import HalfFeedForward, AddNorm, AttentionAddNorm


class EncoderLayer(nn.Module):
    """
    注意这个结构和 bert 的结构完全一致, 在 bert 中被称作 BertLayer。
    """

    def __init__(self, config):
        super(EncoderLayer, self).__init__()
        # Multi-Head Attention
        self.attention = AttentionAddNorm(config)

        # Feed Forward + Add & Norm
        self.intermediate = HalfFeedForward(config)
        self.output = AddNorm(config.intermediate_size, config.hidden_size,
                              config.hidden_dropout_prob, config.layer_norm_eps)

    def forward(self, query_tensor, key_tensor, value_tensor, attention_mask=None):
        # Multi-Head Attention
        attention_output = self.attention(query_tensor, key_tensor, value_tensor, attention_mask)

        # Feed Forward + Add & Norm
        intermediate_output = self.intermediate(attention_output)
        layer_output = self.output(intermediate_output, attention_output)

        return layer_output


class Encoder(nn.Module):
    def __init__(self, config):
        super(Encoder, self).__init__()
        # PyTorch 中的 ModuleList https://zhuanlan.zhihu.com/p/64990232
        self.layer = nn.ModuleList([EncoderLayer(config) for _ in range(config.num_hidden_layers)])

    def forward(self, hidden_states, attention_mask=None):
        for layer_module in self.layer:
            # encode 部分是 self-attention ，qkv 来源一致
            hidden_states = layer_module(hidden_states, hidden_states, hidden_states, attention_mask)

        return hidden_states
