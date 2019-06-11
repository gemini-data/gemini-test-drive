#!/usr/bin/env bash

# ADC deployment script
# High level steps
# 1. User clones repo, contains install script, config files, data sources
# 2. moves into repo directory, copies <keyname>.pem file to directory
# 3. Runs installation script:

#    1. install Docker
#echo Beginning ADC/Tensorflow demo environment installation....
#echo Installing docker.....
#sudo amazon-linux-extras install docker

#    2. update Docker permissions
#sudo usermod -a -G docker ec2-user

#    3. Start docker as a service, pull ge-setup-app Docker image
#echo Starting Docker Service
#sudo service docker start
#echo Pulling ADC setup image
#docker pull quay.io/geminidata/ge-app-setup:master_56


#    5. Prompt user for inputs: aws_region, access_id, access_secret, key_name
#echo Please enter which AWS region you would like to create the demo in:
#read -p 'AWS Region: ' aws_region
echo "Welcome to the setup of Gemini Enterprise Test Drive"
echo "----------------------------------------------------"
echo ""
echo "This script prompts for settings and AWS credentials and prepares the setup for you."
echo ""
echo Enter a name for your Gemini Enterprise Cluster:
read -p 'Cluster Name [gemini-enterprise-test-drive]: ' cluster_name
cluster_name=${cluster_name:-gemini-enterprise-test-drive}

echo ""
echo Please enter your AWS access id:
read -p 'AWS Access ID: ' access_id

echo ""
echo Please enter your AWS access secret:
read -p 'AWS Access Secret: ' access_secret

echo ""
echo Please enter your AWS keyname as it appears in the AWS console:
read -p 'AWS Key Name: ' key_name

echo ""

while true; do
    echo "Please enter the path to your private key (e.g. ~/.ssh/privatekey.pem):"
    read -p 'Private Key Path: ' key_path

    if [ ! -f "$key_path" ]; then
        echo "Key not found. Please make sure to specify the correct path."
    else
        break
    fi
done

echo "Private Key file found. Preparing setup.yaml now..."

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
