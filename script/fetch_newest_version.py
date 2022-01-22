# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/25
#
"""
得到最近的版本号，用于自动更新版本。
"""

import json
import os
import urllib.request

module_root_directory = os.path.join(os.path.abspath(__file__).split("pure_attention")[0], "pure_attention")


# 读取文件内容
def read_file(filename):
    with open(os.path.join(module_root_directory, filename), encoding='utf-8') as f:
        long_description = f.read()
    return long_description


# 从 package.json 读取版本号
def fetch_package_version():
    version = json.loads(read_file("package.json"))["version"]
    return version


# 解析远程版本号
def fetch_remote_versions() -> str:
    url = "https://pypi.org/pypi/pure_attention/json"
    data = json.load(urllib.request.urlopen(url))
    versions = data["info"]["version"]
    return versions


# 替换 package.json 内的版本号
def alter(old_str, new_str):
    file_data = ""
    with open(os.path.join(module_root_directory, "package.json"), encoding='utf-8') as f:
        for line in f:
            if old_str in line:
                line = line.replace(old_str, new_str)
            file_data += line

    with open(os.path.join(module_root_directory, "package.json"), "w", encoding="utf-8") as f:
        f.write(file_data)


# 组织在一起
def update_version():
    local_version_part = fetch_package_version().split(".")
    remote_version_part = fetch_remote_versions().split(".")

    # 如果本地的版本号大于远程的，则直接上
    for i, j in zip(local_version_part, remote_version_part):
        if i > j:
            return ".".join(local_version_part)

    # 说明本地版本号要么比远程的旧，要么没有一样
    remote_version_part[-1] = str(int(remote_version_part[-1]) + 1)

    # 进行替换
    alter(".".join(local_version_part), ".".join(remote_version_part))
    return ".".join(remote_version_part)


if __name__ == "__main__":
    print(update_version())
