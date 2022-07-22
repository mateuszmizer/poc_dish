cfy profile delete ${IP} || true
ctx logger info "installing cfy licence"
### This line is required to set the profile
ctx logger info "Setting Cloudify CLI"
#export CLOUDIFY_SSL_TRUST_ALL=true
cfy profiles use ${IP} -u admin -p ${ADMIN_PASSWORD} -t default_tenant
#cfy profiles use ${IP} -u admin -p ${ADMIN_PASSWORD} -t default_tenant --ssl
# sh -c "cd /tmp && curl ${LICENCE} -o cloudify"
cfy license upload /licence.yaml
ctx logger info "licence installed successfully"
cfy secrets create aws_access_key_id -s ${AWS_ACCESS_KEY_ID}
cfy secrets create aws_secret_access_key -s ${AWS_SECRET_ACCESS_KEY}
cfy secrets create kubeconfig -s """${KUBECONFIG}"""
