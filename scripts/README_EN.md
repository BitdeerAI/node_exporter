# Monitor Agent Installation Guide

## 1. Node Exporter Introduction

Node Exporter is an agent for machine monitoring that collects hardware and operating system metrics and exposes them as HTTP service endpoints in [Prometheus](https://prometheus.io/) format. The Node Exporter in this repository is developed based on the official Prometheus repository [node_exporter](https://github.com/prometheus/node_exporter), and specially integrates the code from [nvidia_gpu_exporter](https://github.com/utkuozdemir/nvidia_gpu_exporter) to better support NVIDIA GPU monitoring.

## 2. Installation Method

We provide two ways to install Node Exporter to meet the needs of different users:

- **Directly use the installation command**: For most users, directly using the installation command we provide is the fastest way. Just enter the corresponding command in your terminal or command line interface to automatically download and install Node Exporter. The quick installation command is as follows:

```bash
# If you do not have root privileges, execute this command
sudo su -

# Installation Commands
wget -qO- https://github.com/BitdeerAI/node_exporter/releases/download/v1.0-sh/install.sh | bash
```

- **Self-compilation and installation**: If you want to compile Node Exporter from source code or need to customize it, you can clone the code from our GitHub repository and follow the instructions to compile and install it.

## 3. Custom selection

We encourage users to choose the appropriate Node Exporter repository and installation method according to their needs. Just make sure that the selected Node Exporter version complies with the monitoring rules and specifications of Prometheus, and it can be seamlessly integrated into your monitoring system.

## 4. Important tips

- **Monitoring port**: The monitoring port used by this version of Node Exporter defaults to 745. Please make sure that this port is enabled on your system, otherwise system monitoring will not work properly.
- **Port Security**: For security reasons, please ensure that only trusted networks and devices are allowed to access this port.
- **Do not delete unless necessary**: Once installed and enabled, Node Exporter will become an important part of your monitoring system. Do not delete or uninstall Node Exporter unless necessary to avoid affecting the monitoring and performance of the system.