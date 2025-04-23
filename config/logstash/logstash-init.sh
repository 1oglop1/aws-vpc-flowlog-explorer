#!/bin/bash
# Wait for Elasticsearch to be ready
until curl -s elasticsearch:9200 >/dev/null; do sleep 2; done

# Create ingest pipeline
curl -X PUT "elasticsearch:9200/_ingest/pipeline/vpc-flow-logs-pipeline" -H 'Content-Type: application/json' -d '{
  "description": "VPC flow logs decompression pipeline",
  "processors": [
    {
      "gzip": {"field": "message", "target_field": "decompressed_content"}
    },
    {
      "split": {"field": "decompressed_content", "separator": "\n"}
    },
    {
      "grok": {
        "field": "decompressed_content",
        "patterns": ["%{NUMBER:version} %{DATA:account_id} %{DATA:interface_id} %{IPORHOST:srcaddr} %{IPORHOST:dstaddr} %{NUMBER:srcport:int} %{NUMBER:dstport:int} %{NUMBER:protocol:int} %{NUMBER:packets:int} %{NUMBER:bytes:int} %{NUMBER:start_time:int} %{NUMBER:end_time:int} %{DATA:action} %{DATA:log_status}"]
      }
    }
  ]
}'

# Start Logstash
exec /usr/local/bin/docker-entrypoint "$@"