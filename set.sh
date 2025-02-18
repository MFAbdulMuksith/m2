#!/bin/bash

# git clone REPO-URl
# cd REPO
# sudo chmod +x set.sh
# Run this Script: ./set.sh

Ensure script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

# Define base directory for configurations and data
BASE_DIR="/opt/container"
PROMETHEUS_DIR="$BASE_DIR/prometheus"
ALERTMANAGER_DIR="$BASE_DIR/alertmanager"
GRAFANA_DIR="$BASE_DIR/grafana"
BLACKBOX_DIR="$BASE_DIR/blackbox"
LOKI_DIR="$BASE_DIR/loki"
PROMTAIL_DIR="$BASE_DIR/promtail"

# Create necessary directories
echo "Creating required directories..."
mkdir -p $PROMETHEUS_DIR/data
mkdir -p $ALERTMANAGER_DIR
mkdir -p $GRAFANA_DIR/data
mkdir -p $BLACKBOX_DIR
mkdir -p $LOKI_DIR
mkdir -p $PROMTAIL_DIR

# Create placeholder config files if they do not exist
# echo "Ensuring configuration files exist..."

# touch $PROMETHEUS_DIR/prometheus.yml
# touch $PROMETHEUS_DIR/alert.rules.yml
# touch $ALERTMANAGER_DIR/alertmanager.yml
# touch $BLACKBOX_DIR/config.yml
# touch $LOKI_DIR/loki-config.yaml
# touch $PROMTAIL_DIR/promtail-config.yaml

# Set proper permissions
echo "Setting permissions..."
chmod -R 755 $BASE_DIR
# chown -R $(whoami):$(whoami) $BASE_DIR

# Copy configuration files to the appropriate directories
sudo cp -R ./prometheus/prometheus.yml /opt/container/prometheus/prometheus.yml
sudo cp -R ./prometheus/alert.rules.yml /opt/container/prometheus/alert.rules.yml
sudo cp -R ./alertmanager/alertmanager.yml /opt/container/alertmanager/alertmanager.yml
sudo cp -R ./blackbox-exporter/config.yml /opt/container/blackbox/config.yml
sudo cp -R ./loki/loki-config.yaml /opt/prometheus/loki/loki-config.yaml
sudo cp -R ./promtail/promtail-config.yaml /opt/prometheus/promtail/promtail-config.yaml
sudo cp -R ./promtail/positions.yaml /opt/prometheus/promtail/positions.yaml

# Prometheus
sudo chown root:root /opt/container/prometheus/prometheus.yml
sudo chmod 644 /opt/container/prometheus/prometheus.yml
sudo chown root:root /opt/container/prometheus/alert.rules.yml
sudo chmod 644 /opt/container/prometheus/alert.rules.yml
sudo mkdir -p /opt/container/prometheus/data
sudo chown -R 65534:65534 /opt/container/prometheus/data
sudo chmod -R 777 /opt/container/prometheus/data

# Grafana
sudo mkdir -p /opt/container/grafana/data
sudo chown -R 472:472 /opt/container/grafana/data
sudo chmod -R 775 /opt/container/grafana/data

# Promtail
sudo mkdir -p /opt/prometheus/promtail/promtail-positions
sudo chown -R promtail:promtail /opt/prometheus/promtail/promtail-positions
sudo chmod -R 775 /opt/prometheus/promtail/promtail-positions
sudo chown root:root /opt/prometheus/promtail/promtail-config.yaml
sudo chmod 644 /opt/prometheus/promtail/promtail-config.yaml
sudo touch /opt/container/promtail/promtail-config.yaml
sudo chmod 644 /opt/container/promtail/promtail-config.yaml
sudo chown root:root /opt/container/promtail/promtail-config.yaml
sudo chown -R promtail:promtail /opt/container/promtail
sudo chmod -R 644 /opt/container/promtail/*



# Loki
sudo chown root:root /opt/prometheus/loki/loki-config.yaml
sudo chmod 644 /opt/prometheus/loki/loki-config.yaml
sudo mkdir -p /opt/prometheus/loki-data
sudo chown -R 10001:10001 /opt/prometheus/loki-data
sudo chmod -R 775 /opt/prometheus/loki-data
sudo touch /opt/container/loki/loki-config.yaml
sudo chmod 644 /opt/container/loki/loki-config.yaml
sudo chown root:root /opt/container/loki/loki-config.yaml

docker network create monitor

# Ensure Docker network exists
echo "Ensuring 'monitor' network exists..."
docker network inspect monitor >/dev/null 2>&1 || docker network create monitor

# Start the monitoring stack
echo "Starting Docker services..."
docker-compose up -d

echo "Monitoring Environment setup completed!"
echo "Test access to the services:"
echo "Prometheus: http://43.205.119.100:9090"
echo "Grafana: http://43.205.119.100:3000"
echo "Alertmanager: http://43.205.119.100:9093"
echo "Traefik Dashboard: http://43.205.119.100:8050"
