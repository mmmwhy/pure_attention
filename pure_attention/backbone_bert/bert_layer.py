# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/22
#
""""""
import math

import torch
from torch import nn

from pure_attention.common.activate import activations
from pure_attention.common.layers import LayerNorm as BertLayerNorm


class BertEmbeddings(nn.Module):
    def __init__(self, config):
        """
        「input_embedding」 部分的实现
        vocab_size: 字典长度；
        hidden_size: 内部神经网络的隐层大小；
        type_vocab_size: 一般是 2 ，一般只有 0 和 1，告诉模型这是第一句话还是第二句话；
                (a) For sequence pairs:

                ``tokens:         [CLS] is this jack ##son ##ville ? [SEP] no it is not . [SEP]``

                ``token_type_ids:   0   0  0    0    0     0       0   0   1  1  1  1   1   1``

                (b) For single sequences:

                ``tokens:         [CLS] the dog is hairy . [SEP]``

                ``token_type_ids:   0   0   0   0  0     0   0``
        max_position_embeddings: 最长多少个字,生成的 position_embeddings 记录每个位置的 embedding，可以通过 cos 和 sin 交替产生。
                            直接初始化学习 和 sin_cos 差不多，但这样写读取预训练模型时，更兼容一些。
        hidden_dropout_prob: 随机丢弃的比例
        layer_norm_eps: norm 分母的 eps
        """
        super(BertEmbeddings, self).__init__()
        self.word_embeddings = nn.Embedding(config.vocab_size, config.hidden_size, padding_idx=0)
        self.position_embeddings = nn.Embedding(config.max_position_embeddings, config.hidden_size)
        self.token_type_embeddings = nn.Embedding(config.type_vocab_size, config.hidden_size)

        self.LayerNorm = BertLayerNorm(config.hidden_size, eps=config.layer_norm_eps)
        self.dropout = nn.Dropout(config.hidden_dropout_prob)

    def forward(self, input_ids, token_type_ids=None, position_ids=None):
        seq_length = input_ids.size(1)
        if position_ids is None:
            position_ids = torch.arange(seq_length, dtype=torch.long, device=input_ids.device)
            position_ids = position_ids.unsqueeze(0).expand_as(input_ids)
        if token_type_ids is None:
            token_type_ids = torch.zeros_like(input_ids)

        words_embeddings = self.word_embeddings(input_ids)
        position_embeddings = self.position_embeddings(position_ids)
        token_type_embeddings = self.token_type_embeddings(token_type_ids)

        # 注意按位相加
        embeddings = words_embeddings + position_embeddings + token_type_embeddings
        embeddings = self.LayerNorm(embeddings)
        embeddings = self.dropout(embeddings)
        return embeddings


class MultiHeadAttentionLayer(nn.Module):
    def __init__(self, config):
        """
        「Multi-Head Attention」 的实现，attention 核心代码
        hidden_size: 隐层纬度
        num_attention_heads: 注意力头的数量
        attention_probs_dropout_prob: attention prob 的 dropout 比例
        attention_scale: 对 query 和 value 的乘积结果进行缩放，目的是为了 softmax 结果稳定
        return_attention_scores: 是否返回 attention 矩阵
        """
        super(MultiHeadAttentionLayer, self).__init__()

        assert config.hidden_size % config.num_attention_heads == 0, "隐藏层纬度 需为 注意力头的数量 整数倍，否则注意力 embedding 无法计算"

        self.hidden_size = config.hidden_size
        self.num_attention_heads = config.num_attention_heads
        self.attention_head_size = int(config.hidden_size / config.num_attention_heads)
        self.return_attention_scores = config.return_attention_scores

        self.query = nn.Linear(config.hidden_size, config.hidden_size)
        self.key = nn.Linear(config.hidden_size, config.hidden_size)
        self.value = nn.Linear(config.hidden_size, config.hidden_size)

        self.dropout = nn.Dropout(config.attention_probs_dropout_prob)

    def transpose_for_scores(self, x):
        """
        这个函数的名字起的比较让人费解

        举个例子，以标准的 bert-base 的 query 来说， 输入的 x 纬度为  [batch_size, query_len, hidden_size]
        hidden_size 为 768
        num_attention_heads 为 12
        attention_head_size 为 768 / 12 = 64

        new_x_shape = [batch_size, query_len] + [12, 64] 即 [batch_size, query_len, num_attention_heads, attention_head_size]

        换句话来说，这个函数其实是把每个 token 的向量都分成了 12 份，给每个注意力头准备了 64d 的数。

        """

        new_x_shape = x.size()[:-1] + (self.num_attention_heads, self.attention_head_size)
        x = x.view(*new_x_shape)
        return x.permute(0, 2, 1, 3)

    def forward(self, query, key, value, attention_mask=None, head_mask=None):
        """
        query shape: [batch_size, query_len, hidden_size]
        key shape: [batch_size, key_len, hidden_size]
        value shape: [batch_size, value_len, hidden_size]
        一般情况下，query_len、key_len、value_len 三者相等
        """

        mixed_query_layer = self.query(query)
        mixed_key_layer = self.key(key)
        mixed_value_layer = self.value(value)
        """
        mixed_query_layer shape: [batch_size, query_len, hidden_size]
        mixed_query_layer shape: [batch_size, key_len, hidden_size]
        mixed_query_layer shape: [batch_size, value_len, hidden_size]
        """

        query_layer = self.transpose_for_scores(mixed_query_layer)
        key_layer = self.transpose_for_scores(mixed_key_layer)
        value_layer = self.transpose_for_scores(mixed_value_layer)
        """
        query_layer shape: [batch_size, num_attention_heads, query_len, attention_head_size]
        key_layer shape: [batch_size, num_attention_heads, key_len, attention_head_size]
        value_layer shape: [batch_size, num_attention_heads, value_len, attention_head_size]
        """

        # 交换 k 的最后两个维度，然后 q 和 k 执行点积, 获得 attention score
        attention_scores = torch.matmul(query_layer, key_layer.transpose(-1, -2))

        # attention_scores shape: [batch_size, num_attention_heads, query_len, key_len]

        """
        进行 attention scale, 除以 math.sqrt(self.attention_head_size) 是为了避免直接 softmax 后结果变得非常悬殊。
        避免只注意到极其个别的 key 上，大家可以感受一下 softmax([1,2]) 与 softmax([1 * np.sqrt(768), 2 * np.sqrt(768)]) 的结果。
        """
        attention_scores = attention_scores / math.sqrt(self.attention_head_size)

        # attention_mask 的值是 -inf, softmax 后的权重就是 0 了
        if attention_mask is not None:
            attention_scores = attention_scores + attention_mask

        # 对注意力结果进行 softmax， 得到 query 对于每个 value 的 score
        attention_probs = nn.Softmax(dim=-1)(attention_scores)

        """
        注意这里的实现是比较特别的，他是把某个 value 的 score 整个 mask 掉，但原始论文的确是这个意思
        这里引出一个很有趣的预训练方式，我们使用两个权重完全相同的 bert 进行对比学习 (比如搞 moco )，而可行的原因就是 drop 不一致
        """
        attention_probs = self.dropout(attention_probs)

        # Mask heads if we want to
        if head_mask is not None:
            attention_probs = attention_probs * head_mask

        # 某些 bert 会有 head_mask，我们这个版本不实现 todo @sun

        """
        再回忆一下
        value_layer shape: [batch_size, num_attention_heads, value_len, attention_head_size]
        attention_scores shape: [batch_size, num_attention_heads, query_len, key_len]
        
        value_len == key_len
        """
        context_layer = torch.matmul(attention_probs, value_layer)

        # context_layer shape: [batch_size, num_attention_heads, query_len, attention_head_size]

        # transpose、permute 等维度变换操作后，tensor 在内存中不再是连续存储的，而 view 操作要求 tensor 的内存连续存储，
        # 所以在调用 view 之前，需要 contiguous 来返回一个 contiguous copy；
        context_layer = context_layer.permute(0, 2, 1, 3).contiguous()
        # context_layer shape: [batch_size, query_len, num_attention_heads, attention_head_size]

        # 注意这里又把最后两个纬度合回去了，做的是 view 操作
        new_context_layer_shape = context_layer.size()[:-2] + (self.hidden_size,)
        context_layer = context_layer.view(*new_context_layer_shape)

        # 是否返回attention scores, 注意这里是最原始的 attention_scores 没有归一化且没有 dropout
        # 第一个位置是产出的 embedding，第二个位置是 attention_probs，后边会有不同的判断
        outputs = (context_layer, attention_scores) if self.return_attention_scores else (context_layer,)
        return outputs


class BertAddNorm(nn.Module):
    def __init__(self, intermediate_size, hidden_size, hidden_dropout_prob, layer_norm_eps):
        """
        「Add & Norm」 部分的代码实现,本模块会循环多次使用
        这里我将原始的 BertSelfOutput 和 BertOutput 和成一个了

        这里的 Add & Norm 实现了三个功能：
        1、在 Multi-Head attention 后，所有的头注意力结果是直接 concat 在一起的(view 调整 size 也可以认为 concat 在一起)
            直接 concat 在一起的结果用起来也有点奇怪，所以需要有个 fc ，来帮助把这些分散注意力结果合并在一起；
        2、在 Feed Forward 操作后，纬度被提升到 intermediate_size，BertAddNorm 还实现了把纬度从 intermediate_size 降回 hidden_size 的功能；
        3、真正的 Add & Norm 部分，也就是  LayerNorm(hidden_states + input_tensor) 这一行；
        """
        super(BertAddNorm, self).__init__()
        self.dense = nn.Linear(intermediate_size, hidden_size)
        self.LayerNorm = BertLayerNorm(hidden_size, eps=layer_norm_eps)
        self.dropout = nn.Dropout(hidden_dropout_prob)

    def forward(self, hidden_states, input_tensor):
        hidden_states = self.dense(hidden_states)
        hidden_states = self.dropout(hidden_states)
        # 残差，非常重要
        hidden_states = self.LayerNorm(hidden_states + input_tensor)
        return hidden_states


class BertIntermediate(nn.Module):
    """
    「Position-wise Feed-Forward Networks 」 的部分代码实现
    FFN(x) = max(0, xW1 + b1)W2 + b2

    原始 Attention is all you need 中，hidden_size: 512, intermediate_size: 2048，纬度放大的操作。
    有点像 cnn 中有两个 kernel size 为 1 的卷积，对纬度进行放大然后再缩小。

    但我们发现这里的代码，似乎只有 activate(xw1+b1) 的部分，没有外边的那个 fc 在 BertAddNorm 里边放着
    """

    def __init__(self, hidden_size, intermediate_size, hidden_act):
        super(BertIntermediate, self).__init__()
        self.dense = nn.Linear(hidden_size, intermediate_size)
        self.intermediate_act_fn = activations[hidden_act]

    def forward(self, hidden_states):
        hidden_states = self.dense(hidden_states)
        hidden_states = self.intermediate_act_fn(hidden_states)
        return hidden_states


class BertAttention(nn.Module):
    def __init__(self, config):
        """
        「Multi-Head Attention 和 Add & Norm」 的实现
        hidden_size: 隐层纬度
        num_attention_heads: 注意力头的数量
        attention_probs_dropout_prob: attention prob 的 dropout 比例
        attention_scale: 对 query 和 value 的乘积结果进行缩放，目的是为了 softmax 结果稳定
        return_attention_scores: 是否返回 attention 矩阵
        hidden_dropout_prob: 隐层 dropout 比例
        layer_norm_eps: norm 下边的 eps
        """
        super(BertAttention, self).__init__()
        self.self = MultiHeadAttentionLayer(config)
        # 这里是左下的那个 Add & Norm
        self.output = BertAddNorm(config.hidden_size, config.hidden_size,
                                  config.hidden_dropout_prob, config.layer_norm_eps)
        self.pruned_heads = set()

    def forward(self, input_tensor, attention_mask=None, head_mask=None):
        self_outputs = self.self(input_tensor, input_tensor, input_tensor, attention_mask, head_mask)
        attention_output = self.output(self_outputs[0], input_tensor)
        outputs = (attention_output,) + self_outputs[1:]
        return outputs


class BertLayer(nn.Module):
    def __init__(self, config):
        """
        完整的 bert 单层结构
        这里我刻意把 config 内的参数都拿出来，方便进行注释
        """
        super(BertLayer, self).__init__()
        self.attention = BertAttention(config)

        self.intermediate = BertIntermediate(config.hidden_size, config.intermediate_size, config.hidden_act)
        self.output = BertAddNorm(config.intermediate_size, config.hidden_size,
                                  config.hidden_dropout_prob, config.layer_norm_eps)

    def forward(self, hidden_states, attention_mask=None, head_mask=None):
        attention_outputs = self.attention(hidden_states, attention_mask, head_mask)
        attention_output = attention_outputs[0]

        # 这里是左上的 Add & Norm，从而得到完整的 FFN
        intermediate_output = self.intermediate(attention_output)
        layer_output = self.output(intermediate_output, attention_output)

        # attention_outputs[0] 是 embedding, [1] 是 attention_probs
        outputs = (layer_output,) + attention_outputs[1:]
        return outputs
