# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/22
#

from setuptools import setup, find_packages
from script.fetch_newest_version import read_file, fetch_package_version


# 获取依赖
def read_requirements(filename):
    return [line.strip() for line in read_file(filename).splitlines()
            if not line.startswith('#')]


setup(
    name='pure_attention',
    version=fetch_package_version(),
    description='use pure attention implement cv/nlp backbone',
    long_description=read_file('README.md'),
    long_description_content_type="text/markdown",
    license='Apache License 2.0',
    url="https://github.com/mmmwhy/pure_attention",
    author='mmmwhy',
    author_email="mmmwhy@mail.ustc.edu.cn",
    install_requires=read_requirements("requirements.txt"),
    packages=find_packages(exclude=['tests'])
)
