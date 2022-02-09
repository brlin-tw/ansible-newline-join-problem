#!/usr/bin/env sh
# 準備並運行靜態代碼分析程序
set -eux

# 安裝執行時期依賴軟體
apk add \
    bash \
    cargo \
    gcc \
    git \
    libffi-dev \
    make \
    musl-dev \
    nodejs \
    npm \
    openssl-dev \
    py3-pip \
    python3 \
    python3-dev \
    rust \
    shellcheck

# --ignore-installed: 迴避 pip #5247 議題問題
# https://github.com/pypa/pip/issues/5247
pip3 install \
    --ignore-installed \
    pre-commit

pre-commit run \
    --all-files
