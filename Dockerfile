FROM quay.io/openshift/origin-jenkins-agent-base:latest

MAINTAINER Frantisek Sumsal <frantisek@sumsal.cz>

# "Convert" the image to CentOS Stream 8
# See: https://github.com/CentOS/sig-cloud-instance-images/blob/CentOS-8-Stream/docker/Dockerfile
RUN rm -f /etc/yum.repos.d/*.repo
RUN dnf download --repofrompath=centos,http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/ --disablerepo=* --enablerepo=centos centos-stream-release centos-stream-repos centos-gpg-keys
RUN rpm -ivh --nodeps --replacefiles *.rpm && rm *.rpm \
    && rpm -e redhat-release \
    && dnf --setopt=tsflags=nodocs --setopt=install_weak_deps=false -y distro-sync \
    && dnf remove -y subscription-manager dnf-plugin-subscription-manager\
    && dnf install -y glibc-langpack-en \
    && dnf clean all

# FIXME: debug only
RUN dnf -y install python2 python2-requests

# Copy Duffy-specific ssh client config
ADD contrib/config/duffy_ssh_config /etc/ssh/ssh_config

# Fix & drop privileges
RUN chown -R 1001:0 $HOME && chmod -R g+rw $HOME
USER 1001

# Run the Jenkins JNLP client (taken from the base image)
ENTRYPOINT ["/usr/bin/go-init","-main","/usr/local/bin/run-jnlp-client"]
