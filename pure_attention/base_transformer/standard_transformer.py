# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/08
#
"""
完整的 transformer 结构
"""
from torch import nn
from pure_attention.base_transformer.layers import InputEmbeddings
from pure_attention.base_transformer.encoder import Encoder
from pure_attention.base_transformer.decoder import Decoder


class Transformer(nn.Module):
    def __init__(self, config):
        super(Transformer, self).__init__()
        self.encoder = Encoder(config)
        self.decoder = Decoder(config)

        self.src_embed = InputEmbeddings(config, config.src_vocab_size)
        self.tgt_embed = InputEmbeddings(config, config.tgt_vocab_size)

        self.proj = nn.Linear(config.hidden_size, config.tgt_vocab_size)

    def encode(self, src, src_mask):
        return self.encoder(self.src_embed(src), src_mask)

    def decode(self, enc_output, src_mask, tgt, tgt_mask):
        return self.decoder(self.tgt_embed(tgt), enc_output, src_mask, tgt_mask)

    def forward(self, src, tgt, src_mask, tgt_mask):
        # encoder 的结果作为 decoder 的 enc_output 参数传入，进行 decode
        dec_output = self.decode(self.encode(src, src_mask), src_mask, tgt, tgt_mask)

        # decode 后的结果，先进入一个全连接层变为词典大小的向量，然后进行 log_softmax 操作 (在 softmax 结果上再做多一次 log 运算)
        # log_softmax 与 softmax 的区别在哪里？ https://www.zhihu.com/question/358069078
        return nn.LogSoftmax(dim=-1)(self.proj(dec_output))
