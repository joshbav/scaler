#!/bin/bash
# arguments

echo
echo "This script will launch a canary blue green deployment that will create a single instance of the new version."
echo "After that new canary instance has been tested, it will be necessary to either rollout the new version completey,"
echo "and therefore terminate the existing version's instances, OR to rollback by terminating the canary version." 
echo "To complete the rollout, run ROLLOUT-NAME, or to rollback run ROLLBACK-NAME"
echo
echo "You must be logged into your cluster with the DC/OS cli."
echo

# to do add description of inputs if there's not 3 provided

CONTAINER=$1
echo "Container provided:" "$CONTAINER"
echo

APP_NAME="$2"
echo "Name of DC/OS Marathon app (not a filename) to be upgraded:" $APP_NAME
echo

APP_TEMPLATE_FILE="$APP_NAME".template.json
echo "App template file to be used:" $APP_TEMPLATE_FILE 
echo "From this a new app will be created at /tmp/new-app-definition.json" 
echo

JOB_TEMPLATE_FILE=deploy-canary-job.template.json

echo DC/OS job template file to be used: $JOB_TEMPLATE_FILE 
echo "From this a new DC/OS job definition will be created at /tmp/deploy-$APP_NAME-canary.json"
echo

# STEP 1 ##### Put the container in the app template
# stream the app skeleton file thru sed, which will swap out a unique key with the container
# save it as /tmp/new-app-definition.json

echo Creating /tmp/new-app-definition.json
cat $APP_TEMPLATE_FILE | sed 's|ThisIsAUniqueKey|'$CONTAINER'|g' | jq -c . > /tmp/new-app-definition.json

# now read it in as an variable in base64 format (to avoid escaping problems), since that's easy for me to use with sed
NEW_APP_DEFINITION_AS_BASE64_JSON=$(cat /tmp/new-app-definition.json | jq -c -r @base64)

# STEP 2 ##### Put the app template into the job template
# stream the job template file thru sed, which will swap out a unique key with 
# the app template file, save it as /tmp/deploy-<app name>-canary.json 
# It will also create the rollout and rollback jobs from it, by modifying the deploy job that was created

echo "Creating /tmp/deploy-$APP_NAME-canary.json"
cat $JOB_TEMPLATE_FILE | sed 's|ThisIsAUniqueKey|'$NEW_APP_DEFINITION_AS_BASE64_JSON'|g' > /tmp/deploy-"$APP_NAME"-canary.json 

echo "Creating /tmp/rollout-$APP_NAME-canary.json"
cat /tmp/deploy-"$APP_NAME"-canary.json | sed 's|--new-instances 1|--complete-cur|g; s|deploy-|rollout-|g' > /tmp/rollout-$APP_NAME-canary.json

echo "Creating /tmp/rollback-$APP_NAME-canary.json"
cat /tmp/deploy-"$APP_NAME"-canary.json | sed 's|--new-instances 1|--rollback-cur|g; s|deploy-|rollback-|g' > /tmp/rollback-$APP_NAME-canary.json

echo "Using the DC/OS CLI, removing any existing DC/OS jobs for app $APP_NAME."
echo
dcos job kill deploy-$APP_NAME-canary
dcos job remove deploy-$APP_NAME-canary 

dcos job kill rollout-$APP_NAME-canary
dcos job remove rollout-$APP_NAME-canary

dcos job kill rollback-$APP_NAME-canary
dcos job remove rollback-$APP_NAME-canary

echo 
echo "Adding a new DC/OS job named deploy-$APP_NAME-canary from the temp file /tmp/deploy-"$APP_NAME"-canary.json" 
echo
# Note that a job will not be executed at the time it's added

dcos job add /tmp/deploy-$APP_NAME-canary.json
echo "DC/OS job deploy-$APP_NAME-canary added, it has not been started. This job will enable 1 instance of the new canary build."
echo

dcos job add /tmp/rollout-$APP_NAME-canary.json
echo "DC/OS job rollout-$APP_NAME-canary added, it has not been started. If the canary instance has passed testing, use this job to rollout the canary version and remove the old version."
echo

dcos job add /tmp/rollback-$APP_NAME-canary.json
echo "DC/OS job deploy-$APP_NAME-canary added, it has not been started. If the canary instance failed testing, use this job to rollback and remove the canary."
echo
echo "To see dcos jobs via the CLI, use: dcos job list"
echo
echo "To run one of the jobs from the CLI, such as  deploy-$APP_NAME-canary   use: dcos job run deploy-$APP_NAME-canary"
echo "Or just use the GUI, and go the Jobs screen. 
echo "Or use the API (https://dcos.github.io/metronome/docs/generated/api.html)"
echo
echo



