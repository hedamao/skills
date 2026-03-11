#!/bin/bash
# OpenClaw Controller - Build Script
# 在 Mac 上交叉编译生成 Windows .exe

set -e

echo "==> 安装 rsrc 工具（生成 Windows 资源文件）..."
go install github.com/akavel/rsrc@latest

echo "==> 生成资源文件..."
$(go env GOPATH)/bin/rsrc -manifest main.manifest -o rsrc_windows_amd64.syso

echo "==> 交叉编译 Windows .exe..."
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -H windowsgui" -o OpenClaw.exe

echo "==> 构建完成！"
echo "    输出文件: OpenClaw.exe"
ls -la OpenClaw.exe
echo ""
echo "将 OpenClaw.exe 拷贝到 Windows 11 机器上即可运行。"
