#!/bin/bash
# ==========================================
# TOM SPARK'S SAFE TORRENT BOX - One-Liner Installer
# Created by Tom Spark | youtube.com/@TomSparkReviews
#
# VPN Options:
#   NordVPN:   nordvpn.tomspark.tech   (4 extra months FREE!)
#   ProtonVPN: protonvpn.tomspark.tech (3 months FREE!)
#   Surfshark: surfshark.tomspark.tech (3 extra months FREE!)
# ==========================================

set -e

REPO_URL="https://github.com/loponai/oneshottorrent/archive/refs/heads/main.zip"
INSTALL_DIR="$HOME/Desktop/oneshottorrent-main"

echo "=========================================="
echo "  Tom Spark's Safe Torrent Box Installer"
echo "=========================================="
echo ""

# Check for required tools
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo "Error: curl or wget is required"
    exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo "Error: unzip is required"
    exit 1
fi

# Create Desktop directory if it doesn't exist
mkdir -p "$HOME/Desktop"

# Download and extract
echo "Downloading Safe Torrent Box..."
cd "$HOME/Desktop"

if command -v curl &> /dev/null; then
    curl -fsSL "$REPO_URL" -o oneshottorrent.zip
else
    wget -q "$REPO_URL" -O oneshottorrent.zip
fi

echo "Extracting..."
unzip -q -o oneshottorrent.zip
rm oneshottorrent.zip

# Run setup
echo "Starting setup..."
cd "$INSTALL_DIR"
chmod +x setup.sh
./setup.sh
