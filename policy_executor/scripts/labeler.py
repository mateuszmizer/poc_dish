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



class Labeler:

    def __init__(self):
        self._create_cloudify_client()


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


if __name__=='__main__':
    deployment_id = inputs.get('deployment_id')
    sla_labels = [inputs.get('SLA_VALUE')]
    Labeler().update_deployment_labels(deployment_id=deployment_id, labels=sla_labels)
