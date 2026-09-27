#!/bin/bash

set -e

exec > >(tee -a /var/log/user-data.log) 2>&1

echo "=========================================="
echo "Starting Express EC2 setup"
echo "=========================================="

# Flask Backend URL
FLASK_BACKEND_URL="${backend_url}"

echo "Flask Backend URL: $FLASK_BACKEND_URL"

apt-get update -y

apt-get install -y \
    git \
    curl

echo "Installing Node.js 22..."

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

echo "Node.js version:"
node --version

echo "NPM version:"
npm --version

echo "Cloning application repository..."

rm -rf /opt/docker_ass

git clone https://github.com/yash5155/docker_ass.git /opt/docker_ass

echo "Repository cloned."

cd /opt/docker_ass/frontend

echo "Installing Express dependencies..."

npm install

echo "Starting Express frontend..."

export FLASK_BACKEND_URL="$FLASK_BACKEND_URL"

nohup npm start > /var/log/express.log 2>&1 &

echo "Express started on port 3000."

echo "=========================================="
echo "Express EC2 setup completed"
echo "=========================================="