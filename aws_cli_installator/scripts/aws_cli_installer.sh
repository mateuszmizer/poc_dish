# support only centos installation
# sudo sh -c 'echo "cfyuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
#!/bin/bash
echo "install unzip"
sudo yum install unzip -y
echo "upload aws cli package"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
# sudo ./aws/install
echo "install aws for cfyuser"
sudo ./aws/install -i /usr/bin/aws-cli -b /usr/bin
echo "configure aws"
sudo -u cfyuser aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
sudo -u cfyuser aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
sudo -u cfyuser aws configure set default.region $AWS_DEFAULT_REGION
# if [[ "$ENV_TYPE" == "AWS" ]]; then
#     echo "AWS env...kubeconfig will be replaced..."
#     KUBECONFIGLOCAL=$(aws eks update-kubeconfig --region $AWS_DEFAULT_REGION --name $CLUSTER --dry-run)
#     echo $(aws eks update-kubeconfig --region $AWS_DEFAULT_REGION --name $CLUSTER --dry-run) >  /etc/cloudify/my_log.log
#     cfy secrets update kubeconfig -s """$KUBECONFIGLOCAL"""
# else
#     echo "AZURE ENV"
# fi
