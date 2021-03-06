#!/bin/bash

. /vagrant/resources/provision-common.sh || exit 127

# do_install https://archive.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz
do_install https://sic.ctti.extranet.gencat.cat/nexus/content/groups/canigo-public-raw/archive.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz || die 1


log "Configurant Maven ..."

cd /opt/apache-maven-* || die 2

export MAVEN_HOME=$PWD
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

_RESOURCES=/vagrant/resources/maven

cp -vfr $_RESOURCES/settings.xml ./conf/

# su - canigo -c "$MAVEN_HOME/bin/mvn help:help clean:help war:help site:help deploy:help install:help compiler:help surefire:help failsafe:help eclipse:help"

cd $(mktemp -d) ; pwd
TEMPO_DIR=$PWD

cat<<EOF>$TEMPO_DIR/mvn-run.sh
export MAVEN_OPTS="-Djava.net.preferIPv4Stack=true -Dsun.net.client.defaultConnectTimeout=60000 -Dsun.net.client.defaultReadTimeout=30000"

cd $TEMPO_DIR;

$MAVEN_HOME/bin/mvn -B archetype:generate -DarchetypeGroupId=cat.gencat.ctti -DarchetypeArtifactId=plugin-canigo-archetype-rest -DarchetypeVersion=LATEST -DartifactId=AppCanigo -DgroupId=cat.gencat.ctti -Dversion=1.0

cd AppCanigo

$MAVEN_HOME/bin/mvn -B clean package failsafe:integration-test
$MAVEN_HOME/bin/mvn -B dependency:resolve -Dclassifier=sources
$MAVEN_HOME/bin/mvn -B dependency:resolve -Dclassifier=javadoc
EOF

chown -R canigo:canigo $TEMPO_DIR

su - canigo -c "bash $TEMPO_DIR/mvn-run.sh"
