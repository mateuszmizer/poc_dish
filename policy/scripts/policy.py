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


class APIManager:
    """
        General class to get node labels
    """

    @property
    def default_headers(self):
        return {
            "Authorization": "Bearer " + str(self.token)
        }
    
    @property
    def url(self):
        return f'{self.cluster_host}{self.api_type}'

    def get_nodes_labels(self):
        resp = requests.get(url=f'{self.url}/nodes', headers=self.default_headers, verify=self.verify)
        return resp.json()


class AwsEksAPIManager(APIManager):

    """Class support AWS EKS API """

    def __init__(self, cluster_host: str, cluster_name: str, region: str, api_type: str='/api/v1'):
        self.api_type = api_type
        self.cluster_host = cluster_host
        self.verify = False if 'https' in str(cluster_host).lower() else True
        self.token_cmd = 'aws --region {} eks get-token --cluster-name {}'.format(region, cluster_name)
            
    @property
    def token(self):
        """
            work only for AWS EKS
            aws --region us-west-1 eks get-token --cluster-name vhhyvj-eks
        """
        ctx.instance.runtime_properties['cluster_host'] = self.cluster_host
        runner = cloudify_utils.LocalCommandRunner(ctx_logger)
        response = runner.run(self.token_cmd)
        token = eval(response.std_out)['status']['token']
        return token


class AzureAksAPIManager(APIManager):

    """Class support Azure AKS API """

    def __init__(self, cluster_host: str, kubeconfig: str, api_type: str='/api/v1'):
        self.api_type = api_type
        self.cluster_host = cluster_host
        self.verify = False if 'https' in str(cluster_host).lower() else True
        self.kubeconfig = kubeconfig
 
    @property
    def token(self):
        """from kubeconfg"""
        token = yaml.safe_load(self.kubeconfig)['users'][0]['user']['token']
        return token


class PolicySLAMatcher:

    def __init__(self, file: str='sla.json'):
        self.sla_value = ''
        self.sla_policy = ''
        self._get_policy_implementation(file=file)
        self._create_cloudify_client()

    def __str__(self):
        return f'Current policy is {self.sla_value}'

    def _get_policy_implementation(self, file: str):
        path = f'scripts/{file}'
        file = ctx.download_resource(path)
        with open(file) as f:
            context = json.load(f)
            self.sla_policy = dict(context)

    def _is_labels_matched(self, labels, sla_values):
        return all([True if k in labels.keys() and v==labels[k] else False for k,v in sla_values.items()])

    def _create_cloudify_client(self):
        try:
           # Cloudify client setup
            client_config = ctx.instance.runtime_properties.get('client') or ctx.node.properties.get('client')
            self.client = CloudifyClient(**client_config) if client_config else manager.get_rest_client()
        except CloudifyClientError as ex:
            raise NonRecoverableError('Client action "{0}" failed: {1}.'.format('delete', ex))

    def update_deployment_labels(self, deployment_id: str, labels: list):
        old_labels_str = self.client.deployments.get(deployment_id=deployment_id)
        old_labels = [{l['key']: l['value']} for l in list(eval(str(old_labels_str))['labels']) if 'sla_policy' not in l['key']]
        all_labels = old_labels + labels
        self.client.deployments.update_labels(deployment_id=deployment_id,
                                              labels=all_labels)

    def match_sla(self, labels):
        """based on json file and node labels method return value of SLA"""
        self.sla_value = [k for k,v in self.sla_policy.items() if self._is_labels_matched(labels, v)]
        return self.sla_value


def _get_api_manager():
    cluster_host = dict(inputs.get('cluster_host')).get('value')
    if 'amazonaws' in cluster_host.lower():
        ctx_logger.info('EKS part will be executed')
        cluster_name = dict(inputs.get('cluster_name')).get('value')
        region = dict(inputs.get('region')).get('value')
        k8smanager = AwsEksAPIManager(cluster_host=cluster_host,
                                      cluster_name=cluster_name,
                                      region=region)
    elif 'azmk8s' in cluster_host.lower():
        ctx_logger.info('AZURE AKS part will be executed')
        rg_id = inputs.get('rg_id')
        aks_id = inputs.get('aks_id')
        kubeconfig = inputs.get('kube_config')
        k8smanager = AzureAksAPIManager(cluster_host=cluster_host,
                                        kubeconfig=kubeconfig)
    return k8smanager


if __name__=='__main__':
    sla_values = []
    deployment_id = inputs.get('deployment_id')
    k8smanager = _get_api_manager()
    policy_matcher = PolicySLAMatcher()
    data = k8smanager.get_nodes_labels()
    for k in data['items']:
        labels = k['metadata']['labels']
        sla_value = policy_matcher.match_sla(labels)
        sla_values += [k for k in sla_value if k not in sla_values]
        for i, l in enumerate(sla_value):
            ctx.instance.runtime_properties[f"{k['metadata']['name']}{i}"] = l
    policy_matcher.update_deployment_labels(deployment_id=deployment_id, labels=[{'SLA_POLICY': s} for s in sla_values])
