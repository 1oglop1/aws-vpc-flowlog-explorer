#!/bin/bash

# Stop all containers
docker-compose down -v

# Remove only data directories, preserving configuration
rm -rf data/loki/data/*
rm -rf data/loki/wal/*
rm -rf data/grafana/*
rm -rf data/promtail/*
# rm -rf data/vpc_flow_logs/*
rm -rf data/fluent-bit
rm -rf data/elasticsearch
rm -rf data/kibana

echo "Cleanup complete. All containers stopped and data removed."
echo "Configuration files preserved. Run setup.sh and docker-compose up -d to restart."