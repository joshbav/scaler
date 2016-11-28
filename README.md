# AUTOMATING ZERO DOWNTIME DEPLOYMENTS
This is bash script (deploy-canary.sh) which takes two arguments; a container name (repo/name:label) and an app name (testapp). 
ex: ./deploy-canary.sh nginx testapp

A new app definition .json file is created (/tmp/new-app-definition.json) from a template file that is specific to the app (testapp.template.json) and the container name.
Three new DC/OS Job definitions will be created from the new app definiton, using a job template (deploy-canary-job.template.json):
/tmp/deploy-$APP_NAME-canary.json
/tmp/rollout-$APP_NAME-canary.json
/tmp/rollback-$APP_NAME-canary.json

Any jobs with these names that alredy exist are stopped and removed. 
Then the three jobs are added.

At this point the deploy-app-template job is ran, and one instance of the new container will be deployed, and the instance count is scaled down by 1 for the existing matching app of the blue green pair (per HAPROXY labels).

Then the new canary instance is tested.

Then if successful, the rollout-app-canary job is ran, and the existing matching app is scaled down by one, while the new canary version is scaled up, all the while the while marathon-lb's (github: mesosphere/marathon-lb) zero downtime script (zdd.py) is utilized to achieve connection draining. 

However if the new canary instance was not successful, the rollback-app-canary job is utilized, which terminates the canary instance, removes the app definition from Services/Marathon, and scales up the existing app by one instance, returing it to its original instance count.

The DC/OS Enterprise Edition CLI is used for this, and the user must be logged in already when running deploy-canary.sh

This is a version 0.1 product.  


