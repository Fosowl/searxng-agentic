#!/bin/bash

# Script to automate SearXNG setup and deployment with Docker Compose
# Assumes docker-compose.yml already exists in the current directory
# Run this script with: bash setup_searxng.sh

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if Docker is installed
if ! command_exists docker; then
    echo "Error: Docker is not installed. Please install Docker first."
    echo "On Ubuntu: sudo apt install docker.io"
    echo "On macOS/Windows: Install Docker Desktop from https://www.docker.com/get-started/"
    exit 1
fi

# Check if Docker daemon is running
echo "Checking if Docker daemon is running..."
if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running or inaccessible."
    # Attempt to start Docker (Linux-specific)
    if [ "$(uname)" = "Linux" ]; then
        echo "Trying to start Docker service (may require sudo)..."
        if sudo systemctl start docker &> /dev/null; then
            echo "Docker started successfully."
        else
            echo "Failed to start Docker. Possible issues:"
            echo "1. Run this script with sudo: sudo bash setup_searxng.sh"
            echo "2. Check Docker installation: sudo systemctl status docker"
            echo "3. Add your user to the docker group: sudo usermod -aG docker $USER (then log out and back in)"
            exit 1
        fi
    else
        echo "Please start Docker manually:"
        echo "- On macOS/Windows: Open Docker Desktop."
        echo "- On Linux: Run 'sudo systemctl start docker' or check your distro's docs."
        exit 1
    fi
else
    echo "Docker daemon is running."
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    echo "Error: Docker Compose is not installed. Please install it first."
    echo "On Ubuntu: sudo apt install docker-compose"
    echo "Or via pip: pip install docker-compose"
    exit 1
fi

# Create a directory for SearXNG config if it doesn’t exist
mkdir -p searxng
cd . || exit

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found in the current directory."
    echo "Please create it before running this script."
    exit 1
fi

# Start containers to generate initial config files (without cap_drop: - ALL)
echo "Starting containers for initial setup..."
if ! docker-compose up -d; then
    echo "Error: Failed to start containers. Check Docker logs with 'docker compose logs'."
    echo "Possible fixes: Run with sudo or ensure port 8080 is free."
    exit 1
fi
sleep 10  # Wait for settings.yml to be generated

# Generate a secret key and update settings.yml
SECRET_KEY=$(openssl rand -hex 32)
if [ -f "searxng/settings.yml" ]; then
    # Cross-platform sed command: use -i '' for macOS/BSD, no backup for Linux
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "s/ultrasecretkey/$SECRET_KEY/g" searxng/settings.yml || {
            echo "Warning: Failed to update settings.yml with secret key. Please check the file manually."
        }
    else
        sed -i "s/ultrasecretkey/$SECRET_KEY/g" searxng/settings.yml || {
            echo "Warning: Failed to update settings.yml with secret key. Please check the file manually."
        }
    fi
else
    echo "Error: settings.yml not found. Initial setup may have failed."
    docker-compose logs searxng
    exit 1
fi

# Stop containers
echo "Stopping containers to apply security settings..."
docker-compose down

# Add cap_drop: - ALL back to the searxng service for security if not already present
if ! grep -q "cap_drop:" docker-compose.yml; then
    sed -i'' '/cap_add:/i\    cap_drop:\n      - ALL' docker-compose.yml || {
        echo "Warning: Failed to add cap_drop to docker-compose.yml. Please add it manually for security."
    }
fi

# Start containers again with secure settings
echo "Deploying SearXNG with secure settings..."
if ! docker-compose up -d; then
    echo "Error: Failed to deploy SearXNG. Check logs with 'docker compose logs'."
    exit 1
fi

# Display status and access instructions
echo "SearXNG setup complete!"
docker ps -a --filter "name=searxng" --filter "name=redis"
echo "Access SearXNG at: http://localhost:8080"
echo "To view logs: docker compose logs -f"
echo "To stop: docker compose down"

export SEARXNG_BASE_URL="http://0.0.0.0:8081/"