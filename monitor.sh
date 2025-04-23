#!/bin/bash

# curl -XGET 'localhost:9600/_node/stats/pipelines'
# curl -XGET 'localhost:9600/_node/stats'

# Script to monitor Fluent Bit processing

# Function to get metrics from Fluent Bit HTTP server
get_metrics() {
  curl -s http://localhost:2020/api/v1/metrics
}

# Function to check Elasticsearch indices and document count
check_es_indices() {
  echo "Elasticsearch Indices:"
  curl -s "http://localhost:9200/_cat/indices/vpc-flow-logs-*?v&h=index,docs.count,store.size"
}

# Function to check Fluent Bit processing rates
check_processing_rates() {
  echo "Processing Rates (records/sec):"
  
  # Get initial metrics
  local start_input=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_input_records_total' | awk '{print $NF}')
  local start_output=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_output_proc_records_total' | awk '{print $NF}')
  
  # Wait a bit to calculate rate
  sleep 2
  
  # Get final metrics
  local end_input=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_input_records_total' | awk '{print $NF}')
  local end_output=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_output_proc_records_total' | awk '{print $NF}')
  
  # Calculate rates (handle case where metrics might be missing)
  if [[ -n "$start_input" && -n "$end_input" ]]; then
    local input_rate=$(( (end_input - start_input) / 2 ))
    echo "  Input: ${input_rate} records/sec"
  else
    echo "  Input: N/A"
  fi
  
  if [[ -n "$start_output" && -n "$end_output" ]]; then
    local output_rate=$(( (end_output - start_output) / 2 ))
    echo "  Output: ${output_rate} records/sec"
  else
    echo "  Output: N/A"
  fi
}

# Function to show Fluent Bit status summary
check_fluent_bit_summary() {
  echo "Fluent Bit Status Summary:"
  
  # Input records
  local input_records=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_input_records_total' | awk '{print $NF}')
  echo "  Total Records Ingested: ${input_records:-N/A}"
  
  # Output records and errors
  local output_records=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_output_proc_records_total' | awk '{print $NF}')
  local output_errors=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_output_errors_total' | awk '{print $NF}')
  local output_retries=$(curl -s http://localhost:2020/api/v1/metrics | grep 'fluentbit_output_retries_total' | awk '{print $NF}')
  
  echo "  Total Records Processed: ${output_records:-N/A}"
  echo "  Total Errors: ${output_errors:-0}"
  echo "  Total Retries: ${output_retries:-0}"
  
  # Calculate success rate if possible
  if [[ -n "$input_records" && -n "$output_records" && "$input_records" -gt 0 ]]; then
    local success_rate=$(( (output_records * 100) / input_records ))
    echo "  Success Rate: ${success_rate}%"
  fi
}

check_index() {
    echo "=== VPC Flow Logs Ingestion Verification ==="
echo "Time: $(date)"
echo ""

echo "=== Elasticsearch Document Counts ==="
curl -s "localhost:9200/_cat/indices/vpc-flow-logs-*?v&h=index,docs.count,store.size"
echo ""

echo "=== Recent Document Count Changes ==="
for i in {1..5}; do
  COUNT_BEFORE=$(curl -s "localhost:9200/vpc-flow-logs-*/_count" | grep -o '"count":[0-9]*' | cut -d':' -f2)
  sleep 5
  COUNT_AFTER=$(curl -s "localhost:9200/vpc-flow-logs-*/_count" | grep -o '"count":[0-9]*' | cut -d':' -f2)
  DIFF=$((COUNT_AFTER - COUNT_BEFORE))
  echo "Documents added in last 5 seconds: $DIFF ($COUNT_BEFORE → $COUNT_AFTER)"
done

echo ""
echo "If document counts are increasing, Fluent Bit is successfully processing logs."
}

# Main monitoring loop
# while true; do
#   clear
#   echo "=== VPC Flow Logs Processing Monitor ==="
#   echo "Time: $(date)"
#   echo ""
  
# #   echo "=== Fluent Bit Summary ==="
# #   check_fluent_bit_summary
# #   echo ""
  
# #   echo "=== Processing Rates ==="
# #   check_processing_rates
# #   echo ""
  
#   echo "=== Elasticsearch Indices ==="
#   check_es_indices
#   echo ""
  
#   check_index
#   # Optional: Show detailed metrics
#   # echo "=== Detailed Metrics ==="
#   # get_metrics | grep -E 'fluentbit_(input|output)_(bytes|records|errors|retries)'
#   # echo ""
  
#   echo "Press Ctrl+C to exit. Refreshing in 5 seconds..."
#   sleep 5
# done

docker-compose logs fluent-bit > fb.log


# curl -X GET "localhost:9200/_cat/indices/vpc-flow-logs-*?v"
curl -X GET "localhost:9200/_cat/indices/vpc-flow-logs*?v"
echo
curl -X GET "localhost:9200/vpc-flow-logs*/_search?size=1"
echo
# Check available fields
curl -X GET "localhost:9200/vpc-flow-logs*/_mapping/field/*"
echo
# Check for specific field existence (e.g., srcaddr, dstaddr)
curl -X GET "localhost:9200/vpc-flow-logs*/_search?q=srcaddr:*&size=1"
echo
curl -X GET "localhost:9200/vpc-flow-logs*/_count"