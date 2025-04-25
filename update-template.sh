#!/bin/bash
# Script to apply the Elasticsearch template for VPC flow logs

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch..."
until curl -s http://localhost:9200 >/dev/null; do
  sleep 2
done

echo "Applying VPC Flow Logs index template..."
curl -X PUT "localhost:9200/_index_template/vpc-flow-logs" \
  -H 'Content-Type: application/json' \
  -d @vpc-flow-logs-template.json

echo "Template applied successfully!"