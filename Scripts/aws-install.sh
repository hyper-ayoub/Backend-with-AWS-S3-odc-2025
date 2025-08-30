#!/bin/bash
set -e

echo "🔎 Removing any old AWS CLI installations..."
sudo apt remove -y awscli || true
pip3 uninstall -y awscli || true

echo "⬇️ Downloading AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

echo "📦 Unzipping installer..."
unzip -o awscliv2.zip

echo "⚙️ Installing AWS CLI v2..."
sudo ./aws/install --update

echo "🧹 Cleaning up..."
rm -rf awscliv2.zip aws/

echo "✅ AWS CLI installed successfully!"
aws --version

echo ""
echo "👉 Next step: run 'aws configure' to set up your credentials."