#!/bin/bash

set -e

BASE_URL="https://191.252.111.124/files/siga/"

RESOURCES=(
    "ckeditor_4.5.7_full.zip"
)

SHA_256_SUN=(
    "323b535003a2b69e5faa306cdb3744cb6879ae402512b0ee8d260a2cb87fc30c"
)

echo "Downloading resources..."
for i in "${!RESOURCES[@]}"; do
    resource=${RESOURCES[$i]}
    file="$(cut -d' ' -f2 <<<"$resource")"

    attempts=0
    pwd
    ls -la
    while [  $attempts -lt 2 ]; do
        echo "Downloading $file:"
        curl --connect-timeout 10 -k --progress-bar $BASE_URL$file -o $file 2>&1

        echo -n "Health check for $file: "
        hash="$(sha256sum $file | cut -d ' ' -f 1)"
        if [ $hash = ${SHA_256_SUN[$i]} ]
        then
            echo "SUCCESS"
            attempts=0
            break
        fi
        ((attempts++))
        echo "FAIL"
        echo "Trying to download again..."
    done
done

add-user.sh admin Password@123

jboss-cli.sh <<EOF
embed-server --std-out=echo
batch

module add --name=com.mysql --resources=siga/tmp/mysql-connector-java-8.0.24.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)
/subsystem=security/security-domain=sp/:add(cache-type=default)
/subsystem=security/security-domain=sp/authentication=classic:add(login-modules=[{code=org.picketlink.identity.federation.bindings.jboss.auth.SAML2LoginModule, flag=>required}])

run-batch
stop-embedded-server
exit
EOF

unzip -q ckeditor_4.5.7_full.zip -d ${JBOSS_HOME}/welcome-content/ckeditor/

rm -r "$HOME/siga/tmp"
mkdir -p "$HOME/siga/tmp"