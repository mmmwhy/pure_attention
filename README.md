# 介绍
attention 在 cv 和 nlp 领域都有很多的应用，比如在 cv 中，可以使用 detr 进行目标检测任务，使用 vit / mae 进行图片预训练任务。

在 nlp 领域中的作用更不用提， bert 以及后续的更多工作将 attention 彻底的发扬光大。

cv 和 nlp 中的很多方法和技巧也在相互影响，比如大规模的预训练、mask 的设计(mae 、vilbert)、自监督学习的设计(从 imageNet 做有监督的预训练到纯粹的自监督预训练)。

这些方面都非常的有趣，我希望可以设计一个 backbone 结构，让其可以在 cv 任务和 nlp 任务上均取到 sota 的效果。

从而为之后的任务提供一个 baseline。

# 目标
提供一套完整的的基础算法服务

1、python 训练任务，包含 NLP 和 CV 任务 。

2、java 环境下使用 onnx 的在线推理部署，使用 onnx 的原因是我在公司用的是 TensorFlow 做推理，我不想和公司的代码一致。

# todo
- 第一阶段的目标：实现 NLP 和 CV 的典型任务，并评估下游效果。
- [ ]  Transformer 的 pytorch 实现；
- [ ]  多版本的 Bert 的实现；
- [ ]  NLP 下游任务 序列标注、分类 的实现，并在公开数据集上进行评估。这里主要是想证明实现的 Bert 效果是符合预期的；
- [ ]  实现 Vit，并在下游任务上验证实现 Vit 的效果是否符合预期；

- 第二阶段的目标：增加 NLP 和 CV 的其余常见任务，扩增项目的能力范围。
- [ ] UNILM；
- [ ] MAE；
- [ ] GPT系列；
- [ ] seq2seq，搞一个翻译任务；
- [ ] 实现模型的 onnx export； 
- [ ] 实现 java 下的 onnx 推理过程；