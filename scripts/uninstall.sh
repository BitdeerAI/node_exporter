set -e

systemctl stop node_exporter.service
systemctl disable node_exporter.service
rm /etc/systemd/system/node_exporter.service
rm /usr/local/bin/node_exporter_amd64
systemctl daemon-reload
