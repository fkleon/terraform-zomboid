# Zomboid server instance
instance_type = "c5.large"

admin_password = "YOUR_PASSWORD"

# AWS SSH keypair. Sorry, RSA only.
# The public key part is used to create the server instance.
ssh_public_key = "ssh-rsa PUBLICKEY"
# The private key part is used to provision the instance.
ssh_private_key = <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
PRIVATEKEY
-----END OPENSSH PRIVATE KEY-----
EOF
