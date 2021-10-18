# Taken from https://raw.githubusercontent.com/openshift/jenkins/openshift-3.11/slave-base/Dockerfile

FROM quay.io/openshift/origin-cli:v3.11

MAINTAINER Frantisek Sumsal <frantisek@sumsal.cz>

ENV HOME=/home/jenkins

USER root
# Install headless Java
RUN yum install -y centos-release-scl-rh epel-release && \
    curl https://copr.fedorainfracloud.org/coprs/alsadi/dumb-init/repo/epel-7/alsadi-dumb-init-epel-7.repo -o /etc/yum.repos.d/alsadi-dumb-init-epel-7.repo && \
    #run yum update to avoid package version mismatch between i686 and other archs
    yum -y update && \
    x86_EXTRA_RPMS=$(if [ "$(uname -m)" == "x86_64" ]; then echo -n java-11-openjdk-headless.i686 ; fi) && \
    INSTALL_PKGS="bc gettext git java-11-openjdk-headless lsof rsync tar unzip which zip bzip2 dumb-init nss_wrapper" && \
    yum install -y --setopt=protected_multilib=false --setopt=tsflags=nodocs $INSTALL_PKGS $x86_EXTRA_RPMS && \
    # have temporarily removed the validation for java to work around known problem fixed in fedora; jupierce and gmontero are working with
    # the requisit folks to get that addressed ... will switch back to rpm -V $INSTALL_PKGS when that occurs
    rpm -V  $INSTALL_PKGS $x86_EXTRA_RPMS && \
    yum clean all && \
    mkdir -p /home/jenkins && \
    chown -R 1001:0 /home/jenkins && \
    chmod -R g+w /home/jenkins && \
    chmod -R 775 /etc/alternatives && \
    chmod -R 775 /var/lib/alternatives && \
    chmod -R 775 /usr/lib/jvm && \
    chmod 775 /usr/bin && \
    chmod 775 /usr/lib/jvm-exports && \
    chmod 775 /usr/share/man/man1 && \
    chmod 775 /var/lib/origin && \
    unlink /usr/bin/java && \
    unlink /usr/bin/jjs && \
    unlink /usr/bin/keytool && \
    unlink /usr/bin/pack200 && \
    unlink /usr/bin/rmid && \
    unlink /usr/bin/rmiregistry && \
    unlink /usr/bin/unpack200 && \
    unlink /usr/share/man/man1/java.1.gz && \
    unlink /usr/share/man/man1/jjs.1.gz && \
    unlink /usr/share/man/man1/keytool.1.gz && \
    unlink /usr/share/man/man1/pack200.1.gz && \
    unlink /usr/share/man/man1/rmid.1.gz && \
    unlink /usr/share/man/man1/rmiregistry.1.gz && \
    unlink /usr/share/man/man1/unpack200.1.gz

# Install additional tools/dependencies:
#   * python3 & cpp-coveralls for Coveralls coverage reports
#   * dnf,rsync, & patch for the utils/reposync.sh script
RUN yum install -y dnf dnf-plugins-core patch python-requests python3 rsync && \
    python3 -m pip install -U pip && \
    python3 -m pip install cpp-coveralls

# Copy the entrypoint
ADD contrib/bin/* /usr/local/bin/
# Copy Duffy-specific ssh client config
ADD contrib/config/duffy_ssh_config /etc/ssh/ssh_config

# Fix & drop privileges
RUN chown -R 1001:0 $HOME && chmod -R g+rw $HOME
USER 1001

# Run the Jenkins JNLP client
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/bin/run-jnlp-client"]
