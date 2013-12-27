# Copyright (c) 2013 NEC Corporation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# @author: Akihiro Motoki, NEC Corporation

import os
import tempfile

import fixtures

from neutron.common.test_lib import test_config


class TempConfigFile(fixtures.NestedTempfile):
    """Create a temporary config file with given configs.

    The format of the argument passed to the constructor is:

        {"<section1>": {"key1": "value1"},
         "<section2>": {"key2": "value2",
                        "key3": "value3"}}

    It generates a temporary config file as follows:

        [section1]
        key1 = value1
        [section2]
        key2 = value2
        key3 = value3

    """
    def __init__(self, configs):
        super(TempConfigFile, self).__init__()
        self.configs = configs

    def setUp(self):
        super(TempConfigFile, self).setUp()
        fd, self.cfg_file = tempfile.mkstemp()
        with os.fdopen(fd, 'w') as f:
            for group in self.configs:
                f.write('[%s]\n' % group)
                for key, value in self.configs[group].items():
                    f.write('%(key)s = %(value)s\n' %
                            {'key': key, 'value': value})
        if 'config_files' not in test_config:
            test_config['config_files'] = []
        self.addCleanup(self.clean_test_config)
        test_config['config_files'].append(self.cfg_file)

    def clean_test_config(self):
        if self.cfg_file in test_config['config_files']:
            test_config['config_files'].remove(self.cfg_file)
