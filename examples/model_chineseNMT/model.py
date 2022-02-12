# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/02/08
#
""""""

from torch import nn

from pure_attention.base_transformer.decoder import Decoder
from pure_attention.base_transformer.encoder import Encoder
from pure_attention.base_transformer.layers import InputEmbeddings


class Seq2SeqModel(nn.Module):
    def __init__(self, config):
        super(Seq2SeqModel, self).__init__()
        self.encoder = Encoder(config)
        self.decoder = Decoder(config)

        """
        翻译任务中共享 src 和 tgt 的 InputEmbedding 权重，原因如下：
        1、我希望加载 bert 的预训练权重；
        2、中文内会混合英文，此时的英文在 src 和 tgt 表意应当是相同的；
        """
        self.embedding = InputEmbeddings(config)

        self.proj = nn.Linear(config.hidden_size, config.vocab_size)
        self.init_weights()

    def init_weights(self):
        self.apply(self._init_weights)

    def _init_weights(self, module):
        """ Initialize the weights """
        if isinstance(module, (nn.Linear, nn.Embedding)):
            module.weight.data.normal_(mean=0.0, std=1e-12)
        elif isinstance(module, nn.LayerNorm):
            module.bias.data.zero_()
            module.weight.data.fill_(1.0)
        if isinstance(module, nn.Linear) and module.bias is not None:
            module.bias.data.zero_()

    def encode(self, src, src_mask):
        # tgt shape 调整为 [batch_size, src_size]
        return self.encoder(self.embedding(src), src_mask)

    def decode(self, enc_output, src_mask, tgt, tgt_mask):
        # tgt shape 调整为 [batch_size, tgt_size]
        return self.decoder(self.embedding(tgt), enc_output, src_mask, tgt_mask)

    def forward(self, src, tgt, src_mask, tgt_mask):
        # encoder 的结果作为 decoder 的 enc_output 参数传入，进行 decode
        dec_output = self.decode(self.encode(src, src_mask), src_mask, tgt, tgt_mask)

        # decode 后的结果，先进入一个全连接层变为词典大小的向量，然后进行 log_softmax 操作 (在 softmax 结果上再做多一次 log 运算)
        # log_softmax 与 softmax 的区别在哪里？ https://www.zhihu.com/question/358069078
        return nn.LogSoftmax(dim=-1)(self.proj(dec_output))
