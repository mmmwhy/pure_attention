# 介绍
[transformers](https://github.com/huggingface/transformers) 为了适应非常多种模型结构，结构变得非常复杂。

我在参考
[transformers](https://github.com/huggingface/transformers) 、 
[bert4pytorch](https://github.com/MuQiuJun-AI/bert4pytorch) 、
[Read_Bert_Code](https://github.com/DA-southampton/Read_Bert_Code)
的代码基础上，对结构进行了一些调整，提高了代码的易读性，并和 [transformers](https://github.com/huggingface/transformers) 的结果完全一致。

# 使用

``` python
from pure_attention.common.nlp.tokenization import Tokenizer
from pure_attention.backbone_bert.bert_model import BertModel

bert_model_path = "/data/pretrain_modal/bert-base-chinese"
test_query = "结果一致性验证"

tokenizer = Tokenizer(bert_model_path + "/vocab.txt")
bert = BertModel(bert_model_path)
tokens_ids, segments_ids = tokenizer.encode(test_query, max_len=64)

bert_pooler_output = bert(tokens_ids, token_type_ids=segments_ids).pooler_output

```


# 结果一致性
分别在下边三个常用中文 bert 上进行测试，结果与 transformers 完全一致。
- [bert-base-chinese](https://huggingface.co/bert-base-chinese)
  
  ![](../../images/bert-base-chinese.png)
  

- [chinese-roberta-wwm-ext](https://huggingface.co/hfl/chinese-roberta-wwm-ext)
  
  ![](../../images/chinese-roberta-wwm-ext.png)
  

- [chinese-roberta-wwm-ext-large](https://huggingface.co/hfl/chinese-roberta-wwm-ext-large)
  
  ![](../../images/chinese-roberta-wwm-ext-large.png)
  

``` python
import torch
from transformers import BertModel
from transformers import BertTokenizer

from pure_attention.common.nlp.tokenization import Tokenizer as LocalTokenizer
from pure_attention.backbone_bert.bert_model import BertModel as OurBertModel

bert_model_path = "/data/pretrain_modal/chinese-roberta-wwm-ext-large"
test_query = "结果一致性验证"

text_tokenizer = BertTokenizer.from_pretrained(bert_model_path, do_lower_case=True)
bert_model = BertModel.from_pretrained(bert_model_path)

tensor_caption = text_tokenizer.encode(test_query, return_tensors="pt", padding='max_length', truncation=True,
                                       max_length=64)

origin_bert_pooler_output = bert_model(tensor_caption).pooler_output

tokenizer = LocalTokenizer(bert_model_path + "/vocab.txt")
bert = OurBertModel(bert_model_path)
tokens_ids, segments_ids = tokenizer.encode(test_query, max_len=64)

our_bert_pooler_output = bert(tokens_ids, token_type_ids=segments_ids).pooler_output

print("check result:", torch.cosine_similarity(origin_bert_pooler_output, our_bert_pooler_output))
```