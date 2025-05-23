#!/usr/bin/env bash

# This script will generate one or more keystores.
# The script is adapted from https://github.com/confluentinc/learn-kafka-courses/blob/main/fund-kafka-security/scripts/keystore-create-kafka-2-3.sh
# Call it as "./create-keystore.sh [commonName] [cfgFilePath] [caDir] [password] [outputDir]"
# Example "./create-keystore.sh devserver ./client-server-cfg/config.cnf ./../../tls-certs/ca pass123 ./../../tls-certs"

#WORKING_DIR=$(cd "$(dirname "$0")" && pwd)
NAME=$1
CFG_PATH=$2
CA_DIR=$3
PASSWORD=$4
OUTPUT_DIR=$5

KEYSTORE_DIR="$OUTPUT_DIR/$NAME"
KEYSTORE="$KEYSTORE_DIR/keystore-$NAME.pkcs12"

# Create the folder if it does not exists
test -e "$KEYSTORE_DIR" || mkdir -p "$KEYSTORE_DIR"

# Generate and copy broker.cnf file
cp "$CFG_PATH" "$KEYSTORE_DIR"
CFG_FILE="$KEYSTORE_DIR/$(basename "$CFG_PATH")"
sed -i -e "s\@PLACEHOLDER\\$NAME\g" "$CFG_FILE"
mv "$CFG_FILE" "$KEYSTORE_DIR/$NAME.cnf"

echo "------------------------------- START GENERATING KEYSTORE $NAME [$KEYSTORE] -------------------------------"

  # Create server key & certificate signing request(.csr file)
  # NOTE: No password is asked because of '-noenc'
  openssl req -new \
  -newkey rsa:4096 \
  -days 3650 \
  -sha512 \
  -noenc \
  -keyout "$KEYSTORE_DIR/$NAME.key" \
  -out "$KEYSTORE_DIR/$NAME.csr" \
  -config "$KEYSTORE_DIR/$NAME.cnf"

  # Sign the server certificate with the CA
  # NOTE: -passin pass:"$PASSWORD" provides the CA encryption password (if the CA is encrypted)
  openssl x509 -req \
  -sha512 \
  -days 3650 \
  -in "$KEYSTORE_DIR/$NAME.csr" \
  -CA "$CA_DIR/ca.crt" \
  -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial \
  -out "$KEYSTORE_DIR/$NAME.crt" \
  -extfile "$KEYSTORE_DIR/$NAME.cnf" \
  -extensions v3_req \
  -passin pass:"$PASSWORD"

  # Convert the server certificate over to pkcs12 format
  openssl pkcs12 -export \
  -in "$KEYSTORE_DIR/$NAME.crt" \
  -inkey "$KEYSTORE_DIR/$NAME.key" \
  -chain \
  -CAfile "$CA_DIR/ca.pem" \
  -name "$NAME" \
  -out "$KEYSTORE_DIR/$NAME.p12" \
  -password pass:"$PASSWORD" \
  -passin pass:"$PASSWORD"

  # Create a keystore for the server and import the certificate
  keytool -importkeystore \
  -alias "$NAME" \
  -deststorepass "$PASSWORD" \
  -destkeystore "$KEYSTORE" \
  -srckeystore "$KEYSTORE_DIR/$NAME.p12" \
  -deststoretype PKCS12  \
  -srcstoretype PKCS12 \
  -noprompt \
  -srcstorepass "$PASSWORD"

  test "$?" -eq 0  && echo "KEYSTORE CREATED SUCCESSFULLY..." || echo "THE KEYSTORE COULD NOT BE CREATED..."

  # Save creds
  echo "$PASSWORD" > "$KEYSTORE_DIR/sslkey-creds-$NAME"
  echo "$PASSWORD" > "$KEYSTORE_DIR/keystore-creds-$NAME"

  echo "------------------------------- END GENERATING KEYSTORE $NAME [$KEYSTORE] -------------------------------"

  echo "------------------------------- START VERIFICATION KEYSTORE [$KEYSTORE] -------------------------------"

  # Verify the keystore
  keytool -list -v \
      -keystore "$KEYSTORE" \
      -storepass "$PASSWORD" > /dev/null

  test "$?" -eq 0  && echo "VERIFICATION OK..." || echo "VERIFICATION FAILED..." ; exit 1

  echo "------------------------------- END VERIFICATION KEYSTORE [$KEYSTORE] -------------------------------"
