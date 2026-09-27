#!/bin/bash

set -e

# Log user-data output
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "Starting EC2 setup..."

# -----------------------------------
# Update packages
# -----------------------------------

apt-get update -y

# -----------------------------------
# Install Python, Git, Curl
# -----------------------------------

apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl

# -----------------------------------
# Install Node.js 22
# -----------------------------------

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

echo "Python:"
python3 --version

echo "Node:"
node --version

echo "NPM:"
npm --version

# -----------------------------------
# Clone project
# -----------------------------------

rm -rf /opt/docker_ass

git clone https://github.com/yash5155/docker_ass.git /opt/docker_ass

# ===================================
# Setup Flask Backend
# ===================================

cd /opt/docker_ass/backend

python3 -m venv venv

/opt/docker_ass/backend/venv/bin/pip install --upgrade pip

/opt/docker_ass/backend/venv/bin/pip install -r requirements.txt

# -----------------------------------
# Start Flask
# -----------------------------------

cd /opt/docker_ass/backend

nohup /opt/docker_ass/backend/venv/bin/python app.py \
    > /var/log/flask.log 2>&1 &

echo "Flask started on port 5000"

# ===================================
# Setup Express Frontend
# ===================================

cd /opt/docker_ass/frontend

npm install

# -----------------------------------
# Start Express
# -----------------------------------

export BACKEND_URL="http://127.0.0.1:5000"

nohup npm start \
    > /var/log/express.log 2>&1 &

echo "Express started on port 3000"

echo "======================================"
echo "Flask + Express deployment completed"
echo "======================================"