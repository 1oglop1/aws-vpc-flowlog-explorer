#!/bin/bash

# Source environment variables
# source .env

#!/bin/bash

# Display usage
usage() {
  echo "Usage: $0 <s3-uri>"
  echo "Example: $0 s3://my-bucket/AWSLogs/123456789/vpcflowlogs/us-east-1/2025/04/22"
  exit 1
}

# Check if S3 URI is provided
if [ $# -lt 1 ]; then
  usage
fi

S3_URI=$1

# Validate S3 URI format
if [[ ! $S3_URI =~ ^s3://([^/]+)/(.+)$ ]]; then
  echo "Invalid S3 URI format. Must be s3://bucket-name/path"
  usage
fi

# Extract bucket and path from URI
S3_BUCKET_NAME=$(echo $S3_URI | sed -E 's|s3://([^/]+)/.*|\1|')
S3_PATH=$(echo $S3_URI | sed -E 's|s3://[^/]+/(.*)|\1|')

# echo "Bucket: $S3_BUCKET_NAME"
# echo "Path: $S3_PATH"

# Extract service type from the path (vpcflowlogs, elasticloadbalancing, etc.)
SERVICE_TYPE=$(echo $S3_PATH | awk -F'/' '{for(i=1;i<=NF;i++) if($i=="vpcflowlogs" || $i=="elasticloadbalancing") print $i}')

# Extract region from the path
if [[ $S3_PATH == *"vpcflowlogs/"* ]]; then
  REGION=$(echo $S3_PATH | grep -o 'vpcflowlogs/[^/]*' | sed 's/vpcflowlogs\///')
elif [[ $S3_PATH == *"elasticloadbalancing/"* ]]; then
  REGION=$(echo $S3_PATH | grep -o 'elasticloadbalancing/[^/]*' | sed 's/elasticloadbalancing\///')
else
  echo "Unknown service type in S3_PATH. Please specify a path containing 'vpcflowlogs' or 'elasticloadbalancing'."
  exit 1
fi

# Extract account ID from the path
ACCOUNT_ID=$(echo $S3_PATH | awk -F'/' '{for(i=1;i<=NF;i++) if($i=="AWSLogs") print $(i+1)}')

# Check if S3 path is a file (ends with .log or .gz)
if [[ $S3_PATH == *.log ]] || [[ $S3_PATH == *.gz ]]; then
  echo "S3_PATH appears to be a file. Using aws s3 cp..."
  
  # Extract the filename from the path
  FILENAME=$(basename "$S3_PATH")
  
  # Get the directory part without the filename
  DIR_PATH=$(dirname "$S3_PATH")
  
  # Extract path suffix after region without the filename
  PATH_SUFFIX=$(echo $DIR_PATH | grep -o "${REGION}/.*" | sed "s|${REGION}/||")
  
  # Create target directory without including the filename
  if [ -n "$PATH_SUFFIX" ]; then
    TARGET_DIR="data/logs/${ACCOUNT_ID}/${SERVICE_TYPE}/${REGION}/${PATH_SUFFIX}"
  else
    TARGET_DIR="data/logs/${ACCOUNT_ID}/${SERVICE_TYPE}/${REGION}"
  fi
else
  echo "S3_PATH appears to be a directory."
  
  # Extract path suffix after region if it exists
  PATH_SUFFIX=$(echo $S3_PATH | grep -o "${REGION}/.*" | sed "s|${REGION}/||")
  
  # Create directory structure for logs
  if [ -n "$PATH_SUFFIX" ]; then
    TARGET_DIR="data/logs/${ACCOUNT_ID}/${SERVICE_TYPE}/${REGION}/${PATH_SUFFIX}"
  else
    TARGET_DIR="data/logs/${ACCOUNT_ID}/${SERVICE_TYPE}/${REGION}"
  fi
fi

# Create the target directory
mkdir -p "${TARGET_DIR}"
echo "Target directory: ${TARGET_DIR}"

# Download based on whether it's a file or directory
if [[ $S3_PATH == *.log ]] || [[ $S3_PATH == *.gz ]]; then
  # Download the file directly
  aws s3 cp "s3://${S3_BUCKET_NAME}/${S3_PATH}" "${TARGET_DIR}/${FILENAME}"
  
  # Check if download was successful
  if [ $? -eq 0 ]; then
    echo "Successfully downloaded ${FILENAME} to ${TARGET_DIR}"
  else
    echo "Failed to download ${FILENAME}"
    exit 1
  fi
else
  echo "Using aws s3 sync for directory..."
  
  # Download logs with sync for directory paths
  aws s3 sync "s3://${S3_BUCKET_NAME}/${S3_PATH}" "${TARGET_DIR}" \
    --exclude "*" \
    --include "*.log" \
    --include "*.gz"
fi

# Check if any files were downloaded
FILE_COUNT=$(find "${TARGET_DIR}" -type f | wc -l)
if [ "$FILE_COUNT" -eq 0 ]; then
  echo "No files were downloaded. Check your S3 path and permissions."
  exit 1
fi

echo "Download complete. Files saved to ${TARGET_DIR}"
echo "Total files: ${FILE_COUNT}"