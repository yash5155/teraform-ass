#!/bin/bash

set -e

# ============================================================
# Log user-data output
# ============================================================

exec > >(tee -a /var/log/user-data.log) 2>&1

echo "=========================================="
echo "Starting Flask EC2 setup"
echo "=========================================="


# ============================================================
# 1. Update system
# ============================================================

apt-get update -y


# ============================================================
# 2. Install required packages
# ============================================================

apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl


# ============================================================
# 3. Verify Python
# ============================================================

echo "Python version:"
python3 --version


# ============================================================
# 4. Clone project
# ============================================================

rm -rf /opt/docker_ass

git clone https://github.com/yash5155/docker_ass.git /opt/docker_ass

echo "Repository cloned."


# ============================================================
# 5. Setup Flask Backend
# ============================================================

cd /opt/docker_ass/backend

echo "Creating Python virtual environment..."

python3 -m venv venv

echo "Upgrading pip..."

/opt/docker_ass/backend/venv/bin/pip install --upgrade pip

echo "Installing Flask dependencies..."

/opt/docker_ass/backend/venv/bin/pip install -r requirements.txt


# ============================================================
# 6. Start Flask
# ============================================================

echo "Starting Flask backend..."

cd /opt/docker_ass/backend

nohup /opt/docker_ass/backend/venv/bin/python app.py \
    > /var/log/flask.log 2>&1 &

echo "Flask started on port 5000."


# ============================================================
# 7. Finish
# ============================================================

echo "=========================================="
echo "Flask EC2 setup completed"
echo "=========================================="