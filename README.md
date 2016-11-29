# AUTOMATING ZERO DOWNTIME DEPLOYMENTS WITH MARATHON-LB
Revision 11-27-16

A utility for DC/OS'S marathon-lb north/south load balancer (mesosphere/marathon-lb & github.com/mesosphere/marathon-lb).

This is bash script (deploy-canary.sh) which takes two arguments; a container name (repo/name:label) and an app name (testapp). 
ex: ./deploy-canary.sh nginx testapp

[Here is a video of its use](https://mesosphere-mc.webex.com/mesosphere-mc/ldr.php?RCID=a8bbc9120c09544543719d2416c28a2c) following the directions below.

REQUIREMENTS 

These requirements are temporary and will change.

1. The DC/OS enterprise cluster must have an account named bootstrapuser with a password of deleteme.

2. Marathon-lb must already be installed, and modified to use the :latest container.

3. The service account named dcos_marathon_lb must have a permission added of dcos:superuser=full, this is best done by inserting the permission string (upper right corner of window).

WHAT IT DOES

A new app definition file is created (/tmp/new-app-definition.json) from a template file that is specific to the app (testapp.template.json) and the provided container name.
Three new DC/OS Job definitions will be created from the new app definition, using a job template (deploy-canary-job.template.json):

/tmp/deploy-appname-canary.json

/tmp/rollout-appname-canary.json

/tmp/rollback-appname-canary.json

Any jobs with these names that already exist are stopped and removed. 
Then the three jobs are added.

The deploy-appname-template job is ready to be ran. It will create just one instance of the new container, and scale down by 1 the existing matching app of the blue green pair.

The canary instance is then tested.

If successful, the rollout-appname-canary job would be ran. It will scale down the existing matching app one instance at a time, while the new canary version is scaled up one instance at a time.

However, if the new canary instance was not successful, the rollback-appname-canary job is utilized, which terminates the canary instance, removes the app definition from DC/OS Services (aka Marathon), and scales up the existing app by one instance, returning it to its original instance count.

During each of the above scaling events, marathon-lb's zero downtime script (zdd.py) is utilized to achieve connection draining. It is documented at: https://github.com/mesosphere/marathon-lb#zero-downtime-deployments

The DC/OS Enterprise Edition CLI is used by this script, you must be logged in already when running deploy-canary.sh

This is the first version of this script.  

# TRY IT OUT

1. Ensure the requirements above are met.

2. Clone this repo, login to your DC/OS Enterprise Edition cluster, and ensure you don't have an app already named testapp. 

3. Modify the testapp.template.json file and change the HAPROXY_0_VHOST label to match the DNS entry for this app, this label is how marathon-lb knows what app is associated to what DNS FQDN, from this marathon-lb automatically configures itself to make the app available via load balancing. Note this template uses the NGINX web server container. 

4. Let's assume the new canary version will differ from the existing version because it's a different container. So generate the new deployment canary and its associated DC/OS jobs that use an Apache web server container instead, using this command:  bash deploy-canary.sh httpd testapp

5. In the DC/OS GUI go to the Jobs screen and begin the job deploy-testapp-canary. Alternatively, you can use the DC/OS CLI to run the job via:  dcos job run deploy-testapp-canary  or you could use the API. This will add -blue to the app name, when the job completes an app named testapp-blue will be visible in the Services screen. 

6. Test that you can reach the app using your browser, curl, etc.    

7. Since this script is focused on rolling out new versions of apps, we need to first have a version already running. This only needs to be done once, because from then on all operations are rollouts/rollbacks of new versions. The previous step accomplished the need to get an initial app running. Now that we have an existing version of the app runninng, we will generate the next version that uses nginx instead of apache, and we'll deploy a single canary instance of it. So rerun the deploy-canary script but this time with nginx: ./deploy-canary nginx testapp

8. In the DC/OS GUI go to the Jobs screen and begin the job deploy-testapp-canary. This will deploy one instance of the nginx version and name it testapp-green.

9. If you cycle thru the browser or curl, or generate a load test, you should see 1 of 4 responses with the "Welcome to NGINX" default page, and 3 of 4 responses with the "It works!" default apache page.  At this point you are in a hybrid deployment mode; both the old and new versions are running and traffic is split. 

10a. Let us assume the test canary was successful. You would now run the rollout-testapp-canary job. 

10b. However, if the test canary instance was not successful, you would remove it by running the rollback-testapp-canary job.

