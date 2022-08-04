#!/usr/bin/env python

from this import s
import logging

from cloudify import manager, ctx
from cloudify.state import ctx_parameters as inputs
from cloudify import utils as cloudify_utils


ctx_logger = cloudify_utils.setup_logger('cloudify-agent.tests.installer.script', logger_level=logging.DEBUG)
runner = cloudify_utils.LocalCommandRunner(ctx_logger)


def get_aws_eks_kubeconfig(region: str, eks_name: str, file: str):
    cmd = f'aws eks update-kubeconfig --region {region} --name {eks_name} --dry-run'
    response = runner.run(cmd)
    runner.run(f'echo "{response.std_out}" | tee "{file}"')
    return response.std_out.replace('client.authentication.k8s.io/v1beta1', 'client.authentication.k8s.io/v1alpha1')  # WA for helm issue


def get_azure_aks_kubeconfig(aks_id: str, rg_id: str, file: str):
    cmd = f'az aks get-credentials --name {aks_id} -g {rg_id} -f "{file}"'
    response = runner.run(cmd)
    return response.std_out


if __name__=='__main__':
    deployment_id = inputs.get('deployment_id')
    cluster_host = dict(inputs.get('cluster_host')).get('value')
    file = inputs.get("KUBECONFIG_PATH")
    if 'amazonaws' in cluster_host.lower():
        ctx_logger.info('EKS part will be executed')
        cluster_name = dict(inputs.get('cluster_name')).get('value')
        region = dict(inputs.get('region')).get('value')
        config = get_aws_eks_kubeconfig(region=region, eks_name=cluster_name, file=file)
        ctx.instance.runtime_properties["ENV"] = 'AWS'
    elif 'azmk8s' in cluster_host.lower():
        ctx_logger.info('AZURE AKS part will be executed')
        rg_id = inputs.get('rg_id')
        aks_id = inputs.get('aks_id')
        config = get_azure_aks_kubeconfig(aks_id=aks_id, rg_id=rg_id, file=file)
        ctx.instance.runtime_properties["ENV"] = 'AZURE'
    ctx.instance.runtime_properties["kubeconfig"] = config
    ctx.instance.runtime_properties["KUBECONFIG_PATH"] = file
