#!/usr/bin/env bash

settings_file="settings"

echo "Welcome to the setup of Gemini Enterprise Test Drive"
echo "----------------------------------------------------"
echo ""
echo "This script prompts for settings and AWS credentials and prepares the setup for you."
echo ""

function prompt_settings() {
    read_settings

    default_cluster_name=${default_cluster_name:-gemini-enterprise-test-drive}
    echo Enter a name for your Gemini Enterprise Cluster:
    read -p "Cluster Name [$default_cluster_name]: " cluster_name
    cluster_name=${cluster_name:-$default_cluster_name}

    default_access_id=${default_access_id:-"AAAAAAAAAAAAA"}
    echo ""
    echo Please enter your AWS access id:
    read -p "AWS Access ID [$default_access_id]: " access_id
    access_id=${access_id:-$default_access_id}

    default_access_secret=${default_access_secret:-"BBBBBBBBBB"}
    echo ""
    echo Please enter your AWS access secret:
    read -p "AWS Access Secret [$default_access_secret]: " access_secret
    access_secret=${access_secret:-$default_access_secret}

    echo ""
    default_key_name=${default_key_name:-"mykeypair"}
    echo Please enter your AWS keyname as it appears in the AWS console:
    read -p "AWS Key Name [$default_key_name]: " key_name
    key_name=${key_name:-$default_key_name}

    echo ""

    detect_private_key

    echo ""
    echo "Private Key file found. Please review your settings below:"
    echo ""
    echo "cluster_name=$cluster_name"
    echo "access_id=$access_id"
    echo "access_secret=$access_secret"
    echo "key_name=$key_name"
    echo "key_path=$key_path"

    cluster_name=`printf '%q' $cluster_name`
    access_id=`printf '%q' $access_id`
    access_secret=`printf '%q' $access_secret`
    key_name=`printf '%q' $key_name`
    key_path=`printf '%q' $key_path`

    echo "default_cluster_name=\"$cluster_name\"" > $settings_file
    echo "default_access_id=\"$access_id\"" >> $settings_file
    echo "default_access_secret=\"$access_secret\"" >> $settings_file
    echo "default_key_name=\"$key_name\"" >> $settings_file
    echo "default_key_path=\"$key_path\"" >> $settings_file
}

function prompt_private_key() {
    while true; do
        echo "Please enter the path to your private key:"
        default_key_path=${default_key_path:-"~/.ssh/privatekey.pem"}
        read -p "Private Key Path [$default_key_path]: " key_path
        key_path=${key_path:-$default_key_path}

        if [ ! -f "$key_path" ]; then
            echo "Key not found. Please make sure to specify the correct path."
        else
            break
        fi
    done
}

function detect_private_key() {
    detected_key=`find ~/.ssh/ -name "*.pem" | head -1`
    if [ -f $detected_key ]; then
        read -r -p "Found key at $detected_key. Do you want to proceed with this? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                key_path=$detected_key
                ;;
            *)
                prompt_private_key
                ;;
        esac
    else
        echo "No private key detected. Please specify the path to the previously uploaded .pem file."
        prompt_private_key
    fi
}

function read_settings() {

    if [ -f "settings" ]; then
        echo "Loading settings..."
        source $settings_file
    fi
}

while true ; do
    prompt_settings
    echo
    read -r -p "Are these settings correct? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            break
            ;;
        *)

            ;;
    esac
done

echo "Preparing setup.yaml now..."
key_filename=$(basename -- "$key_path")

sed "s~###CLUSTER_NAME###~$cluster_name~g ; s~###ACCESS_ID###~$access_id~g ; s~###ACCESS_SECRET###~$access_secret~g ; s~###KEY_NAME###~$key_name~g ; s~###KEY_PATH###~$key_filename~g" "setup.yaml.template" > setup.yaml

echo ""
echo "Preparation complete. Running setup docker container and adding config."
docker run --name gemini-setup -d -p 80:8000 quay.io/geminidata/ge-app-setup:master_56
docker cp setup.yaml gemini-setup:/project
docker cp $key_path gemini-setup:/project

echo "Done. Launching Gemini Enterprise setup now, this may take up to 50 minutes..."
echo ""
docker exec -it gemini-setup gectl cluster setup -c setup.yaml --exclude=hdfs --exclude=influxdb --exclude=neo4j --exclude=spark --exclude=storybuilder --developer -vvvv
echo ""
echo "Deployment of Gemini Enterprise Cluster was successful. Continuing to prepare environment..."
mkdir var
docker cp gemini-setup:/usr/local/gectl/var/tmp var/
docker cp gemini-setup:/usr/local/gectl/var/log var/

admin_url=`find var/ -name INFO.log | xargs grep URLs | grep -oP "http://[^']+"`
public_ip=`echo $admin_url | sed -E "s/http:\/\/([^\/]+).*/\\1/"`
public_dns=`host $public_ip | sed -E "s/.*pointer (.+)\.$/\\1/"`
master_ip=`find var/ -name INFO.log | xargs grep "Setting universe on" | sed -E "s/.*on (.+)/\\1/"`
jupyter_url="https://$public_dns/jupyterlab-notebook/"

echo "admin_url=\"$admin_url\"" >> $settings_file
echo "public_ip=\"$public_ip\"" >> $settings_file
echo "master_ip=\"$master_ip\"" >> $settings_file
echo "public_dns=\"$public_dns\"" >>  $settings_file
echo "jupyter_url=\"$jupyter_url\"" >> $settings_file

echo "Configuring Cluster and installing additional services..."
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.11/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos &&
dcos cluster setup http://$master_ip &&
dcos

dcos package repo add "DCOS Service Catalog" https://universe.mesosphere.com/repo
sed "s~###PUBLIC_IP###~$public_ip~g" "jupyter_service.json.template" > jupyter_service.json
dcos package --options=jupyter_service.json install jupyterlab --yes
dcos package repo remove "DCOS Service Catalog"

while true ; do
    status=`dcos task  jupyterlab-notebook | sed -n '2p' | awk '{print $4}'`
    if [ "$status" == "R" ]; then
        break
    else
        echo "Waiting for services, checking state again in 2s..."
        sleep 2
    fi
done

echo "Installing sample data sources..."


echo "######################################"
echo "# "
echo "# Public IP:   $public_ip "
echo "# Master IP:   $master_ip "
echo "# Admin URL:   $admin_url "
echo "# Jupyter URL: $jupyter_url "
echo "# "
echo "######################################"

#2019-06-13 06:52:14 INFO     URLs: ['http://35.165.255.34/admin']
#2019-06-13 06:52:15 INFO     Provision: COMPLETE
#2019-06-13 06:52:15 INFO     Duration: 00:49:09
#2019-06-13 06:52:15 INFO     Log Directory: /usr/local/gectl/var/log/20190613060256
#2019-06-13 06:52:15 INFO     State File: /usr/local/gectl/var/tmp/20190613060256/state
