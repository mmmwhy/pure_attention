#!/usr/bin/env bash
#
# @author: fy.li <fy.li@qq.com>
# @date: 2021/10/12
#

SELF_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)
source "$SELF_DIR/common.sh"

# 使用 pep8 为校验标准
function format() {
  if ! which "autopep8" ; then
    cecho r "autopep8 not install, run:pip install autopep8==1.5.7"
    exit 1
  fi

  # 只对最近一次提交 commit 内的文件进行 autopep8
  git log --name-only -1|grep .py|while read py_file;
  do
    if [  -f "$py_file" ] ; then
      autopep8 --in-place --recursive --max-line-length=120 "$py_file"
    fi
  done

  cecho g "auto format done"
}

# 更新版本号
function update_version() {
  python script/vision_controller.py
}


# 生成 changelog
function changelog() {
  if ! which "npm" ; then
    cecho r "see: {} for detail"
    exit 1
  fi
  npm run changelog
}

# 完成发包
function release_package_to_pypi() {
  cp ~/.pypirc_pypi ~/.pypirc

  python setup.py sdist
  twine upload dist/*

  rm -rf dist pure_attention.egg-info
  cp ~/.pypirc_internal ~/.pypirc
}

function usage() {
  cat << EOF
  Usage:
    $0 sub_command
  sub_command:
    - format: format code (running by autopep8)
    - release: release code to pypi
    - all: run all
EOF
  exit 1
}


function args() {
  if [[ $# -lt 1 ]]; then
      usage
  fi

  case $1 in
    format|f)
      cecho y ">>>>>>> formatting ..."
      changelog
      format
      update_version
      ;;
    release|r|all)
      cecho y ">>>>>>> release code to pypi  ..."
      changelog
      format
      update_version
      release_package_to_pypi
      ;;
    *)
      ;;
  esac

}

args "$@"