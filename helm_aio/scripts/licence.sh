#!/bin/bash
ctx logger info "update size of deployment"
kubectl patch deployment ${MANAGER_NAME} -n $NAMESPACE -p '{"spec": {"template": { "spec": {"volumes": [{"name": "runlock", "emptyDir":{"sizeLimit":"4Gi"}}]}}}}}' --kubeconfig /etc/cloudify/.kube/config 
kubectl patch deployment ${MANAGER_NAME} -n $NAMESPACE -p '{"spec": {"template": { "spec": {"volumes": [{"name": "run", "emptyDir":{"sizeLimit":"4Gi"}}]}}}}}' --kubeconfig /etc/cloudify/.kube/config 
kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true AWS_DEFAULT_REGION=${REGION_VALUE}
kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true ENV_TYPE=${ENV_TYPE_VALUE}
kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true CLUSTER=${CLUSTER_VALUE}
ctx logger info "sleep for pod restart"
sleep 300
cfy profile delete ${IP} || true
ctx logger info "installing cfy licence for ${IP}"
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
