# Scripts Guide

本目录包含 Node Exporter 的构建、安装、卸载和第三方代码同步脚本。

## 脚本概览

| 脚本                           | 用途                         | 执行环境              |
| ------------------------------ | ---------------------------- | --------------------- |
| `deploy.sh`                    | 构建双架构二进制并打包       | 开发机（macOS/Linux） |
| `scripts/install.sh`           | 服务器上安装 Node Exporter   | 目标服务器（需 root） |
| `scripts/uninstall.sh`         | 服务器上卸载 Node Exporter   | 目标服务器（需 root） |
| `scripts/sync_gpu_exporter.sh` | 从上游同步 GPU Exporter 代码 | 开发机                |

---

## 1. deploy.sh — 构建与打包

为 `linux/amd64` 和 `linux/arm64` 两种架构构建二进制并打包为 `.tar.gz`。

```bash
# 使用默认版本号 v1.1
bash deploy.sh

# 指定版本号
bash deploy.sh v1.2
```

**产出文件**（在 `build/` 目录下）：

```
build/
├── node_exporter_amd64.tar.gz
├── node_exporter_arm64.tar.gz
└── sha256sums.txt
```

**发布流程**：

1. 执行 `bash deploy.sh <version>` 完成构建
2. 将 `sha256sums.txt` 中的哈希值更新到 `scripts/install.sh` 顶部的 `SHA256_AMD64` 和 `SHA256_ARM64`
3. 将两个 `.tar.gz` 和 `install.sh` 上传到 GitHub Release

---

## 2. scripts/install.sh — 安装

自动检测服务器架构，下载对应的安装包并完成安装。

```bash
# 需要 root 权限
sudo su -

# 默认端口 745
bash install.sh

# 自定义端口
bash install.sh 9100
```

**远程一键安装**：

```bash
# 默认端口
wget -qO- https://github.com/BitdeerAI/node_exporter/releases/download/<version>/install.sh | bash

# 自定义端口
wget -qO- https://github.com/BitdeerAI/node_exporter/releases/download/<version>/install.sh | bash -s -- 9100
```

**安装流程**：

1. 检查 root 权限和依赖命令（wget、sha256sum、tar、systemctl）
2. 通过 `uname -m` 自动识别架构（amd64 / arm64）
3. 下载对应架构的 `.tar.gz` 包
4. SHA256 校验文件完整性
5. 安装二进制到 `/usr/local/bin/node_exporter`
6. 创建并启动 systemd 服务

---

## 3. scripts/uninstall.sh — 卸载

```bash
sudo bash scripts/uninstall.sh
```

**卸载流程**：

1. 停止并禁用 `node_exporter` 服务
2. 删除 systemd 服务文件
3. 删除二进制文件（兼容旧版 `node_exporter_amd64` 命名）

---

## 4. scripts/sync_gpu_exporter.sh — 同步 GPU Exporter

从上游 [nvidia_gpu_exporter](https://github.com/utkuozdemir/nvidia_gpu_exporter) 仓库同步最新的 GPU 监控代码。

```bash
# 同步 master 分支最新代码
bash scripts/sync_gpu_exporter.sh

# 同步指定版本（tag）
bash scripts/sync_gpu_exporter.sh v1.4.1
```

**同步流程**：

1. 使用 git sparse clone 拉取上游 `internal/exporter` 和 `internal/util` 目录
2. 复制 `.go` 源文件（跳过 `_test.go`）
3. 自动将 import 路径替换为本项目路径
4. 显示上游 commit 信息用于版本追踪

**同步后须执行**：

```bash
go mod tidy && go build ./...
```

---

## 重要提示

- **监控端口**：默认为 `745`，请确保防火墙已放行
- **端口安全**：仅允许可信网络访问监控端口
- **架构支持**：支持 `x86_64`（amd64）和 `aarch64`（arm64）
- **GPU 监控**：需要服务器上安装了 `nvidia-smi`，安装脚本会自动检测
