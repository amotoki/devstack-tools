#!/usr/bin/env python

# Usage: bulk_net_create net1 [net2 net3 ...]

import argparse
import json
import os
from pprint import pprint
import sys

from quantumclient.common import utils
from quantumclient.v2_0 import client as qclient
from quantumclient.quantum import v2_0 as q20

supported_resources = ['network', 'subnet', 'port']

def getclient():
    params = {'username': os.environ.get('OS_USERNAME'),
              'tenant_name': os.environ.get('OS_TENANT_NAME'),
              'password': os.environ.get('OS_PASSWORD'),
              'auth_url': os.environ.get('OS_AUTH_URL')}
    return qclient.Client(**params)

def bulk_create(resource, params, jsonfile=None):
    print ('resource=%(resource)s, params=%(params)s, '
           'jsonfile=%(jsonfile)s' % locals())
    if not params and not jsonfile:
        print 'No data is specified. Do nothing.' % resource
        return
    if jsonfile:
        with open(jsonfile) as f:
            body = json.loads(f.read())
    else:
        #collection = '%ss' % resource
        #body = {collection: [{'name': n} for n in params]}
        body = formatters[resource](params)
        #body = format_network_params(params)
        pprint(body)

    print 'Request body ---->'
    pprint(json.dumps(body))
    print
    print 'Response body <----'
    qc = getclient()
    obj_creater = getattr(qc, 'create_%s' % resource)
    ret = obj_creater(body)
    pprint(ret)

def format_network_params(params):
    return {'networks': [{'name': n} for n in params]}

def format_subnet_params(params):
    body = {'subnets': []}
    for param in params:
        subnet = {}
        items = param.split(',')
        if len(items) < 2:
            raise Exception('Too few subnet parameters %s '
                            '(net, cidr are reuqired)' % param)
        for i, v in enumerate(items[:2]):
            if '=' in v:
                continue
            if i == 0:
                subnet['network_id'] = v
            else:
                subnet['cidr'] = v
        for i in items:
            if '=' not in i:
                continue
            k, v = i.split('=', 1)
            subnet[k] = v
        print subnet
        if subnet.get('network_id'):
            subnet['network_id'] = q20.find_resourceid_by_name_or_id(
                getclient(), 'network', subnet['network_id'])
        else:
            raise Exception('network_id is not specified')
        if not subnet.get('cidr'):
            raise Exception('cidr is not specifed')
        if not subnet.get('ip_version'):
            subnet['ip_version'] = 4
        body['subnets'].append(subnet)
        print subnet
    print body
    return body

def format_port_params(params):
    pass

def parse_command(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--file', '-f', dest='jsonfile')
    parser.add_argument('command')
    parser.add_argument('param', nargs='*')
    return parser.parse_args(argv)

formatters = {'network': format_network_params,
             'subnet': format_subnet_params,
             'port': format_port_params}

def main():
    parsed_arg = parse_command(sys.argv[1:])
    if parsed_arg.command in formatters:
        bulk_create(parsed_arg.command, parsed_arg.param, parsed_arg.jsonfile)
    else:
        SystemExit('Unknown Command')

if __name__ == '__main__':
    main()
