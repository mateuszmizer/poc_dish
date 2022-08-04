#!/bin/bash
ctx logger info "update size of deployment for path ${KUBECONFIG_PATH}"
kubectl patch deployment ${MANAGER_NAME} -n ${NAMESPACE} -p '{"spec": {"template": { "spec": {"volumes": [{"name": "runlock", "emptyDir":{"sizeLimit":"4Gi"}}, {"name": "run", "emptyDir":{"sizeLimit":"4Gi"}}]]}}}}}' --kubeconfig "${KUBECONFIG_PATH}" 
# kubectl patch deployment ${MANAGER_NAME} -n $NAMESPACE -p '{"spec": {"template": { "spec": {"volumes": [{"name": "run", "emptyDir":{"sizeLimit":"4Gi"}}]}}}}}' --kubeconfig /etc/cloudify/.kube/config 
kubectl set env deployment/${MANAGER_NAME} -n ${NAMESPACE} --kubeconfig "${KUBECONFIG_PATH}" --overwrite=true AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} AWS_DEFAULT_REGION=${REGION_VALUE} ENV_TYPE=${ENV_TYPE_VALUE} CLUSTER=${CLUSTER_NAME_VALUE}
# kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig ${KUBECONFIG_PATH} --overwrite=true AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
# kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig ${KUBECONFIG_PATH} --overwrite=true AWS_DEFAULT_REGION=${REGION_VALUE}
# kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig ${KUBECONFIG_PATH} --overwrite=true ENV_TYPE=${ENV_TYPE_VALUE}
# kubectl set env deployment/${MANAGER_NAME} -n $NAMESPACE --kubeconfig ${KUBECONFIG_PATH}--overwrite=true CLUSTER=${CLUSTER_NAME_VALUE}
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
cfy secrets create kubeconfig -s """$(cat ${KUBECONFIG})"""
# rm -rf ${KUBECONFIG_PATH}
#PART FOR CLI INSTALLATION
ctx logger info "set aws creds for ${MANAGER_NAME}"
ctx logger info "ENV: $ENV_TYPE"
ctx logger info "CLUSTER: $CLUSTER"
POD_NAME=$(kubectl get pods --all-namespaces --kubeconfig "${KUBECONFIG_PATH}"| grep "${MANAGER_NAME}"|awk '{print $2}')
echo $POD_NAME >> /etc/cloudify/my_log.log
NAMESPACE=$(kubectl get pods --all-namespaces --kubeconfig "${KUBECONFIG_PATH}"| grep "${MANAGER_NAME}"|awk '{print $1}')
ctx logger info "download script to local pod $POD_NAME"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig "${KUBECONFIG_PATH}" -- /bin/bash -c "curl -LO https://raw.githubusercontent.com/mateuszmizer/poc_dish/main/aws_cli_installator/scripts/aws_cli_installer.sh"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig "${KUBECONFIG_PATH}" -- /bin/bash -c "sudo chmod +x aws_cli_installer.sh"
ctx logger info "Start AWS CLI installation"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig "${KUBECONFIG_PATH}" -- /bin/bash -c "./aws_cli_installer.sh"
ctx logger info "AWS CLI is installed"
