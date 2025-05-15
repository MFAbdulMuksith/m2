#!/bin/bash
set -euo pipefail

# ========================================================
# Client Monitoring Setup Script
# Installs: Node Exporter (metrics) + Promtail (logs)
# Version: 2.1
# ========================================================

# --- Configuration ---
readonly CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="/opt/monitoring"
readonly PROMTAIL_DIR="${BASE_DIR}/promtail"
readonly LOG_FILE="/var/log/client_monitoring_setup.log"
readonly DOCKER_NETWORK="monitoring-net"
readonly COMPOSE_FILE="${CONFIG_DIR}/docker-compose.yml"

# Service UID/GID (matching container users)
readonly PROMTAIL_UID=10001
readonly NODE_EXPORTER_UID=65534  # nobody

# --- Logging Setup ---
exec > >(tee -a "${LOG_FILE}") 2>&1

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")    echo -e "\033[1;36m[${timestamp}] INFO: ${message}\033[0m" ;;
        "SUCCESS") echo -e "\033[1;32m[${timestamp}] SUCCESS: ${message}\033[0m" ;;
        "WARNING") echo -e "\033[1;33m[${timestamp}] WARNING: ${message}\033[0m" ;;
        "ERROR")   echo -e "\033[1;31m[${timestamp}] ERROR: ${message}\033[0m" >&2 ;;
    esac
}

# --- Validation Checks ---
validate_environment() {
    # Root check
    [[ $EUID -eq 0 ]] || {
        log "ERROR" "Script must be run as root"
        exit 1
    }

    # Docker check
    command -v docker &>/dev/null || {
        log "ERROR" "Docker not installed"
        exit 1
    }

    # Docker Compose check
    if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
        log "ERROR" "Docker Compose not available"
        exit 1
    fi
}

# --- Filesystem Setup ---
setup_filesystem() {
    log "INFO" "Creating directory structure..."

    local dirs=(
        "${BASE_DIR}"
        "${PROMTAIL_DIR}/config"
        "${PROMTAIL_DIR}/data"
    )

    mkdir -p "${dirs[@]}"
    chmod -R 750 "${BASE_DIR}"

    # Set ownership
    chown -R ${PROMTAIL_UID}:${PROMTAIL_UID} "${PROMTAIL_DIR}"
    log "SUCCESS" "Directory structure created"
}

# --- Configuration Deployment ---
deploy_configs() {
    log "INFO" "Deploying configurations..."

    # Promtail config
    local promtail_config="${PROMTAIL_DIR}/config/promtail-config.yaml"
    if [[ ! -f "${promtail_config}" ]]; then
        if [[ -f "${CONFIG_DIR}/promtail-config.yaml" ]]; then
            cp "${CONFIG_DIR}/promtail-config.yaml" "${promtail_config}"
            chown ${PROMTAIL_UID}:${PROMTAIL_UID} "${promtail_config}"
            chmod 640 "${promtail_config}"
            log "SUCCESS" "Promtail config deployed"
        else
            log "ERROR" "Missing promtail-config.yaml in source directory"
            exit 1
        fi
    else
        log "WARNING" "Promtail config already exists - preserving existing file"
    fi

    # Positions file
    touch "${PROMTAIL_DIR}/data/positions.yaml"
    chown ${PROMTAIL_UID}:${PROMTAIL_UID} "${PROMTAIL_DIR}/data/positions.yaml"
    chmod 644 "${PROMTAIL_DIR}/data/positions.yaml"
}

# --- Docker Network Setup ---
setup_network() {
    if ! docker network inspect "${DOCKER_NETWORK}" &>/dev/null; then
        log "INFO" "Creating Docker network: ${DOCKER_NETWORK}"
        docker network create "${DOCKER_NETWORK}" || {
            log "ERROR" "Failed to create Docker network"
            exit 1
        }
    fi
}

# --- Service Management ---
start_services() {
    log "INFO" "Starting monitoring services..."

    local compose_cmd="docker compose"
    if command -v docker-compose &>/dev/null; then
        compose_cmd="docker-compose"
    fi

    ${compose_cmd} -f "${COMPOSE_FILE}" up -d || {
        log "ERROR" "Failed to start services"
        exit 1
    }
}

verify_services() {
    log "INFO" "Verifying services..."

    local services=("node_exporter" "promtail")
    local all_ok=true
    local timeout=60
    local interval=5

    for service in "${services[@]}"; do
        local elapsed=0
        local running=false

        while [[ $elapsed -lt $timeout ]]; do
            if docker ps --filter "name=${service}" --format '{{.Status}}' | grep -q "Up"; then
                running=true
                break
            fi
            sleep $interval
            elapsed=$((elapsed + interval))
        done

        if $running; then
            log "SUCCESS" "${service} is running"
        else
            log "ERROR" "${service} failed to start"
            docker logs "${service}" | tail -n 20
            all_ok=false
        fi
    done

    $all_ok || exit 1
}

# --- Main Execution ---
main() {
    log "INFO" "=== Starting Client Monitoring Setup ==="
    validate_environment

    log "INFO" "=== Filesystem Setup ==="
    setup_filesystem

    log "INFO" "=== Configuration Deployment ==="
    deploy_configs

    log "INFO" "=== Docker Network Setup ==="
    setup_network

    log "INFO" "=== Service Startup ==="
    start_services

    log "INFO" "=== Service Verification ==="
    verify_services

    log "SUCCESS" "Client monitoring setup completed successfully!"
    log "INFO" "Node Exporter metrics available on :9100"
    log "INFO" "Detailed logs: ${LOG_FILE}"
}

main "$@"
