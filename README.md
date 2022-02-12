# 介绍
attention 在 cv 和 nlp 领域都有很多的应用，比如在 cv 中，可以使用 detr 进行目标检测任务，使用 vit / mae 进行图片预训练任务。

在 nlp 领域中的作用更不用提， bert 以及后续的更多工作将 attention 彻底的发扬光大。

cv 和 nlp 中的很多方法和技巧也在相互影响，比如大规模的预训练、mask 的设计(mae 、vilbert)、自监督学习的设计(从 imageNet 做有监督的预训练到纯粹的自监督预训练)。

这些方面都非常的有趣，我希望可以设计一个 backbone 结构，让其可以在 cv 任务和 nlp 任务上均取到 sota 的效果。

从而为之后的任务提供一个 baseline。

# 目标
提供一套完整的的基础算法服务

1、python 训练任务，包含 NLP 和 CV 任务。

2、java 环境下使用 onnx 的在线推理部署。

# todo
第一阶段：实现 NLP 和 CV 的典型任务，并评估下游效果。
- [x]  Pytorch 实现 Transformer 的 encode 阶段，并实现 bert ;

  > 参考 [transformers](https://github.com/huggingface/transformers) 的设计，但只保留与关键 encode 相关的代码，简化代码量。
  保持与原始 huggingface encode 的结果一致, 使用方法和一致性校验可以参考 [backbone_bert](pure_attention/backbone_bert/README.md) 。

  - [x] 提供 [transformers](https://github.com/huggingface/transformers) 中 [bert-base-chinese](https://huggingface.co/bert-base-chinese) 、[chinese-roberta-wwm-ext](https://huggingface.co/hfl/chinese-roberta-wwm-ext) 、[chinese-roberta-wwm-ext-large](https://huggingface.co/hfl/chinese-roberta-wwm-ext-large) 、[ernie 1.0](https://huggingface.co/nghuyong/ernie-1.0) 的国内下载镜像,  下载方式具体可参考 [transformers国内下载镜像](pure_attention/backbone_bert/README.md#transformers国内下载镜像) 。

- [x]  Pytorch 实现 Transformer 的 decode 阶段，并实现 seq2seq 任务。
  > todo
- [ ]  NLP 下游任务 序列标注、分类 的实现，并在公开数据集上进行评估，这里主要是想证明实现的 backbone 效果是符合预期的；
  > todo
- [ ]  实现 Vit，并在下游任务上验证实现 Vit 的效果是否符合预期；
  > todo

 第二阶段：增加 NLP 和 CV 的其余常见任务，扩增项目的能力范围。
- [ ] UNILM；
- [ ] MAE；
- [ ] GPT系列；
- [ ] seq2seq，搞一个翻译任务；
- [ ] 实现模型的 onnx export； 
- [ ] 实现 java 下的 onnx 推理过程；
