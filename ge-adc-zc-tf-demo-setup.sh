# ADC deployment script

# install Docker
sudo amazon-linux-extras install docker

# update Docker permissions
sudo usermod -a -G docker ec2-user

# Start docker as service, pull ge-setup-app Docker image
sudo service docker start
docker pull quay.io/geminidata/ge-app-setup:master_56

# Run docker container, expose web interface to host machine port 80
docker run -d -p 80:8000 quay.io/geminidata/ge-app-setup:training

# Copy setup.yaml, .pem file to setup container
# docker ps
# docker cp setup.yaml <ps>:/project
# docker cp <keyname>.pem <ps>:/project
