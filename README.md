# Client-Side Monitoring with Docker Compose

This project sets up a client-side monitoring solution using Docker Compose. It deploys **Node Exporter** for system metrics collection and **Promtail** for log aggregation.

- **Node Exporter** for host metrics
- **Promtail** for log collection


## Requirements

Before proceeding, ensure the following dependencies are installed:

- Docker
- Docker Compose
- Access to a **Linux server** with proper privileges for container creation and network management.

## Overview

### 1. **Node Exporter** (Prometheus Exporter for System Metrics)
- Image: `prom/node-exporter:v1.4.0`
- Collects and exposes system metrics for Prometheus.
- Runs on port `9100`.
- Mounts `/proc`, `/sys`, and `/rootfs` for system-level monitoring.
- Custom command arguments exclude specific mount points.

### 2. **Promtail** (Log Aggregation for Loki)
- Image: `grafana/promtail:3.2.1`
- Collects logs from `/var/log` and forwards them to Loki.
- Uses configuration from `/opt/container/promtail/promtail-config.yaml`.
- Stores log positions in `/opt/container/promtail/positions.yaml` to avoid duplication.

## Directory Structure

```
.
├── docker-compose.yml
├── node-exporter
├── promtail
│   ├── positions.yaml
│   └── promtail-config.yaml
├── set.sh

```

## Getting Started

### 1. Clone the Repository

Clone this repository to your server.

```bash
 git clone <your-repo-url>
 cd <your-repo-folder>
```

### 2. Modify Configuration Files

Before running the stack, you may want to customize configuration files based on your needs. Here the key files to check:

- **`promtail/promtail-config.yaml`**: Config for collecting logs with Promtail.

### 3. Run the Setup Script

Make sure you run the setup script (`set.sh`) as a root user or with sudo permissions to prepare the directories and configuration files.

```bash
chmod +x set.sh
./set.sh
```

### 4. Start the Stack

Once the setup script has completed, you can start the stack using Docker Compose.

```bash
docker-compose up -d
```

This command will:
- Start all containers (`node-exporter` and `promtail` containers.).
- Set up networking between containers.

### 5. Access the Services

Once the containers are up and running, you can access the services through the following URLs:

- **Node Exporter**: `http://<PUBLIC-IP>:9100`

### 6. Verify Running Containers

Check if the containers are running:
```bash
 docker ps
```
Expected output should include `node-exporter` and `promtail` containers.

## Key Components

### 1. **Node Exporter**

Node Exporter collects hardware and OS metrics from the host machine (e.g., CPU, memory, disk usage).


### 2. **Loki & Promtail**

Loki collects logs from your applications, and Promtail is used to push logs to Loki from your services. This helps in aggregating logs in a central place for better debugging and monitoring.

## Managing the Stack

### 1. **Stopping the Stack**

To stop the stack, use the following command:

```bash
docker-compose down
```

This will stop all services and remove containers. However, volumes will remain unless explicitly removed.

### 2. **Logs & Debugging**

To view the logs of any container:

```bash
docker-compose logs <service-name>
```

Example for Grafana logs:

```bash
docker-compose logs promtail
```

### 3. **Updating the Stack**

To update any container or service, pull the latest image and restart the service:

```bash
docker-compose pull <service-name>
docker-compose up -d <service-name>
```

## Configuration Files
Ensure the following configuration files exist:

- **Promtail Configuration:** `/opt/container/promtail/promtail-config.yaml`
- **Log Position Tracking:** `/opt/container/promtail/positions.yaml`

Refer to the [Grafana Promtail Documentation](https://grafana.com/docs/loki/latest/clients/promtail/) for details on configuring Promtail.

## Troubleshooting

- **Node Exporter not accessible on port 9100?**
  - Ensure port 9100 is open and not blocked by a firewall.
  - Restart the container using: `docker restart node-exporter`.

- **Promtail not forwarding logs?**
  - Verify Promtail logs using: `docker logs promtail -f`
  - Check Promtail configuration syntax: `cat /opt/container/promtail/promtail-config.yaml`

## References
- [Prometheus Node Exporter](https://prometheus.io/docs/guides/node-exporter/)
- [Grafana Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)


---

# **Docker Installation and Configuration Guide**

## **1. Install Docker Using the Convenience Script**
Docker provides an official installation script that automates the installation process. This method is useful for quick installations but should be used with caution in production environments.

### **Step 1: Download the Installation Script**
```bash
curl -fsSL https://get.docker.com -o install-docker.sh
```
- `curl -fsSL` fetches the script securely.
- `-o install-docker.sh` saves it locally as `install-docker.sh`.

### **Step 2: Make the Script Executable**
```bash
sudo chmod +x install-docker.sh
```
- `chmod +x` grants execution permissions to the script.

### **Step 3: Perform a Dry Run (Optional)**
```bash
sh install-docker.sh --dry-run
```
- Runs a test installation without making changes.
- Useful for verifying what actions will be performed.

### **Step 4: Run the Installation Script**
```bash
sudo sh install-docker.sh
```
- Executes the script with root privileges to install Docker.

---

## **2. Verify Docker Installation**
Once installed, confirm that Docker is running:

```bash
docker --version
```
- Displays the installed Docker version.

```bash
sudo systemctl status docker
```
- Checks if the Docker service is running.

```bash
sudo docker run hello-world
```
- Runs a test container to verify functionality.

---

## **3. Manage Docker as a Non-Root User**
By default, Docker requires root privileges. To run it without `sudo`, follow these steps:

### **Step 1: Create a Docker User Group**
```bash
sudo groupadd docker
```
- Creates a `docker` group if it does not already exist.

### **Step 2: Add Your User to the Docker Group**
```bash
sudo usermod -aG docker $USER
```
- Adds the current user to the `docker` group.

### **Step 3: Apply Group Changes**
```bash
newgrp docker
```
- Applies group membership changes without requiring a logout.

### **Step 4: Verify Non-Root Access**
```bash
docker run hello-world
```
- If successful, Docker is accessible without `sudo`.

---

## **4. Fix Docker Permission Issues**
If there are permission issues when accessing Docker, follow these steps:

### **Step 1: Change Ownership of the `.docker` Directory**
```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
```
- Assigns ownership of `.docker` to the current user.

### **Step 2: Grant Group Permissions**
```bash
sudo chmod g+rwx "$HOME/.docker" -R
```
- Provides read, write, and execute permissions to the group.

---

## **5. Enable Docker to Start on Boot**
Ensure Docker services start automatically after reboot:

```bash
sudo systemctl enable docker.service
```
- Enables the main Docker service.

```bash
sudo systemctl enable containerd.service
```
- Enables the `containerd` service, which manages container runtimes.

---

## **6. Test Docker Functionality**
Run the following command to verify everything is working:
```bash
docker run hello-world
```
- If successful, you should see a message confirming that Docker is installed and running.

---


# To install Docker Compose on Ubuntu, follow these steps:

---

### **1. Install Docker**
Docker Compose requires Docker to be installed first. If Docker is not already installed, follow these steps:

#### Update your package list:
```bash
sudo apt update
```

#### Install Docker dependencies:
```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
```

#### Add Docker's official GPG key:
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

#### Add Docker's repository:
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### Update the package list again:
```bash
sudo apt update
```

#### Install Docker:
```bash
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

#### Verify Docker installation:
```bash
sudo docker --version
```

---

### **2. Install Docker Compose**
There are two ways to install Docker Compose: using the official binary or via `apt`. Below are both methods:

---

#### **Method 1: Install Docker Compose using the official binary (recommended)**

1. Download the latest stable release of Docker Compose:
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   ```
   Replace `v2.23.3` with the latest version from the [Docker Compose GitHub releases page](https://github.com/docker/compose/releases).

2. Apply executable permissions to the binary:
   ```bash
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. Verify the installation:
   ```bash
   docker-compose --version
   ```

---

#### **Method 2: Install Docker Compose via `apt` (older versions)**

1. Install Docker Compose:
   ```bash
   sudo apt install docker-compose -y
   ```

2. Verify the installation:
   ```bash
   docker-compose --version
   ```

---

### **3. Post-Installation Steps**

#### Add your user to the `docker` group (optional):
To run Docker and Docker Compose without `sudo`, add your user to the `docker` group:
```bash
sudo usermod -aG docker $USER
```

Then, log out and log back in for the changes to take effect.

---

### **4. Verify Docker Compose**
Test Docker Compose by running:
```bash
docker-compose --version
```
You should see output like:
```
Docker Compose version v2.23.3
```

---

### **5. Using Docker Compose**
You can now use Docker Compose to manage multi-container applications. For example:
```bash
docker-compose up -d
```
