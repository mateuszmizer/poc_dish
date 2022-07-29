#!/usr/bin/env python

from this import s
import requests
import json
import logging

from cloudify import manager, ctx
from cloudify.state import ctx_parameters as inputs
from cloudify import utils as cloudify_utils
from cloudify_rest_client.client import CloudifyClient
from cloudify_rest_client.exceptions import CloudifyClientError
from cloudify.exceptions import NonRecoverableError

ctx_logger = cloudify_utils.setup_logger('cloudify-agent.tests.installer.script', logger_level=logging.DEBUG)


def _get_cloudify_client():
    try:
        # Cloudify client setup
        client_config = ctx.instance.runtime_properties.get('client') or ctx.node.properties.get('client')
        return CloudifyClient(**client_config) if client_config else manager.get_rest_client()
    except CloudifyClientError as ex:
        raise NonRecoverableError('Client action "{0}" failed: {1}.'.format('delete', ex))


def get_deployment_which_match_sla(sla_value: str):
    deployments = []
    client = _get_cloudify_client()
    deployments_list_all = client.deployments.list()
    for deployment in deployments_list_all:
        deployment_id = deployment['id']
        labels_str = client.deployments.get(deployment_id=deployment_id)
        labels = [l['value'].lower() for l in list(eval(str(labels_str))['labels']) if 'sla_policy' in l['key']]
        if sla_value.lower() in labels:
            deployments.append(deployment_id)
    return deployments


if __name__=='__main__':
    sla = inputs.get('sla')
    matched_deployments = get_deployment_which_match_sla(sla)
    ctx_logger.info(matched_deployments)
    if matched_deployments:
        ctx.instance.runtime_properties["DEPLOY_ID"] = matched_deployments[-1]
    else:
        raise NonRecoverableError('No Environment match policy: {0}'.format(sla))
