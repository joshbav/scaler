#!/bin/bash
#for some reason chmod didnt work in the dockerfile, think it's a docker bug, so doing it in this script
chmod u+x /usr/local/sbin/dcos
dcos config set core.dcos_url http://master.mesos

#launch the auto login, using CCM default credentials
/usr/bin/expect /dcos-cli-login-via-expect.sh
:
#load up many possible cli modules, even if we won't use them
dcos package install --yes --cli dcos-enterprise-cli &&
dcos package install --yes --cli spark &&
dcos package install --yes --cli cassandra &&
dcos package install --yes --cli confluent-kafka &&
dcos package install --yes --cli kafka
