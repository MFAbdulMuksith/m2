#!/bin/bash

# git clone URL
# cd REPONAME
# sudo chmod +x set.sh
# sudo ./set.sh

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo."
   exit 1
fi

# Define base directory for configurations and data
BASE_DIR="/opt/container"
PROMTAIL_DIR="$BASE_DIR/promtail"

# Create necessary directories
echo "Creating required directories..."
mkdir -p "$PROMTAIL_DIR"

# Set proper permissions for base directory
chmod -R 755 "$BASE_DIR"

# Function to copy files if they do not exist
copy_if_not_exists() {
    local src=$1
    local dest=$2
    if [[ ! -f "$dest" ]]; then
        if [[ -f "$src" ]]; then
            echo "Copying $src to $dest"
            cp "$src" "$dest"
        else
            echo "Warning: Source file $src not found. Skipping."
        fi
    else
        echo "Skipping $dest (already exists)."
    fi
}

# Copy configuration files only if they don't already exist
echo "Copying configuration files (if not already present)..."

copy_if_not_exists ./promtail/promtail-config.yaml "$PROMTAIL_DIR/promtail-config.yaml"
copy_if_not_exists ./promtail/positions.yaml "$PROMTAIL_DIR/positions.yaml"

# Set permissions function
set_permissions() {
    local file=$1
    local owner=$2
    local mode=$3
    if [[ -f "$file" ]]; then
        echo "Setting permissions for $file"
        chown "$owner" "$file"
        chmod "$mode" "$file"
    fi
}

# Apply permissions to configuration files
set_permissions "$PROMTAIL_DIR/promtail-config.yaml" root:root 644
set_permissions "$PROMTAIL_DIR/positions.yaml" root:root 644

# Set ownership and permissions for Promtail directory
echo "Setting data directory permissions..."
chown -R promtail:promtail "$PROMTAIL_DIR"
chmod -R 755 "$PROMTAIL_DIR"

# Ensure Docker network exists before running services
if ! docker network inspect monitor >/dev/null 2>&1; then
    echo "Creating 'monitor' Docker network..."
    docker network create monitor
fi

# Ensure Docker Compose is installed
if ! command -v docker-compose &>/dev/null; then
    echo "Error: docker-compose is not installed. Install it and try again."
    exit 1
fi

# Start the monitoring stack
echo "Starting Docker services..."
docker-compose up -d

# Final status
echo "✅ Monitoring Environment setup completed!"
