# creates a new CCM test cluster, expects url (w or w/o HTTPS) to a DC/OS master

bash ~/dcosnew.sh $1

# get marathon-lb
bash ~/mlb-setup.sh

#installs at 0 instances
dcos marathon app add scaler.json

#load up the blue test app
dcos marathon app add testapp-v1-nginx.json

#install jenkins with /var/jenkins as only config change
dcos marathon app add jenkins.json
