There are 2 QA clusters:
  - k8s-masterk on aws, mostly master branch
  - k8s-branchz on azure, mostly branches.
  - about 10-25 envs on each (that's the count of values files)
  - there is some readme QA keeps which has details on which env
    is used for what
  - 2 directories:
    - infrastructure has terraform which creates the cluster
    - deploys/ contains the k8s config and helm charts we
      run on the cluster

Deployments are made via helm charts.
The helm chart captures many of the options (feature flags)
  which must be turned on/off when deploying YMS.
(see a helm values file)
Example: https://github.com/pincsolutions/k8s-masterk/blob/main/deploys/yms-abs-mel/values-abs-mel.yml

Some QA folks use command line.
Others use a helm-dashboard.
Main idea is: make some change to existing values file, and deploy.
(sometimes have to change the changeme field)

When we deploy, dozens of things are deployed:
  - web pods
  - background processing jobs
  - various daemons to run specific features
  - rtls system

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


when can we tear down the envs?

# creating the envs
need a cli. answer a set of questions and wait.


cli process questions:
  - what branch you need to test
    - example: YMS-1234_switcher_teams
  - what database flavor do you need?
    - choice of the flavor
  - what is your ams username?
    (because we need to add permissions for user to the site)


poc
  - cli from a secure host
  - choice of 2 databases
  - needs to creates env
  - needs to provision permissions
  - needs to tear down env


## scope

do we test integrations projects?
do we generate the sqs/sns infrastructure?
do we have to create sample ib/ob shipments?


What do we want to create?
How do we translate this into k8s/helm deploy.
How to generate data for the use-case?
How to add permissions for user to the site
How to tear these things down?
  

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
This is how we get a new YMS on xxx-yyy-masterk.pincsolutions.com for
  user alice
Services are the same
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

The script gathers the N items given by the user.
(ie:
Which DB template do you want to use?
  1 - nke-el1
  2 - kft-dov
  3 - rdl-ato
  4 - abs-por
  5 - jwo-mel
  6 - frd-oha
)


We can use the postgres template DB feature so we can get a really fast copy of
a database ready.
  - for this we would use existing DB server, not new server.
We need to generate a new 6-letter campus code.
May may need to create random corporations
We need to update that database with:
  - the campus code used in the sites table
We need to provision AMS and tell it about the new campus
We need to give alice the permissions to use site xxx-yyy
  - what type of user are they? (sys-admin, guest, etc)
We need to update the k8s ingress with entries for this new site.
  - need to investigate k8s ingress possibilities
We need to update DNS and and entries for the new site.
  - do we want a new domain to not interfere with pincsolutions.com?
We generate a valid helm values file
  - use defaults as much as possible
  - asset_mover/journeys/message_dispacher on/off?
We deploy the helm values file
  - need kubectl access for this
We give the user the url where the new YMS is deployed
  (generated-campus-code-masterk.pincsolutions.com)
We need to stream logs to some place like OpenSearch.
  - can we update fluentbit.yaml and reload it?
What kind of data would we need to generate for xxx-yyy in terms of
  - shipments
    base set, could just 20 inbound/outbound

How do we kill this environment?
  - helm uninstall
  - remove the entries in AMS for xxx-yyy
  - generated shipment data
  - clean up any DNS
  - clean up ingress
  - clean fluentbit file, and logs from openseach



TBD:
  - Do we always checkin the new values file, and delete it when we're done?
  - No terraform here, so no SQS/SNS. No testing sqs-to-yms integration. that ok?

#######################################################################

June2 2025:

configurator pods:
  kubectl exec -it yms-frd-oha-ruby-configurator-545bbfd557-cnxh7 -- bash

template dbs:
See here for template DBs: https://www.postgresql.org/docs/current/manage-ag-templatedbs.html

Daniel to send TTY scripts to team as a starting point.


#######################################################################
How would we create an env where the services were also generated for each new
environment?
#######################################################################

DUNNO
