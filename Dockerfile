
#
# Setup Stage: install apps
#
# This is a dedicated stage so that donwload archives don't end up on
# production image and consume unnecessary space.
#

FROM opensuse/tumbleweed as setup

ARG IB_GATEWAY_VERSION=10.25.1k
ARG IB_GATEWAY_RELEASE_CHANNEL=latest
ARG IBC_VERSION=3.17.0
ENV IB_GATEWAY_VERSION=${IB_GATEWAY_VERSION} IB_GATEWAY_RELEASE_CHANNEL=${IB_GATEWAY_RELEASE_CHANNEL} IBC_VERSION=${IBC_VERSION}

# It's necessary to have openjfx installed for IB
RUN zypper install -y unzip gzip tar java-1_8_0-openjdk java-1_8_0-openjfx
# Enable openjfx module
RUN cd /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/jre/lib/ext/ && ln -s /usr/lib64/jvm/openjfx8/rt/lib/ext/jfxrt.jar jfxrt.jar

WORKDIR /tmp/setup

# Install IB Gateway
# Use this instead of "RUN curl .." to install a local file:
RUN curl -sSL https://download2.interactivebrokers.com/installers/ibgateway/${IB_GATEWAY_RELEASE_CHANNEL}-standalone/ibgateway-${IB_GATEWAY_RELEASE_CHANNEL}-standalone-linux-x64.sh --output ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh
# Fixing Java version so that it could be ARM and AMD
RUN export JAVA_PATCH=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | sed 's/^1\.//' | cut -d'_' -f2) && \
  sed -i "s/\"202\"/\"$JAVA_PATCH\"/g" ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh && \
  sed -i 's~\(# INSTALL4J_JAVA_HOME_OVERRIDE\).*~INSTALL4J_JAVA_HOME_OVERRIDE=/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/jre~g' ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh
RUN chmod a+x ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh
RUN ./ibgateway-${IB_GATEWAY_VERSION}-standalone-linux-x64.sh -q -dir /root/Jts/ibgateway/${IB_GATEWAY_VERSION}
COPY ./config/ibgateway/jts.ini /root/Jts/jts.ini

# Install IBC
RUN curl -sSL https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip --output IBCLinux-${IBC_VERSION}.zip
RUN mkdir /root/ibc
RUN unzip ./IBCLinux-${IBC_VERSION}.zip -d /root/ibc
RUN chmod -R u+x /root/ibc/*.sh
RUN chmod -R u+x /root/ibc/scripts/*.sh
COPY ./config/ibc/config.ini.tmpl /root/ibc/config.ini.tmpl

# Copy scripts
COPY ./scripts /root/scripts

RUN rm -rf /usr/lib64/ld-linux-x86-64.so.2

# #
# # Build Stage: build production image
# #

FROM ubuntu:23.10

ARG IB_GATEWAY_VERSION=10.25.1k
ENV IB_GATEWAY_VERSION=${IB_GATEWAY_VERSION}

WORKDIR /root

# Prepare system
RUN apt-get update -y
RUN apt-get install --no-install-recommends --yes \
  ca-certificates   \
  gettext   \
  xvfb   \
  libxslt-dev   \
  libxrender1   \
  libxtst6   \
  libxi6   \
  libgtk2.0-bin   \
  socat   \
  x11vnc

# Copy files
COPY --from=setup /root/ .
RUN chmod a+x /root/scripts/*.sh
RUN mkdir -p /usr/lib64
COPY --from=setup /usr/lib64/ /usr/lib64
COPY --from=setup /var/lib/ca-certificates /var/lib/ca-certificates

# IBC env vars
ENV TWS_MAJOR_VRSN ${IB_GATEWAY_VERSION}
ENV TWS_PATH /root/Jts
ENV IBC_PATH /root/ibc
ENV IBC_INI /root/ibc/config.ini
ENV TWOFA_TIMEOUT_ACTION exit

# Start run script
CMD ["/root/scripts/run.sh"]
