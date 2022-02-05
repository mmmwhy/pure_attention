# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/07
#
"""
实现 transformer 的 decode 部分
"""
from torch import nn

from pure_attention.base_transformer.layers import HalfFeedForward, AddNorm, AttentionAddNorm


class DecoderLayer(nn.Module):
    def __init__(self, config):
        super(DecoderLayer, self).__init__()
        # Masked Multi-head Attention
        self.self_attn = AttentionAddNorm(config)

        # Multi-Head Attention
        self.enc_attn = AttentionAddNorm(config)

        # Feed Forward + Add & Norm
        self.intermediate = HalfFeedForward(config)
        self.output = AddNorm(config.intermediate_size, config.hidden_size,
                              config.hidden_dropout_prob, config.layer_norm_eps)

    def forward(self, dec_input, enc_output, slf_attn_mask, dec_enc_attn_mask):
        # Masked Multi-head Attention
        dec_self_attn = self.self_attn(dec_input, dec_input, dec_input, dec_enc_attn_mask)

        # Multi-Head Attention
        dec_enc_attn = self.enc_attn(dec_self_attn, enc_output, enc_output, slf_attn_mask)

        # Feed Forward + Add & Norm
        intermediate_output = self.intermediate(dec_enc_attn)
        layer_output = self.output(intermediate_output, dec_enc_attn)

        return layer_output


class Decoder(nn.Module):
    def __init__(self, config):
        super(Decoder, self).__init__()
        # PyTorch 中的 ModuleList https://zhuanlan.zhihu.com/p/64990232
        self.layer = nn.ModuleList([DecoderLayer(config) for _ in range(config.num_hidden_layers)])

    def forward(self, dec_input, enc_output, slf_attn_mask, dec_enc_attn_mask):
        for layer_module in self.layer:
            dec_input = layer_module(dec_input, enc_output, slf_attn_mask, dec_enc_attn_mask)
        return dec_input
