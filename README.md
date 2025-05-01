# Simple AWS FLOW LOG explorer
In case your organization does not have log processing tool or you simply need to analyze only a small portion of logs
this is the tool!

## Prerequisites

`docker`, `curl`, `aws cli`

Run these commands to start the solution

`setup.sh` - prepare directory structure

`./download_vpc_logs.sh s3://bucket-name/THE_REST_OF_S3_URI` - it can be a single file or a whole directory
 example 1 day logs: ./download_vpc_logs.sh s3://my-bucket/AWSLogs/1234567890123/vpcflowlogs/eu-central-1/2025/04/24


`docker-compose up -d` - starts the whole machinery 
`./update-template.sh` - update index template 

`./monitor.sh` - simple indicator if everything works as expected

`./import_kibana_objects.sh` - pre-configure kibana with good defaults. 
Log timestamps are in UTC but Kibana shows timestamps in your timezone for convenient search.

then you can visit kibana and start exploring http://localhost:5601/
