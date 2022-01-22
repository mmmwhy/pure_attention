# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/22
#
""""""
import os
from pure_attention.backbone_bert.package import BertConfig, BertOutput
import torch
from torch import nn
from pure_attention.backbone_bert.bert_layer import BertLayer, BertEmbeddings
from pure_attention.common.layers import LayerNorm as BertLayerNorm


class BertEncoder(nn.Module):
    def __init__(self, config):
        super(BertEncoder, self).__init__()
        self.output_attentions = config.output_attentions
        self.output_hidden_states = config.output_hidden_states

        self.layer = nn.ModuleList([BertLayer(config) for _ in range(config.num_hidden_layers)])

    def forward(self, hidden_states, attention_mask=None, head_mask=None):
        all_hidden_states = ()
        all_attentions = ()
        for i, layer_module in enumerate(self.layer):
            if self.output_hidden_states:
                all_hidden_states = all_hidden_states + (hidden_states,)

            layer_outputs = layer_module(hidden_states, attention_mask, head_mask[i])
            # [0] 是 embedding, [1] 是 attention_score
            hidden_states = layer_outputs[0]

            if self.output_attentions:
                all_attentions = all_attentions + (layer_outputs[1],)

        # Add last layer
        if self.output_hidden_states:
            all_hidden_states = all_hidden_states + (hidden_states,)

        outputs = (hidden_states,)
        if self.output_hidden_states:
            # 把中间层的结果取出来，一些研究认为中间层的 embedding 也有价值
            outputs = outputs + (all_hidden_states,)
        if self.output_attentions:
            outputs = outputs + (all_attentions,)

        # last-layer hidden state, (all hidden states), (all attentions)
        return outputs


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
    def __init__(self, config_path):
        super(BertModel, self).__init__()

        self.config = BertConfig(os.path.join(config_path, "config.json"))

        self.embeddings = BertEmbeddings(self.config)
        self.encoder = BertEncoder(self.config)
        self.pooler = BertPooler(self.config)

        self.init_weights()
        self.from_pretrained(os.path.join(os.path.join(config_path, "pytorch_model.bin")))
        self.eval()

    def init_weights(self):
        self.apply(self._init_weights)

    def _init_weights(self, module):
        """ Initialize the weights """
        if isinstance(module, (nn.Linear, nn.Embedding)):
            # Slightly different from the TF version which uses truncated_normal for initialization
            # cf https://github.com/pytorch/pytorch/pull/5617
            module.weight.data.normal_(mean=0.0, std=self.config.initializer_range)
        elif isinstance(module, BertLayerNorm):
            module.bias.data.zero_()
            module.weight.data.fill_(1.0)
        if isinstance(module, nn.Linear) and module.bias is not None:
            module.bias.data.zero_()

    def from_pretrained(self, pretrained_model_path):
        if not os.path.exists(pretrained_model_path):
            print(f"missing pretrained_model_path: {pretrained_model_path}")
            pass

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

    def forward(self, input_ids, attention_mask=None, token_type_ids=None, position_ids=None, head_mask=None):
        if attention_mask is None:
            attention_mask = torch.ones_like(input_ids)
        if token_type_ids is None:
            token_type_ids = torch.zeros_like(input_ids)

        # We create a 3D attention mask from a 2D tensor mask.
        # Sizes are [batch_size, 1, 1, to_seq_length]
        # So we can broadcast to [batch_size, num_heads, from_seq_length, to_seq_length]
        # this attention mask is more simple than the triangular masking of causal attention
        # used in OpenAI GPT, we just need to prepare the broadcast dimension here.

        extended_attention_mask = attention_mask.unsqueeze(1).unsqueeze(2)

        # Since attention_mask is 1.0 for positions we want to attend and 0.0 for
        # masked positions, this operation will create a tensor which is 0.0 for
        # positions we want to attend and -10000.0 for masked positions.
        # Since we are adding it to the raw scores before the softmax, this is
        # effectively the same as removing these entirely.
        extended_attention_mask = extended_attention_mask.to(dtype=next(self.parameters()).dtype)  # fp16 compatibility
        extended_attention_mask = (1.0 - extended_attention_mask) * -10000.0

        # Prepare head mask if needed
        # 1.0 in head_mask indicate we keep the head
        # attention_probs has shape bsz x n_heads x N x N
        # input head_mask has shape [num_heads] or [num_hidden_layers x num_heads]
        # and head_mask is converted to shape [num_hidden_layers x batch x num_heads x seq_length x seq_length]
        if head_mask is not None:
            if head_mask.dim() == 1:
                head_mask = head_mask.unsqueeze(0).unsqueeze(0).unsqueeze(-1).unsqueeze(-1)
                head_mask = head_mask.expand(self.config.num_hidden_layers, -1, -1, -1, -1)
            elif head_mask.dim() == 2:
                head_mask = head_mask.unsqueeze(1).unsqueeze(-1).unsqueeze(
                    -1)  # We can specify head_mask for each layer
            head_mask = head_mask.to(
                dtype=next(self.parameters()).dtype)  # switch to fload if need + fp16 compatibility
        else:
            head_mask = [None] * self.config.num_hidden_layers

        embedding_output = self.embeddings(input_ids, position_ids=position_ids, token_type_ids=token_type_ids)
        encoder_outputs = self.encoder(embedding_output,
                                       extended_attention_mask,
                                       head_mask=head_mask)
        sequence_output = encoder_outputs[0]
        pooled_output = self.pooler(sequence_output)

        outputs = BertOutput(last_hidden_state=sequence_output, pooler_output=pooled_output,
                             attentions=encoder_outputs[1:])

        return outputs
