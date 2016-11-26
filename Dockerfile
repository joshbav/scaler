FROM mesosphere/marathon-lb:latest
RUN export TERM=xterm
RUN apt-get update \ 
&& apt-get install -y \
curl \
vim \
less \
nano \
jq \
iputils-ping \
net-tools \
traceroute \
netcat \
dnsutils \
tcpdump \
nmap \
python3 \
python3-pip \
atop \
p7zip \
txt2regex \
default-jre \ 
expect

# need to not use marathon-lb's entrypoint, not sure if it gets inherited or not, setting it just in case
ENTRYPOINT bash 

CMD pip3 install virtualenv


ADD setup-dcos-cli.sh /
CMD chmod u+x /setup-dcos-cli.sh
ADD dcos-cli-login-via-expect.sh /
CMD chmod u+x /dcos-cli-login-via-expect.sh

# add the dcos CLI files
ADD https://downloads.dcos.io/binaries/cli/linux/x86-64/0.4.14/dcos /usr/local/sbin/dcos
# Not sure why this command doesn't seem to run / stick
RUN chmod u+x /usr/local/sbin/dcos

# zdd.py requirements already satisfied since we're using marathon-lb container as the base for this container
#CMD pip3 install --upgrade pip
#CMD pip3 install -r requirements.txt

# add our sample app definitions
ADD testapp-v1-nginx.json / 
ADD testapp-v2-apache.json / 

# add scripts, hence the name of this container even if it's used for ZDD or other uses than auto scale
# Documentation https://docs.mesosphere.com/1.8/usage/tutorials/autoscaling/
ADD https://github.com/mesosphere/marathon-autoscale/blob/master/marathon-autoscale.py /
ADD https://github.com/mesosphere/marathon-autoscale/blob/master/marathon-servicediscovery.py /
ADD https://github.com/mesosphere/marathon-autoscale/blob/master/marathon_scale_test.py /
ADD https://github.com/mesosphere/marathon-autoscale/blob/master/sample-mesos-statistics.json /

# add signal wrapper, just in case we need it for the scale down, even though it wouldn't be deployed from this container, but we could extend this container to create an easy test this way. and what signal wrapper does is it prevents the propagation of signals for 10s for the first signal, that way a sigterm doesn't immediately kill the app, and our load blancer has time to take out out of the pool since it learns of the mesos kill signal being sent.
# https://github.com/sargun/signal-wrapper
ADD https://2-69824194-gh.circle-artifacts.com/0/tmp/circle-artifacts.AwoLkSz/signal-wrapper--linux-amd64 /signal-wrapper
CMD chmod u+x /signal-wrapper


