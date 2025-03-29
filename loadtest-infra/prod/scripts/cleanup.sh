#!/bin/bash

echo "🧹 Removing old buha-backend container if exists..."
docker rm -f buha-backend 2>/dev/null || true

echo "📁 Cleaning /home/ec2-user/app directory..."
rm -rf /home/ec2-user/app/* || true