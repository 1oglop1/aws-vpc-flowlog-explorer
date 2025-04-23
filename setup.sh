#!/bin/bash

# Stop any running containers
# docker-compose down 2>/dev/null

# Create required directories
mkdir -p data/logs

mkdir -p config/elasticsearch
mkdir -p config/logstash/pipeline
mkdir -p config/logstash/config
mkdir -p config/kibana/saved_objects

mkdir -p data/elasticsearch
mkdir -p data/kibana

mkdir -p config/fluent-bit

# Set required permissions
# chmod -R 777 data/loki

echo "Setup complete. Run 'docker-compose up -d' to start."