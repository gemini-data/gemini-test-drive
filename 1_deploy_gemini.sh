#!/usr/bin/env bash

settings_file="settings"

echo "Welcome to the setup of Gemini Enterprise Test Drive"
echo "----------------------------------------------------"
echo ""
echo "This script prompts for settings and AWS credentials and prepares the setup for you."
echo ""

# -
# - Functions
# -

function prompt_settings() {
    read_settings

    default_cluster_name=${cluster_name:-gemini-enterprise-test-drive}
    echo Enter a name for your Gemini Enterprise Cluster:
    read -p "Cluster Name [$default_cluster_name]: " input_cluster_name
    cluster_name=${input_cluster_name:-$default_cluster_name}

    default_access_id=${access_id:-"AAAAAAAAAAAAA"}
    echo ""
    echo Please enter your AWS access id:
    read -p "AWS Access ID [$default_access_id]: " input_access_id
    access_id=${input_access_id:-$default_access_id}

    default_access_secret=${access_secret:-"BBBBBBBBBB"}
    echo ""
    echo Please enter your AWS access secret:
    read -p "AWS Access Secret [$default_access_secret]: " input_access_secret
    access_secret=${input_access_secret:-$default_access_secret}

    echo ""
    default_key_name=${key_name:-"mykeypair"}
    echo Please enter your AWS keyname as it appears in the AWS console:
    read -p "AWS Key Name [$default_key_name]: " input_key_name
    key_name=${input_key_name:-$default_key_name}

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

    echo "cluster_name=\"$cluster_name\"" > $settings_file
    echo "access_id=\"$access_id\"" >> $settings_file
    echo "access_secret=\"$access_secret\"" >> $settings_file
    echo "key_name=\"$key_name\"" >> $settings_file
    echo "key_path=\"$key_path\"" >> $settings_file
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
    if [ "$detected_key" != "" ] && [ -f $deteted_key ]; then
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

# -
# - MAIN LOGIC
# - Prompt user input
# -
cluster_complete="no"
if [ -d "var/" ]; then
    setup_complete=`find var/run/ -name setup_complete`
    if [ "$setup_complete" != "" ] && [ -f "$setup_complete" ]; then
        echo "You have an existing cluster running, will continue with service configuration and preparation but not touching the cluster."
        echo "If you want to start over, run ./99_teardown.sh first. Continuing now..."
        cluster_complete="yes"
    else
        echo "There is an incomplete Gemini Cluster installation detected. Please run ./99_teardown.sh first to clean up and rerun this script (./1_deploy_gemini.sh)"
        exit 99
    fi
fi

while true ; do
    prompt_settings
    echo
    read -r -p "Are these settings correct? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])

            # -
            # - AWS CLI configration and security group update
            # -
            [[ -d ~/.aws ]] || mkdir ~/.aws

            echo "[default]" > ~/.aws/config
            echo "region = us-west-2" >> ~/.aws/config

            echo "[default]" > ~/.aws/credentials
            echo "aws_access_key_id = $access_id" >> ~/.aws/credentials
            echo "aws_secret_access_key = $access_secret" >> ~/.aws/credentials

            echo ""
            echo "Validating specified settings..."
            echo ""
            aws_credential_test=`aws sts get-caller-identity 1>/dev/null 2>/dev/null ; echo $?`
            if [ "$aws_credential_test" != "0" ]; then
                echo "Supplied AWS credentials aren't valid, please try again."
            else
                aws_keypair_test=`aws ec2 describe-key-pairs --key-name "$key_name" 1>/dev/null 2>/dev/null ; echo $?`
                if [ "$aws_keypair_test" != "0" ]; then
                    echo "Supplied AWS credentials ar valid, but did not find the specificed key pair ('$key_name')."
                    echo "Please make sure to enter the name of the Key Pair exactly as it appears in the AWS console under EC2 -> Key Pairs"
                    echo ""
                else
                    echo "Successfully validated AWS credentials and Key Pair, continuing..."
                    echo ""
                    break
                fi
            fi
            ;;
        *)

            ;;
    esac

done

# -
# - Prepare setup.yaml and docker container for gectl
# -
echo "Preparing setup.yaml now..."
key_filename=$(basename -- "$key_path")

sed "s~###CLUSTER_NAME###~$cluster_name~g ; s~###ACCESS_ID###~$access_id~g ; s~###ACCESS_SECRET###~$access_secret~g ; s~###KEY_NAME###~$key_name~g ; s~###KEY_PATH###~$key_filename~g" "setup.yaml.template" > setup.yaml

if [ "$cluster_complete" == "no" ]; then
    echo ""
    echo "Preparation complete. Running setup docker container and adding config."
    docker run --name gemini-setup -d -p 80:8000 quay.io/geminidata/ge-app-setup:master_56
    docker cp setup.yaml gemini-setup:/project
    docker cp $key_path gemini-setup:/project


    # -
    # - Run gectl and extract data
    # -
    echo "Done. Launching Gemini Enterprise setup now, this may take up to 50 minutes..."
    echo ""
    docker exec -it gemini-setup gectl cluster setup -c setup.yaml --exclude=zero-copy --exclude=hdfs --exclude=influxdb --exclude=neo4j --exclude=spark --exclude=storybuilder --developer -vvvv
    echo ""

    [[ -d var ]] || mkdir var
    docker cp gemini-setup:/usr/local/gectl/var/tmp var/
    docker cp gemini-setup:/usr/local/gectl/var/log var/
    docker cp gemini-setup:/usr/local/gectl/var/run var/

    setup_complete=`find var/run/ -name setup_complete`
    if [ "$setup_complete" != "" ] && [ -f "$setup_complete" ]; then
        echo "Deployment of Gemini Enterprise Cluster was successful. Continuing to prepare environment..."
    else
        echo "Deployment of Gemini Enterprise Cluster was NOT successful. Please check the output above for errors or contact product@geminidata.com for assistance."
        echo "You might retry the deployment process by first cleaning up (run ./99_teardown.sh) and then start the deployment again (run ./1_deploy_gemini.sh)"
        echo ""
        exit 99
    fi
fi

# -
# - Prep settings
# -
admin_url=`find var/ -name INFO.log | xargs grep URLs | grep -oP "http://[^']+"`
public_ip=`echo $admin_url | sed -E "s/http:\/\/([^\/]+).*/\\1/"`
public_dns=`host $public_ip | sed -E "s/.*pointer (.+)\.$/\\1/"`
master_ip=`find var/ -name INFO.log | xargs grep "Setting universe on" | sed -E "s/.*on (.+)/\\1/"`
jupyter_url="https://$public_dns/jupyterlab-notebook/"
ssh_sg_id=`find var/ -name DEBUG.log | xargs grep "aws_security_group.ssh: Creation complete after" | sed -E "s/.*ID\:\s([^\)]+)\)/\\1/"`
sqlline_connect='!connect jdbc:avatica:remote:url=http://'"$public_ip"':8765 admin admin'

echo "admin_url=\"$admin_url\"" >> $settings_file
echo "public_ip=\"$public_ip\"" >> $settings_file
echo "master_ip=\"$master_ip\"" >> $settings_file
echo "public_dns=\"$public_dns\"" >>  $settings_file
echo "jupyter_url=\"$jupyter_url\"" >> $settings_file
echo "ssh_sg_id=\"$ssh_sg_id\"" >> $settings_file
echo "config_server_ip=\"$config_server_ip\"" >> $settings_file
echo "sqlline_connect=\"$sqlline_connect\"" >> $settings_file

# -
# - DCOS CLI install
# -
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.11/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos &&
dcos cluster setup http://$master_ip

config_server_ip=`dcos task ge-app-datapipeline-conf-server | sed -n "2p" | awk '{print $2}'`

echo "Configuring Cluster and installing additional services..."

sudo yum install java-1.8.0-openjdk -y

# -
# - Modify security group and get config server public ip
# -
aws ec2 authorize-security-group-ingress --group-id $ssh_sg_id --protocol tcp --port 2222 --cidr 0.0.0.0/0
config_server_public_ip=`aws ec2 describe-instances --filters "Name=private-ip-address,Values=$config_server_ip" | grep PublicIpAddress | sed -E "s/.*\:\s\"([^\"]+)\",/\\1/"`
echo "config_server_public_ip=\"$config_server_public_ip\"" >> $settings_file

# -
# - Zero-Copy service config and launch
# -
echo "Installing sample data sources..."
sudo rpm -ivh https://rpmfind.net/linux/dag/redhat/el7/en/x86_64/dag/RPMS/sshpass-1.05-1.el7.rf.x86_64.rpm
zip -r -j adapter.zip zerocopy/
sshpass -p changeme scp -o 'StrictHostKeyChecking no' -P 2222 adapter.zip gemini@"$config_server_public_ip":/project/data
curl "http://$master_ip/service/marathon/v2/apps/zero-copy/adapter/restart" -X POST
rm -rf adapter.zip

echo "Installing Gemini Zero-Copy Data Virtualization service..."
dcos marathon app add services/zerocopy.json

# -
# - Jupyter service config and launch
# -
echo "Installing Juypterlab service..."
cd notebook/ && zip -r ../jupyter.zip *.ipynb .bash* .jupyter/ .hadooprc/ .local/ .profile avatica-1.13.0.jar && cd ..
sshpass -p changeme scp -o 'StrictHostKeyChecking no' -P 2222 jupyter.zip gemini@"$config_server_public_ip":/project/data
rm -f jupyter.zip

dcos package repo add "DCOS Service Catalog" https://universe.mesosphere.com/repo
dcos marathon app add services/jupyter.json

while true ; do
    status=`dcos task  jupyterlab-notebook | sed -n '2p' | awk '{print $4}'`
    if [ "$status" == "R" ]; then
        echo "Services are up and running. Continuing..."
        break
    else
        echo "Waiting for service, checking state again in 2s..."
        sleep 2
    fi
done
dcos package repo remove "DCOS Service Catalog"

# -
# - Print final output
# -
echo ""
echo ""
echo "SUCCESS: All preparation done! Gemini Enterprise is now ready. Please continue with tutorial."
echo ""
echo "######################################"
echo "# "
echo "# Public IP:       $public_ip "
echo "# Master IP:       $master_ip "
echo "# Admin URL:       $admin_url "
echo "# Jupyter URL:     ${jupyter_url}lab/tree/gemini_test_drive.ipynb "
echo "# sqlline Connect: $sqlline_connect "
echo "# "
echo "######################################"
