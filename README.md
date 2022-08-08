# dish_poc

PRECONDITIONS

EKS/AKS Enviroment
Main manager has installed and configured: aws-cli, kubectl and azure-cli

All below steps can by executed by submanager_installation.zip package
________________________________________________________________________________________________________

STEPS:
1. Store kubeconfigs as secrets 
use:
kubeconfig_storager.zip

FOR EKS modify those value manually:
users:
- name: arn:aws:eks:ca-central-1:735096272642:cluster/nsgbjm-eks
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1   # <- correct value


2. Prepare configuration (install cert-manager and cert-issuer)
k8s_cert_configuration.zip

3. Install postgree, rabbitmq and CM worker (use verison 3.8.0 for installation - issue in ver. 3.9.0)
helm_blueprint.yaml

4. Install nfd
nfd-blueprint.zip

4. Install policy
policy.zip

5. SLA Matcher: bluprint for select which blueprint will be deployed on sepcified ENV (based on SLA value)
sla_matcher.zip
