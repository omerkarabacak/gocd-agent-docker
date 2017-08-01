FROM ubuntu:16.04

LABEL gocd.version="17.7.0" \
  gocd.full.version="17.7.0-5147" \
  gocd.git.sha="53fdb1b15184f93966059a42429bf9ed0bfdee59"

ADD "https://download.gocd.org/binaries/17.7.0-5147/generic/go-agent-17.7.0-5147.zip" /tmp/go-agent.zip
ADD https://github.com/krallin/tini/releases/download/v0.14.0/tini-static-amd64 /usr/local/sbin/tini
ADD https://github.com/tianon/gosu/releases/download/1.10/gosu-amd64 /usr/local/sbin/gosu

# allow mounting ssh keys, dotfiles, and the go server config and data
VOLUME /godata

# force encoding
ENV LANG=en_US.utf8

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  chmod 0755 /usr/local/sbin/gosu && \
  chown root:root /usr/local/sbin/gosu && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
  groupadd -g 1000 go && \ 
  useradd -u 1000 -g go -d /home/go -m go && \
  echo deb 'http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main' > /etc/apt/sources.list.d/openjdk-ppa.list && \ 
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DA1A4A13543B466853BAF164EB9B1D8886F44E2A && \ 
  apt-get update && \ 
  apt-get install -y curl software-properties-common ca-certificates apt-transport-https openjdk-8-jre-headless git subversion mercurial openssh-client bash unzip sudo && \ 
  apt-get autoclean && \
# unzip the zip file into /go-agent, after stripping the first path prefix
  unzip /tmp/go-agent.zip -d / && \
  mv go-agent-17.7.0 /go-agent && \
  rm /tmp/go-agent.zip

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
  apt-key fingerprint 0EBFCD88

RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN apt-get update && apt-get install docker-ce -y

RUN  usermod -a -G docker go
RUN  usermod -a -G root go
RUN  echo "go ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ADD docker-entrypoint.sh /

RUN ["chmod", "+x", "/docker-entrypoint.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]
