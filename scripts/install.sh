#!/bin/bash

# Set to exit the script if any command returns a non-zero status
set -e

# Variable definitions
sha256sum="793e14c3e9f743461566e7ff4dbd2dc8d038063520f84d42d0138a5ba694db30"
version="v1.1"

# Set port
if [ $# -eq 0 ]; then
  # Default
  port=745
else
  port=$1
fi

name="node_exporter_amd64"
gz_name="$name.tar.gz"
file_url="https://github.com/BitdeerAI/node_exporter/releases/download/$version/$gz_name"
tmp_file="/tmp/$gz_name"
tmp_dir="/tmp/$name"
tmp_bin="$tmp_dir/node_exporter"
bin_filename="/usr/local/bin/node_exporter_amd64"

if [ -f "$bin_filename" ]; then  
  echo "Installation exited because the NodeExporter already exists."
  exit 1
fi

# Donwload node_exporter release file
wget "$file_url" -P /tmp
computed_hash=$(sha256sum "$tmp_file" | awk '{print $1}')

if [[ "$computed_hash" != "$sha256sum" ]]; then
  echo "File verification failed"
  rm -rf "$tmp_file"
  exit 1
fi

# Unpack the tar file
tar -xzf "$tmp_file" -C /tmp
rm "$tmp_file"

# Set executable permissions for the downloaded binary file
chmod a+x "$tmp_bin"

# Move the binary file to the destination folder
cp "$tmp_bin" "$bin_filename"
rm -rf "$tmp_dir"

# Create Systemd service file
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=$bin_filename --web.listen-address=:$port
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload Systemd configuration
systemctl daemon-reload

# Start and enable the node_exporter service
systemctl enable node_exporter.service
systemctl start node_exporter.service
systemctl status node_exporter.service

# The installation is complete
echo "The installation is complete"
exit 0
