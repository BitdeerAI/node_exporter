# Monitor Agent 安装指南

## 一、Node Exporter介绍

Node Exporter 是一个用于机器监控的代理，它收集硬件和操作系统的度量标准，并将它们暴露为 [Prometheus](https://prometheus.io/) 格式的 HTTP 服务端点。本仓库的 Node Exporter 基于 Prometheus 官方仓库[node_exporter](https://github.com/prometheus/node_exporter)进行开发，并特别集成了来自 [nvidia_gpu_exporter](https://github.com/utkuozdemir/nvidia_gpu_exporter) 的代码，以便更好地支持 NVIDIA GPU 的监控。

## 二、安装方法

我们提供了两种安装 Node Exporter 的方式，以满足不同用户的需求：

- **直接使用安装命令**: 对于大多数用户来说，直接使用我们提供的安装命令是最快捷的方式。只需在您的终端或命令行界面中输入相应的命令，即可自动下载并安装 Node Exporter。快速安装命令如下:
  
```bash
# If you do not have root privileges, execute this command
sudo su -

# Installation Commands
wget -qO- https://github.com/BitdeerAI/node_exporter/releases/download/v1.0-sh/install.sh | bash
```
  
- **自行编译安装**: 如果您希望从源代码开始编译 Node Exporter，或者需要对其进行自定义修改，您可以从我们的 GitHub 仓库中克隆代码，并按照说明进行编译和安装。
  
## 三、自主选择

我们鼓励用户根据自己的需求选择适合的 Node Exporter 仓库和安装方式。只要确保所选的 Node Exporter 版本符合 Prometheus 的监控规则和规范，即可无缝集成到您的监控系统中。

## 四、重要提示

- **监控端口**: 本版本的 Node Exporter 使用的监控端口默认为 745。请确保该端口在您的系统上已启用，否则系统监控将无法正常工作。
- **端口安全**" 出于安全考虑，请确保仅允许可信的网络和设备访问该端口。
- **非必要不删除**: Node Exporter 一旦安装并启用，将成为您监控系统的重要组成部分。在非必要的情况下，请勿随意删除或卸载 Node Exporter，以免影响系统的监控和性能。
