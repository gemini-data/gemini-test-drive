#!/bin/sh
source settings

# Deploy Elastic
id=<placeholder>
curl "http://$public_ip/admin/admin/api/apps" --data-binary "{\"id\":\"elastic001\",\"package\":{\"id\":\"$id\",\"name\":\"elastic\",\"version\":\"1.0.0\",\"install_type\":\"DCOS\",\"json_configs\":null,\"custom_config\":{\"service\":{\"name\":\"elastic\",\"log_level\":\"INFO\",\"app_id\":\"elastic001\"},\"master_nodes\":{\"cpus\":1,\"mem\":2048,\"disk\":2000},\"data_nodes\":{\"cpus\":1,\"mem\":4096,\"disk\":10000,\"count\":2},\"ingest_nodes\":{\"cpus\":0.5,\"mem\":2048,\"disk\":2000},\"coordinator_nodes\":{\"cpus\":1,\"mem\":2048,\"disk\":1000,\"count\":1}}}}" --compressed

# Retrieve Elastic Data VIP
curl "http://$master_ip/service/elastic001/elastic/v1/endpoints/data-http" --compressed
