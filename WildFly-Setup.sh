#!/bin/bash
set +e
WILDFLY_VERSION=18.0.0.Final
WILDFLY_FILENAME=wildfly-$WILDFLY_VERSION
WILDFLY_ARCHIVE_NAME=$WILDFLY_FILENAME.zip
WILDFLY_DOWNLOAD_ADDRESS=http://download.jboss.org/wildfly/$WILDFLY_VERSION/$WILDFLY_ARCHIVE_NAME

INSTALL_DIR=/opt/wildfly
WILDFLY_FULL_DIR=$INSTALL_DIR/$WILDFLY_FILENAME
WILDFLY_DIR=$INSTALL_DIR/wildfly
WILDFLY_HOME=/opt/wildfly/

WILDFLY_USER="wildfly"
WILDFLY_SERVICE="wildfly"
WILDFLY_MODE="standalone"

WILDFLY_STARTUP_TIMEOUT=240
WILDFLY_SHUTDOWN_TIMEOUT=30

#Setting up the Stage
yum install wget -y
yum install unzip -y
yum install vim -y
yum install java-11-openjdk-devel -y

#Shutting down if any existing WildFly is running
echo " Shutting down if any existing WildFly is running"
echo ""
echo ""

PID=`ps -eaf | grep wildfly | grep -v grep | awk '{print $2}'`
if [[ "" !=  "$PID" ]]; then
  echo "Shutting down existing WildFly with $PID"
$WILDFLY_HOME/wildfly/bin/jboss-cli.sh --connect command=:shutdown
fi

#Deleting wildfly user

#You Must be a root to go ahead

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

#Downloading the Wildfly
userdel wildfly

echo "Downloading: $WILDFLY_DOWNLOAD_ADDRESS..."
[ -e "$WILDFLY_ARCHIVE_NAME" ] && echo 'Wildfly archive already exists.'
if [ ! -e "$WILDFLY_ARCHIVE_NAME" ]; then
  wget --progress=bar  $WILDFLY_DOWNLOAD_ADDRESS
  if [ $? -ne 0 ]; then
    echo "Not possible to download Wildfly."
    exit 1
  fi
fi


echo "Cleaning up the old MESS..."
echo "######################################"
echo "######################################"
rm -f "$WILDFLY_DIR"
rm -rf "$WILDFLY_FULL_DIR"
rm -rf "/var/run/$WILDFLY_SERVICE/"
rm -f "/etc/init.d/$WILDFLY_SERVICE"

echo "    "
echo "    "
echo "    "
echo "Installatling the $WILDFLY_VERSION Stay AROUND..."
echo "######################################"
echo "######################################"

mkdir $WILDFLY_FULL_DIR
unzip -q  $WILDFLY_ARCHIVE_NAME -d $INSTALL_DIR
ln -s $WILDFLY_FULL_DIR/ $WILDFLY_DIR
useradd -s /sbin/nologin $WILDFLY_USER
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR
chown -R $WILDFLY_USER:$WILDFLY_USER $WILDFLY_DIR/

echo "Downloading the WAR file to the required Directory"
curl -o $WILDFLY_HOME/wildfly/standalone/deployments/SampleWebApp.war https://github.com/AKSarav/SampleWebApp/raw/master/dist/SampleWebApp.war


echo -e " Starting the WildFly in Standalone mode"

nohup $WILDFLY_HOME/wildfly/bin/standalone.sh -b 0.0.0.0 &

echo -e " Wildfly is firedup, to check whats goin on , do tail -f nohup.out"
