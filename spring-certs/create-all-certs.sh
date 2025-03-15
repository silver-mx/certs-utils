#!/usr/bin/env bash

# Create a certificate authority (CA) and all certificates for the client and broker(s)
# Call it as "./create-all-certs.sh [commonName] [password] [outputDir] [encryptedCA(true/false)]"
# Example "./create-all-certs.sh devserver pass123 ./../../tls-certs false"

#WORKING_DIR=$(cd "$(dirname "$0")" && pwd)
COMMON_NAME=$(test "$1" && echo "$1" || echo "1")
PASSWORD=$(test "$2" && echo "$2" || echo "pass123")
OUTPUT_DIR=$(test "$3" && echo "$3" || echo "./../../tls-certs")
ENCRYPTED=$(test "$4" && echo "$4" || echo "false")
CA_DIR="$OUTPUT_DIR/ca"
CLIENT_SERVER_CFG="./client-server-cfg/config.cnf"

echo "COMMON_NAME=$COMMON_NAME"
echo "PASSWORD=$PASSWORD"
echo "OUTPUT_DIR=$OUTPUT_DIR"
echo "CA_DIR=$CA_DIR"
echo "CLIENT_SERVER_CFG=$CLIENT_SERVER_CFG"

test -e "$OUTPUT_DIR" || mkdir -p "$OUTPUT_DIR"

# Create certificate authority (CA) if it does not exist
CA_ENCRYPTION_PASSPHRASE=$(test "$ENCRYPTED" = "true" && echo "$PASSWORD" || echo "")
echo "CA_ENCRYPTION_PASSPHRASE=$CA_ENCRYPTION_PASSPHRASE"
test -e "$CA_DIR" || ./create-ca.sh "$CA_DIR" "$CA_ENCRYPTION_PASSPHRASE"

# Create keystore for the server
./create-keystore.sh "$COMMON_NAME" "$CLIENT_SERVER_CFG" "$CA_DIR" "$PASSWORD" "$OUTPUT_DIR"

# Create the truststore for the server
./create-truststore.sh "$COMMON_NAME" "$CA_DIR" "$PASSWORD" "$OUTPUT_DIR"
