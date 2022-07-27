ctx logger info "set aws creds"
export POD_NAME=$(kubectl get pods --all-namespaces | grep "${MANAGER_NAME}"|awk '{print $2}')
export NAMESPACE=$(kubectl get pods --all-namespaces | grep "${MANAGER_NAME}"|awk '{print $1}')
kubectl exec -ti $POD_NAME -n $NAMESPACE -- /bin/bash -c "export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
kubectl exec -ti $POD_NAME -n $NAMESPACE -- /bin/bash -c "export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
kubectl exec -ti $POD_NAME -n $NAMESPACE -- /bin/bash -c "export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
ctx logger info "download script to local pod"
kubectl exec -ti $POD_NAME -n $NAMESPACE -- /bin/bash -c "curl -LO https://raw.githubusercontent.com/mateuszmizer/poc_dish/main/aws_cli_installator/scripts/aws_cli_installer.sh"
kubectl exec -ti $POD_NAME -n $NAMESPACE -- /bin/bash -c "sudo chmod +x aws_cli_installer.sh"
ctx logger info "Start AWS CLI installation"
kubectl exec -ti $POD_NAME -n $NAMESPACE -- /bin/bash -c "./aws_cli_installer.sh"
ctx logger info "AWS CLI is installed"