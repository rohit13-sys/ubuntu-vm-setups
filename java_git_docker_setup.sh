#!/usr/bin/env bash

set -e

echo "======================================"
echo " Ubuntu Development Environment Setup "
echo "======================================"

# --------------------------------------
# Update system
# --------------------------------------
echo "[1/6] Updating system..."
sudo apt update
sudo apt upgrade -y

# --------------------------------------
# Basic dependencies
# --------------------------------------
echo "[2/6] Installing dependencies..."
sudo apt install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    tar \
    unzip

# --------------------------------------
# JAVA 20 - Eclipse Temurin
# --------------------------------------
echo "[3/6] Installing Java 20..."

JAVA_VERSION="20.0.2"
JAVA_BUILD="9"
JAVA_DIR="/opt/java"

sudo mkdir -p "$JAVA_DIR"

cd /tmp

JAVA_ARCHIVE="OpenJDK20U-jdk_x64_linux_hotspot_${JAVA_VERSION}_${JAVA_BUILD}.tar.gz"

JAVA_URL="https://github.com/adoptium/temurin20-binaries/releases/download/jdk-${JAVA_VERSION}%2B${JAVA_BUILD}/${JAVA_ARCHIVE}"

wget -O "$JAVA_ARCHIVE" "$JAVA_URL"

sudo tar -xzf "$JAVA_ARCHIVE" -C "$JAVA_DIR"

sudo ln -sfn "$JAVA_DIR/jdk-${JAVA_VERSION}+${JAVA_BUILD}" "$JAVA_DIR/java-20"

# JAVA environment variables
sudo tee /etc/profile.d/java20.sh > /dev/null <<'EOF'
export JAVA_HOME=/opt/java/java-20
export PATH=$JAVA_HOME/bin:$PATH
EOF

sudo chmod 644 /etc/profile.d/java20.sh

# Make Java available immediately in this shell
export JAVA_HOME=/opt/java/java-20
export PATH="$JAVA_HOME/bin:$PATH"

echo "Java version:"
java -version

# --------------------------------------
# GIT
# --------------------------------------
echo "[4/6] Installing Git..."

sudo apt install -y git

echo "Git version:"
git --version

# --------------------------------------
# DOCKER
# --------------------------------------
echo "[5/6] Installing Docker Engine..."

# Remove conflicting packages if present
sudo apt remove -y \
    docker.io \
    docker-compose \
    docker-compose-v2 \
    docker-doc \
    podman-docker \
    containerd \
    runc \
    2>/dev/null || true

# Docker official GPG key
sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

# Docker official repository
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

# Install Docker Engine + Compose
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Allow current user to use Docker without sudo
sudo usermod -aG docker "$USER"

echo "Docker version:"
sudo docker --version

echo "Docker Compose version:"
sudo docker compose version

# --------------------------------------
# GIT GLOBAL CONFIG
# --------------------------------------
echo "[6/6] Git configuration"

echo ""
echo "Git is installed."
echo "You can configure your Git identity later with:"
echo ""
echo 'git config --global user.name "Your Name"'
echo 'git config --global user.email "your@email.com"'
echo ""

# --------------------------------------
# FINISHED
# --------------------------------------
echo "======================================"
echo " Installation completed successfully "
echo "======================================"

echo ""
echo "Java:"
java -version

echo ""
echo "Git:"
git --version

echo ""
echo "Docker:"
sudo docker --version

echo ""
echo "IMPORTANT:"
echo "Log out and log back in (or reboot) for Docker group changes."
echo ""
echo "After logging back in, test Docker with:"
echo "docker run hello-world"
