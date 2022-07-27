#!/usr/bin/env python

from this import s
import requests
import json
import logging
import yaml

from cloudify import manager, ctx
from cloudify.state import ctx_parameters as inputs
from cloudify import utils as cloudify_utils
from cloudify_rest_client.client import CloudifyClient
from cloudify_rest_client.exceptions import CloudifyClientError
from cloudify.exceptions import NonRecoverableError

ctx_logger = cloudify_utils.setup_logger('cloudify-agent.tests.installer.script', logger_level=logging.DEBUG)
manager_name = 'cloudify-manager-aio'


class Manager:

    runner = cloudify_utils.LocalCommandRunner(ctx_logger)

    @property
    def pod_name(self):
        cmd = "kubectl get pods -A |grep " + manager_name + "|awk '{print $2}'"
        return self.runner.run(cmd).stdout

    @property
    def namespace(self):
        cmd = "kubectl get pods -A |grep " + manager_name + "|awk '{print $1}'"
        return self.runner.run(cmd).stdout


class AwsEksManager(Manager):

    """Class support AWS EKS API """

    def __init__(self, cluster_name: str, region: str):
        self._cmd = 'aws eks update-kubeconfig --region {} --name {}'.format(region, cluster_name)
            
    def set_as_k8s_context(self):
        """
            work only for AWS EKS
            aws eks update-kubeconfig --region {} --name {}
        """
        
        response = self.runner.run(self._cmd)


class AzureAksManager(Manager):

    """Class support Azure AKS API """

    def __init__(self, rg_id: str, aks_id: str):
        self._cmd = 'az aks get-credentials --name {} -g {}'.format(aks_id, rg_id)
 
    def set_as_k8s_context(self):
        self.runner.run(self._cmd)


def _get_api_manager():
    cluster_host = dict(inputs.get('cluster_host')).get('value')
    if 'amazonaws' in cluster_host.lower():
        ctx_logger.info('EKS part will be executed')
        cluster_name = dict(inputs.get('cluster_name')).get('value')
        region = dict(inputs.get('region')).get('value')
        k8smanager = AwsEksManager(cluster_name=cluster_name,
                                      region=region)
    elif 'azmk8s' in cluster_host.lower():
        ctx_logger.info('AZURE AKS part will be executed')
        rg_id = inputs.get('rg_id')
        aks_id = inputs.get('aks_id')
        k8smanager = AzureAksManager(rg_id=rg_id,
                                        aks_id=aks_id)
    return k8smanager



if __name__=='__main__':
    sla_values = []
    # deployment_id = inputs.get('deployment_id')
    k8smanager = _get_api_manager()
    k8smanager.set_as_k8s_context()
    ctx.instance.runtime_properties["POD_NAME"] = k8smanager.pod_name
    ctx.instance.runtime_properties["NAMESPACE"] = k8smanager.namespace


