#!/bin/sh
source 0_env.sh

# Deploy Elastic
id=2f44144af037725565d1e3423f540182
curl "http://$PUBLIC_IP/admin/admin/api/apps" --data-binary "{\"id\":\"$ELASTIC_NAME\",\"package\":{\"id\":\"$id\",\"name\":\"elastic\",\"version\":\"1.0.0\",\"install_type\":\"DCOS\",\"json_configs\":null,\"custom_config\":{\"service\":{\"name\":\"elastic\",\"log_level\":\"INFO\",\"app_id\":\"$ELASTIC_NAME\"},\"master_nodes\":{\"cpus\":1,\"mem\":2048,\"disk\":2000},\"data_nodes\":{\"cpus\":1,\"mem\":4096,\"disk\":10000,\"count\":2},\"ingest_nodes\":{\"cpus\":0.5,\"mem\":2048,\"disk\":2000},\"coordinator_nodes\":{\"cpus\":1,\"mem\":2048,\"disk\":1000,\"count\":1}}}}" --compressed

# Retrieve Elastic Data VIP
curl "http://$MASTER_IP/service/$ELASTIC_NAME/elastic/v1/endpoints/data-http" --compressed

#sed 's/###ELASTICHOST###/simon/g; s/###ELASTICPORT###/simonasdf/g' model.json.template > model.json
