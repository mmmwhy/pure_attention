#!/usr/bin/env bash
#
# @author: fy.li <fy.li@qq.com>
# @date: 2021/10/12
#
SELF_DIR=$(cd "$(dirname "$0")" || exit 1; pwd)
ROOT=$(cd "$SELF_DIR/.." || exit 1; pwd)
cd "$ROOT" || exit
echo "script dir: $SELF_DIR"
echo "project dir: $ROOT"


# 彩色输出
function cecho {
  local code="\033["
  case "$1" in
    black  | bk) color="${code}0;30m";;
    red    |  r) color="${code}1;31m";;
    green  |  g) color="${code}1;32m";;
    yellow |  y) color="${code}1;33m";;
    blue   |  b) color="${code}1;34m";;
    purple |  p) color="${code}1;35m";;
    cyan   |  c) color="${code}1;36m";;
    gray   | gr) color="${code}0;37m";;
    *) local text="$1"
  esac

  [[ -z "${text}" ]] && local text="${color}$2${code}0m"
  echo -e "${text}"
}