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

    echo ""
    echo "Private Key file found. Please review your settings below:"
    echo ""
    echo "cluster_name=$cluster_name"
    echo "access_id=$access_id"
    echo "access_secret=$access_secret"
    echo "key_name=$key_name"
    echo "key_path=$key_path"

    echo "default_cluster_name=$cluster_name" > $settings_file
    echo "default_access_id=$access_id" >> $settings_file
    echo "default_access_secret=$access_secret" >> $settings_file
    echo "default_key_name=$key_name" >> $settings_file
    echo "default_key_path=$key_path" >> $settings_file
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

sed "s/###CLUSTER_NAME###/$cluster_name/g ; s/###ACCESS_ID###/$access_id/g ; s/###ACCESS_SECRET###/$access_secret/g ; s/###KEY_NAME###/$key_name/g ; s/###KEY_PATH###/$key_filename/g" "setup.yaml.template" > setup.yaml

#    4. Run docker container, expose web interface to host machine port 80
#docker run -d -p 80:8000 quay.io/geminidata/ge-app-setup:master_56



#    6. Edit setup.yaml to
#sed

#    7. Copy setup.yaml, .pem file to setup container
# docker ps
# docker cp setup.yaml <ps>:/project
# docker cp <keyname>.pem <ps>:/project

#    8. Run gectl cluster setup command within container
# gectl cluster setup -c setup.yaml --exclude=hdfs --exclude=influxdb --exclude=neo4j --exclude=spark --exclude=storybuilder --developer -vvvv &> setup.log &
