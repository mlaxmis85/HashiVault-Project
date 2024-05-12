#!/bin/bash
# Install Vault (adjust the download URL as needed)
VAULT_VERSION="1.8.4"
wget "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip "vault_${VAULT_VERSION}_linux_amd64.zip"
chmod +x vault
mv vault /usr/local/bin/

# Create directories for data and configuration
mkdir -p /opt/vault/data
mkdir -p /etc/vault

# Create Vault configuration file (vault.hcl)
cat <<EOF > /etc/vault/vault.hcl
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/opt/vault/data"
}
EOF

# Start Vault servers
./vault server -config=/etc/vault/vault.hcl &

# Initialize and unseal the first Vault node
export VAULT_ADDR="http://127.0.0.1:8200"
./vault operator init
# Note down the unseal keys and the initial root token

# Unseal the first Vault node (use your unseal keys)
./vault operator unseal <unseal_key_1>
./vault operator unseal <unseal_key_2>
./vault operator unseal <unseal_key_3>

# Start the second and third Vault nodes
./vault server -config=/etc/vault/vault.hcl -dev &
./vault server -config=/etc/vault/vault.hcl -dev &

# Join the second and third nodes to the cluster
export VAULT_ADDR="http://127.0.0.1:8201"  # Address of the second node
./vault operator raft join http://127.0.0.1:8200
export VAULT_ADDR="http://127.0.0.1:8202"  # Address of the third node
./vault operator raft join http://127.0.0.1:8200

# Verify the cluster status
./vault status
