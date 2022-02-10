# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: mmmwhy <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/22
#
""""""
import os

import torch
from torch import nn

from pure_attention.backbone_bert.package import BertConfig, BertOutput
from pure_attention.base_transformer.encoder import Encoder
from pure_attention.base_transformer.layers import InputEmbeddings


class BertPooler(nn.Module):
    def __init__(self, config):
        super(BertPooler, self).__init__()
        self.dense = nn.Linear(config.hidden_size, config.hidden_size)
        self.activation = nn.Tanh()

    def forward(self, hidden_states):
        # 只取出第一个 token 也就是 cls 位置上的 embedding 进行 dense 变形
        first_token_tensor = hidden_states[:, 0]
        pooled_output = self.dense(first_token_tensor)
        pooled_output = self.activation(pooled_output)
        return pooled_output


class BertModel(nn.Module):
    def __init__(self, model_path):
        super(BertModel, self).__init__()

        # 配置文件是一定要有的
        self.config = BertConfig(os.path.join(model_path, "config.json"))

        self.embeddings = InputEmbeddings(self.config)
        self.encoder = Encoder(self.config)
        self.pooler = BertPooler(self.config)

        self.init_weights()
        self.from_pretrained(os.path.join(os.path.join(model_path, "pytorch_model.bin")))
        self.eval()

    def init_weights(self):
        self.apply(self._init_weights)

    def _init_weights(self, module):
        """ Initialize the weights """
        if isinstance(module, (nn.Linear, nn.Embedding)):
            # Slightly different from the TF version which uses truncated_normal for initialization
            # cf https://github.com/pytorch/pytorch/pull/5617
            module.weight.data.normal_(mean=0.0, std=self.config.initializer_range)
        elif isinstance(module, nn.LayerNorm):
            module.bias.data.zero_()
            module.weight.data.fill_(1.0)
        if isinstance(module, nn.Linear) and module.bias is not None:
            module.bias.data.zero_()

    def from_pretrained(self, pretrained_model_path):
        if not os.path.exists(pretrained_model_path):
            print(f"missing pretrained_model_path: {pretrained_model_path}")
            return

        state_dict = torch.load(pretrained_model_path, map_location='cpu')

        # 名称可能存在不一致，进行替换
        old_keys = []
        new_keys = []
        for key in state_dict.keys():
            new_key = key
            if 'gamma' in key:
                new_key = new_key.replace('gamma', 'weight')
            if 'beta' in key:
                new_key = new_key.replace('beta', 'bias')
            if 'bert.' in key:
                new_key = new_key.replace('bert.', '')
            # 兼容部分不优雅的变量命名
            if 'LayerNorm' in key:
                new_key = new_key.replace('LayerNorm', 'layer_norm')

            if new_key:
                old_keys.append(key)
                new_keys.append(new_key)

        for old_key, new_key in zip(old_keys, new_keys):

            if new_key in self.state_dict().keys():
                state_dict[new_key] = state_dict.pop(old_key)
            else:
                # 避免预训练模型里有多余的结构，影响 strict load_state_dict
                state_dict.pop(old_key)

        # 确保完全一致
        self.load_state_dict(state_dict, strict=True)

    def forward(self, input_ids, attention_mask=None, token_type_ids=None, position_ids=None):

        if attention_mask is None:
            attention_mask = torch.ones_like(input_ids)
        if token_type_ids is None:
            token_type_ids = torch.zeros_like(input_ids)

        # We create a 4D attention mask from a 2D tensor mask.
        # Sizes are [batch_size, 1, 1, to_seq_length]
        # So we can broadcast to [batch_size, num_heads, from_seq_length, to_seq_length]

        # 使用 dataloader 的时候纬度可能出问题 todo @mmmwhy
        extended_attention_mask = attention_mask.unsqueeze(1).unsqueeze(2)

        # Since attention_mask is 1.0 for positions we want to attend and 0.0 for
        # masked positions, this operation will create a tensor which is 0.0 for
        # positions we want to attend and -10000.0 for masked positions.
        # Since we are adding it to the raw scores before the softmax, this is
        # effectively the same as removing these entirely.
        extended_attention_mask = extended_attention_mask.to(dtype=next(self.parameters()).dtype)  # fp16 compatibility
        extended_attention_mask = (1.0 - extended_attention_mask) * -10000.0

        embedding_output = self.embeddings(input_ids, position_ids=position_ids, token_type_ids=token_type_ids)
        sequence_output = self.encoder(embedding_output, extended_attention_mask)
        pooled_output = self.pooler(sequence_output)

        outputs = BertOutput(last_hidden_state=sequence_output, pooler_output=pooled_output)

        return outputs
