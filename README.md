# certs-utils
Utilities to generate certificates

### Kafka Certificates

Creates a certificate authority (CA) and all certificates for the client and broker(s).
Call it as `./create-all-certs.sh [numBrokers] [password] [outputDir] [encryptedCA(true/false)]`

```bash
cd kafka-certs

./create-all-certs.sh 1 pass123 ./../output/kafka-tls-certs false
```

### Java-Spring HTTPS/TLS

Creates a certificate authority (CA) and the keystore for the server.
Call it as `./create-all-certs.sh [commonName/alias] [password] [outputDir] [encryptedCA(true/false)]`

```bash
cd spring-certs

./create-all-certs.sh devserver pass123 ./../output/spring-tls-certs false
```
