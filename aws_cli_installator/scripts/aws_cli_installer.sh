# support only centos installation
# sudo sh -c 'echo "cfyuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
ctx logger info "install unzip"
sudo yum install unzip -y
ctx logger info "upload aws cli package"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
# sudo ./aws/install
sudo ./aws/install -i /usr/bin/aws-cli -b /usr/bin
sudo -u cfyuser aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
sudo -u cfyuser aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
sudo -u cfyuser aws configure set default.region ${AWS_DEFAULT_REGION}
