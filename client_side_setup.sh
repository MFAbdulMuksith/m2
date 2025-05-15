#!/bin/bash
set -euo pipefail

# =============================================
# Client Monitoring Setup Script
# Installs:
# - Node Exporter (system metrics)
# - Promtail (log collection)
# =============================================

# Configuration
readonly BASE_DIR="/opt/client"
readonly CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)
readonly LOG_FILE="/var/log/client_monitoring_setup_${TIMESTAMP}.log"

# Service Versions
readonly NODE_EXPORTER_VERSION="1.6.1"
readonly PROMTAIL_VERSION="2.9.1"

# Initialize logging
exec > >(tee -a "${LOG_FILE}") 2>&1
echo "=== Starting Client Monitoring Setup $(date) ==="

# Helper Functions
function die() {
  echo "❌ [FATAL] $1" >&2
  exit 1
}

function info() {
  echo "ℹ️  [INFO] $1"
}

function success() {
  echo "✅ [SUCCESS] $1"
}

# Verify root privileges
function check_root() {
  if [[ $EUID -ne 0 ]]; then
    die "This script must be run as root. Use sudo."
  fi
}

# Check for required dependencies
function check_dependencies() {
  local missing=()

  if ! command -v docker &>/dev/null; then
    missing+=("docker")
  fi

  if ! docker compose version &>/dev/null && ! command -v docker-compose &>/dev/null; then
    missing+=("docker-compose")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing dependencies: ${missing[*]}"
  fi
}

# Setup directory structure
function setup_directories() {
  info "Creating directory structure..."

  local dirs=(
    "${BASE_DIR}/config"
    "${BASE_DIR}/data/promtail"
    "${BASE_DIR}/logs"
  )

  mkdir -p "${dirs[@]}"
  chmod -R 750 "${BASE_DIR}"
  success "Directories created"
}

# Deploy configuration files
function deploy_configs() {
  info "Deploying configurations..."

  # Promtail config
  if [[ -f "${CONFIG_DIR}/promtail-config.yml" ]]; then
    cp "${CONFIG_DIR}/promtail-config.yml" "${BASE_DIR}/config/promtail.yml"
    chmod 640 "${BASE_DIR}/config/promtail.yml"
  else
    die "Missing promtail-config.yml in ${CONFIG_DIR}"
  fi

  # Docker compose file
  if [[ -f "${CONFIG_DIR}/docker-compose.yml" ]]; then
    cp "${CONFIG_DIR}/docker-compose.yml" "${BASE_DIR}/docker-compose.yml"
  else
    generate_compose_file
  fi

  success "Configurations deployed"
}

# Generate Docker compose file if missing
function generate_compose_file() {
  cat > "${BASE_DIR}/docker-compose.yml" <<EOF
version: '3.8'

services:
  node-exporter:
    image: prom/node-exporter:v${NODE_EXPORTER_VERSION}
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
    ports:
      - "9100:9100"
    networks:
      - monitoring-net

  promtail:
    image: grafana/promtail:v${PROMTAIL_VERSION}
    container_name: promtail
    restart: unless-stopped
    user: "0:0"  # Run as root to read all logs
    volumes:
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ${BASE_DIR}/config/promtail.yml:/etc/promtail/config.yml
      - ${BASE_DIR}/data/promtail:/etc/promtail
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring-net

networks:
  monitoring-net:
    driver: bridge
EOF
}

# Create system user for services
function setup_system_user() {
  if ! id -u promtail &>/dev/null; then
    useradd --system --no-create-home --user-group promtail || true
  fi

  chown -R promtail:promtail "${BASE_DIR}/data/promtail"
}

# Create Docker network
function setup_network() {
  if ! docker network inspect monitoring-net &>/dev/null; then
    docker network create monitoring-net
    success "Created Docker network"
  fi
}

# Start services
function start_services() {
  info "Starting monitoring services..."

  cd "${BASE_DIR}"
  if docker compose version &>/dev/null; then
    docker compose up -d --wait
  else
    docker-compose up -d --wait
  fi

  success "Services started successfully"
}

# Verify services are running
function verify_services() {
  info "Verifying services..."

  local services=(
    "node-exporter"
    "promtail"
  )

  for service in "${services[@]}"; do
    if docker ps --filter "name=${service}" --format '{{.Status}}' | grep -q 'Up'; then
      success "${service} is running"
    else
      die "${service} failed to start. Check logs with: docker logs ${service}"
    fi
  done
}

# Main execution flow
function main() {
  check_root
  check_dependencies
  setup_directories
  deploy_configs
  setup_system_user
  setup_network
  start_services
  verify_services

  echo ""
  success "Client monitoring setup completed!"
  echo "   - Node Exporter metrics: http://13.229.79.31:9100/metrics"
  echo "   - Logs stored in: ${BASE_DIR}/data/promtail"
  echo "   - Setup logs: ${LOG_FILE}"
}

main "$@"
