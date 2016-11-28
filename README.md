# AUTOMATING ZERO DOWNTIME DEPLOYMENTS WITH MARATHON-LB
Revision 11-27-16

A utility for DC/OS'S marathon-lb north/south load balancer (mesosphere/marathon-lb & github.com/mesosphere/marathon-lb).

This is bash script (deploy-canary.sh) which takes two arguments; a container name (repo/name:label) and an app name (testapp). 
ex: ./deploy-canary.sh nginx testapp

The DC/OS enterprise cluster must have an account named bootstrapuser with a password of deleteme
Marathon-lb must already be installed, and modified to use the :latest container. 
The service account named dcos_marathon_lb must have a permission added of dcos:superuser=full

What it does:

A new app definition .json file is created (/tmp/new-app-definition.json) from a template file that is specific to the app (testapp.template.json) and the container name.
Three new DC/OS Job definitions will be created from the new app definiton, using a job template (deploy-canary-job.template.json):

/tmp/deploy-$APP_NAME-canary.json

/tmp/rollout-$APP_NAME-canary.json

/tmp/rollback-$APP_NAME-canary.json

Any jobs with these names that alredy exist are stopped and removed. 
Then the three jobs are added.

The deploy-app-template job is ready to be ran. It will create just one instance of the new container, and scale down by 1 the existing matching app of the blue green pair (per HAPROXY labels in the app definitions).

The canary instance is then tested.

If successful, the rollout-testapp-canary job would be ran. It will scale down the existing matching app one instance at a time, while the new canary version is scaled up one instance at a time.

However if the new canary instance was not successful, the rollback-testapp-canary job is utilized, which terminates the canary instance, removes the app definition from Services/Marathon, and scales up the existing app by one instance, returing it to its original instance count.

During each of the above scaling events, marathon-lb's zero downtime script (zdd.py) is utilized to achieve connection draining. It is documented at: https://github.com/mesosphere/marathon-lb#zero-downtime-deployments

The DC/OS Enterprise Edition CLI is used by this script,  the user must be logged in already when running deploy-canary.sh

This is a version 0.1 product.  

# TRY IT

To try it, clone this repo, login to your cluster, and ensure you don't have an app already named testapp.

Modify the testapp.template.json and change the HAPROXY_0_VHOST label to match your DNS. This lablel is used by marathon-lb to automatically configure itself and make the app available via load balancing. Also modify that same label in the testapp-nginx.json file, and optionally in the testapp-apache.json file. 

Then add the nginx test app with: dcos marathon app add testapp-nginx.json

Verify you can reach the app via curl or a browser.

Then generate the deployment jobs with a canary that uses the apache container:  ./deploy-canary httpd testapp

In the DC/OS GUI go to the Jobs screen and begin the job deploy-testapp-canary. The job is a large container, the initial download will take time. Alternatively, you can use the DC/OS cli to run the job via:  dcos job run deploy-testapp-canary 

If you cycle thru the browser or curl, or generate a load test, you should see 1 of 4 responses with the "It Works!" default page of apache. At this point you are in hybrid mode; both the old and new versions are running and traffic is split. 

Let us assume the test canary was successful. You would now run the rollout-testapp-canary job. 

However if the test canary instance was not successful, you would remove it by running the rollback-testapp-canary job.

