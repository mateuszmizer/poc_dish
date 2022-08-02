#!/bin/bash
ctx logger info "set aws creds for ${MANAGER_NAME}"
ctx logger info "ENV: ${ENV_TYPE_VALUE}"
ctx logger info "CLUSTER: ${CLUSTER_VALUE}"
export POD_NAME=$(kubectl get pods --all-namespaces --kubeconfig /etc/cloudify/.kube/config| grep "${MANAGER_NAME}"|awk '{print $2}')
export NAMESPACE=$(kubectl get pods --all-namespaces --kubeconfig /etc/cloudify/.kube/config| grep "${MANAGER_NAME}"|awk '{print $1}')
kubectl set env -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_VALUE}
kubectl set env -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_VALUE}
kubectl set env -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION_VALUE}
kubectl set env -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true ENV_TYPE=${ENV_TYPE_VALUE}
kubectl set env -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config --overwrite=true CLUSTER=${CLUSTER_VALUE}
ctx logger info "download script to local pod"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config -- /bin/bash -c "curl -LO https://raw.githubusercontent.com/mateuszmizer/poc_dish/main/aws_cli_installator/scripts/aws_cli_installer.sh"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config -- /bin/bash -c "sudo chmod +x aws_cli_installer.sh"
ctx logger info "Start AWS CLI installation"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config -- /bin/bash -c "./aws_cli_installer.sh"
ctx logger info "AWS CLI is installed"