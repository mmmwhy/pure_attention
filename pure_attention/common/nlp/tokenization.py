# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/24
#
""""""
import collections
import os
import unicodedata
from io import open
import torch
import numpy as np
from pure_attention.common.logger import init_logger

logger = init_logger(__name__)


def truncate_sequences(maxlen, indices, *sequences):
    """截断总长度至不超过 maxlen
    """
    sequences = [s for s in sequences if s]
    if not isinstance(indices, (list, tuple)):
        indices = [indices] * len(sequences)

    while True:
        lengths = [len(s) for s in sequences]
        if sum(lengths) > maxlen:
            # 从较长的一侧进行 pop
            i = np.argmax(lengths)
            sequences[i].pop(indices[i])
        else:
            return sequences


def load_vocab(vocab_file):
    """
    加载词典文件到 dict
    """
    vocab = collections.OrderedDict()
    index = 0
    with open(vocab_file, "r", encoding="utf-8") as reader:
        while True:
            token = reader.readline()
            if not token:
                break
            token = token.strip()
            vocab[token] = index
            index += 1
    return vocab


def whitespace_tokenize(text):
    """
    去除文本中的空白符
    """
    text = text.strip()
    if not text:
        return []
    tokens = text.split()
    return tokens


class Tokenizer(object):

    def __init__(
            self,
            vocab_file,
            do_lower_case=True,
            do_basic_tokenize=True,
            unk_token="[UNK]",
            sep_token="[SEP]",
            pad_token="[PAD]",
            cls_token="[CLS]",
            mask_token="[MASK]"):
        """

        参数:
            vocab_file:
                词典文件
            do_lower_case:
                是否转换成小写
            do_basic_tokenize:
                分词前，是否进行基础的分词
            unk_token:
                未知词标记
            sep_token:
                句子切分标记，当只有一句话作为输入时，此标记知识作为结束符；当有两句话作为输入时，此标记作为分隔符、最后一句话的结束符
            pad_token:
                padding 填充标记
            cls_token:
                分类标记，位于整个序列的第一个
            mask_token:
                mask标记

        """
        if not os.path.isfile(vocab_file):
            raise ValueError(
                "Can't find a vocabulary file at path '{}'.".format(vocab_file))
        self.vocab = load_vocab(vocab_file)
        self.ids_to_tokens = collections.OrderedDict(
            [(ids, tok) for tok, ids in self.vocab.items()])
        self.do_basic_tokenize = do_basic_tokenize
        if do_basic_tokenize:
            self.basic_tokenizer = BasicTokenizer(do_lower_case=do_lower_case,
                                                  never_split=(unk_token, sep_token, pad_token, cls_token, mask_token))
        self.wordpiece_tokenizer = WordpieceTokenizer(vocab=self.vocab)
        self.unk_token = unk_token
        self.sep_token = sep_token
        self.pad_token = pad_token
        self.cls_token = cls_token
        self.mask_token = mask_token

    def tokenize(self, text):
        split_tokens = []
        if self.do_basic_tokenize:
            for token in self.basic_tokenizer.tokenize(text):
                for sub_token in self.wordpiece_tokenizer.tokenize(token):
                    split_tokens.append(sub_token)
        else:
            split_tokens = self.wordpiece_tokenizer.tokenize(text)
        if self.cls_token is not None:
            split_tokens.insert(0, self.cls_token)
        if self.sep_token is not None:
            split_tokens.append(self.sep_token)
        return split_tokens

    def convert_tokens_to_ids(self, tokens):
        """
        tokens 转为 vocab 中的 id
        """
        ids = []
        for token in tokens:
            ids.append(self.vocab[token])
        return ids

    def convert_ids_to_tokens(self, ids):
        """
        ids 转为词表中的 token
        """
        tokens = []
        for i in ids:
            tokens.append(self.ids_to_tokens[i])
        return tokens

    def encode(
            self,
            first_text,
            second_text=None,
            is_padding=True,
            max_len=512,
            truncate_from='right'
    ):
        """
        输出文本对应 token id 和 segment id
        """
        if isinstance(first_text, str):
            first_tokens = self.tokenize(first_text)
        else:
            first_tokens = first_text

        if second_text is None:
            second_tokens = None
        elif isinstance(second_text, str):
            second_tokens = self.tokenize(second_text)
        else:
            second_tokens = second_text

        if max_len is not None:
            if truncate_from == 'right':
                index = -2
            elif truncate_from == 'left':
                index = 1
            else:
                index = truncate_from
            if second_text is not None:
                max_len += 1
            truncate_sequences(max_len, index, first_tokens, second_tokens)

        # token_ids 等价于 input_ids,segment_ids 等价于 token_type_ids
        first_token_ids = self.convert_tokens_to_ids(first_tokens)
        first_segment_ids = [0] * len(first_token_ids)

        if second_text is not None:
            second_tokens = second_tokens[1:]
            second_token_ids = self.convert_tokens_to_ids(second_tokens)
            second_segment_ids = [1] * len(second_token_ids)
            first_token_ids.extend(second_token_ids)
            first_segment_ids.extend(second_segment_ids)

        # 做一个 padding 操作
        if is_padding:
            while len(first_token_ids) < max_len:
                first_token_ids.append(self.vocab[self.pad_token])
                first_segment_ids.append(self.vocab[self.pad_token])

        if max_len and len(first_token_ids) > max_len:
            first_token_ids = first_token_ids[:max_len]
            first_segment_ids = first_segment_ids[:max_len]

        first_token_ids = torch.tensor([first_token_ids])
        first_segment_ids = torch.tensor([first_segment_ids])

        return first_token_ids, first_segment_ids


class BasicTokenizer(object):
    """Runs basic tokenization (punctuation splitting, lower casing, etc.)."""

    def __init__(self,
                 do_lower_case=True,
                 never_split=("[UNK]", "[SEP]", "[PAD]", "[CLS]", "[MASK]")):
        """Constructs a BasicTokenizer.

        Args:
          do_lower_case: Whether to lower case the input.
        """
        self.do_lower_case = do_lower_case
        self.never_split = never_split

    def tokenize(self, text):
        """
        文本切分成 token，这个操作可能会导致序列标注类任务位置无法对齐，ner 类任务中需注意这一点。

        """
        text = self._clean_text(text)
        text = self._tokenize_chinese_chars(text)
        orig_tokens = whitespace_tokenize(text)
        split_tokens = []
        for token in orig_tokens:
            if self.do_lower_case and token not in self.never_split:
                token = token.lower()
                token = self._run_strip_accents(token)
            split_tokens.extend(self._run_split_on_punc(token))

        output_tokens = whitespace_tokenize(" ".join(split_tokens))
        return output_tokens

    def _run_strip_accents(self, text):
        """Strips accents from a piece of text."""
        text = unicodedata.normalize("NFD", text)
        output = []
        for char in text:
            cat = unicodedata.category(char)
            if cat == "Mn":
                continue
            output.append(char)
        return "".join(output)

    def _run_split_on_punc(self, text):
        """Splits punctuation on a piece of text."""
        if text in self.never_split:
            return [text]
        chars = list(text)
        i = 0
        start_new_word = True
        output = []
        while i < len(chars):
            char = chars[i]
            if _is_punctuation(char):
                output.append([char])
                start_new_word = True
            else:
                if start_new_word:
                    output.append([])
                start_new_word = False
                output[-1].append(char)
            i += 1

        return ["".join(x) for x in output]

    def _tokenize_chinese_chars(self, text):
        """Adds whitespace around any CJK character."""
        output = []
        for char in text:
            cp = ord(char)
            if self._is_chinese_char(cp):
                output.append(" ")
                output.append(char)
                output.append(" ")
            else:
                output.append(char)
        return "".join(output)

    def _is_chinese_char(self, cp):
        """Checks whether CP is the codepoint of a CJK character."""
        # This defines a "chinese character" as anything in the CJK Unicode block:
        #   https://en.wikipedia.org/wiki/CJK_Unified_Ideographs_(Unicode_block)
        #
        # Note that the CJK Unicode block is NOT all Japanese and Korean characters,
        # despite its name. The modern Korean Hangul alphabet is a different block,
        # as is Japanese Hiragana and Katakana. Those alphabets are used to write
        # space-separated words, so they are not treated specially and handled
        # like the all of the other languages.
        if ((cp >= 0x4E00 and cp <= 0x9FFF) or  #
                (cp >= 0x3400 and cp <= 0x4DBF) or  #
                (cp >= 0x20000 and cp <= 0x2A6DF) or  #
                (cp >= 0x2A700 and cp <= 0x2B73F) or  #
                (cp >= 0x2B740 and cp <= 0x2B81F) or  #
                (cp >= 0x2B820 and cp <= 0x2CEAF) or
                (cp >= 0xF900 and cp <= 0xFAFF) or  #
                (cp >= 0x2F800 and cp <= 0x2FA1F)):  #
            return True

        return False

    def _clean_text(self, text):
        """Performs invalid character removal and whitespace cleanup on text."""
        output = []
        for char in text:
            cp = ord(char)
            if cp == 0 or cp == 0xfffd or _is_control(char):
                continue
            if _is_whitespace(char):
                output.append(" ")
            else:
                output.append(char)
        return "".join(output)


class WordpieceTokenizer(object):
    """Runs WordPiece tokenization."""

    def __init__(self, vocab, unk_token="[UNK]", max_input_chars_per_word=100):
        self.vocab = vocab
        self.unk_token = unk_token
        self.max_input_chars_per_word = max_input_chars_per_word

    def tokenize(self, text):
        """Tokenizes a piece of text into its word pieces.

        This uses a greedy longest-match-first algorithm to perform tokenization
        using the given vocabulary.

        For example:
          input = "unaffable"
          output = ["un", "##aff", "##able"]

        Args:
          text: A single token or whitespace separated tokens. This should have
            already been passed through `BasicTokenizer`.

        Returns:
          A list of wordpiece tokens.
        """

        output_tokens = []
        for token in whitespace_tokenize(text):
            chars = list(token)
            if len(chars) > self.max_input_chars_per_word:
                output_tokens.append(self.unk_token)
                continue

            is_bad = False
            start = 0
            sub_tokens = []
            while start < len(chars):
                end = len(chars)
                cur_substr = None
                while start < end:
                    substr = "".join(chars[start:end])
                    if start > 0:
                        substr = "##" + substr
                    if substr in self.vocab:
                        cur_substr = substr
                        break
                    end -= 1
                if cur_substr is None:
                    is_bad = True
                    break
                sub_tokens.append(cur_substr)
                start = end

            if is_bad:
                output_tokens.append(self.unk_token)
            else:
                output_tokens.extend(sub_tokens)
        return output_tokens


def _is_whitespace(char):
    """Checks whether `chars` is a whitespace character."""
    # \t, \n, and \r are technically contorl characters but we treat them
    # as whitespace since they are generally considered as such.
    if char == " " or char == "\t" or char == "\n" or char == "\r":
        return True
    cat = unicodedata.category(char)
    if cat == "Zs":
        return True
    return False


def _is_control(char):
    """Checks whether `chars` is a control character."""
    # These are technically control characters but we count them as whitespace
    # characters.
    if char == "\t" or char == "\n" or char == "\r":
        return False
    cat = unicodedata.category(char)
    if cat.startswith("C"):
        return True
    return False


def _is_punctuation(char):
    """Checks whether `chars` is a punctuation character."""
    cp = ord(char)
    # We treat all non-letter/number ASCII as punctuation.
    # Characters such as "^", "$", and "`" are not in the Unicode
    # Punctuation class but we treat them as punctuation anyways, for
    # consistency.
    if ((cp >= 33 and cp <= 47) or (cp >= 58 and cp <= 64) or
            (cp >= 91 and cp <= 96) or (cp >= 123 and cp <= 126)):
        return True
    cat = unicodedata.category(char)
    if cat.startswith("P"):
        return True
    return False
