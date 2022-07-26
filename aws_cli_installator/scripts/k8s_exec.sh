#!/bin/bash
ctx logger info "set aws creds for ${MANAGER_NAME}"
ctx logger info "ENV: $ENV_TYPE"
ctx logger info "CLUSTER: $CLUSTER"
POD_NAME=$(kubectl get pods --all-namespaces --kubeconfig /etc/cloudify/.kube/config| grep "${MANAGER_NAME}"|awk '{print $2}')
echo $POD_NAME >> /etc/cloudify/my_log.log
NAMESPACE=$(kubectl get pods --all-namespaces --kubeconfig /etc/cloudify/.kube/config| grep "${MANAGER_NAME}"|awk '{print $1}')
ctx logger info "download script to local pod $POD_NAME"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config -- /bin/bash -c "curl -LO https://raw.githubusercontent.com/mateuszmizer/poc_dish/main/aws_cli_installator/scripts/aws_cli_installer.sh"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config -- /bin/bash -c "sudo chmod +x aws_cli_installer.sh"
ctx logger info "Start AWS CLI installation"
kubectl exec -ti $POD_NAME -n $NAMESPACE --kubeconfig /etc/cloudify/.kube/config -- /bin/bash -c "./aws_cli_installer.sh"
ctx logger info "AWS CLI is installed"