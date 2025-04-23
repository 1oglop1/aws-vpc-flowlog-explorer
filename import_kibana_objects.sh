#!/bin/bash

for file in config/kibana_import/*; do

  curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  --form "file=@$file"
  echo 
done

# curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
#   -H "kbn-xsrf: true" \
#   --form file=@config/kibana_import/rejected_traffic_viz.ndjson