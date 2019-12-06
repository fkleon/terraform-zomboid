# Headless Project Zomboid server

Terraform modules to provision a headless Project Zomboid server in AWS.

## Quick start

### Requirements

* [Terraform](https://www.terraform.io) version 0.12.x
* Amazon AWS account and [access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)
* SSH keypair for the EC2 instance

### Initial setup

* Put AWS credentials in `~/.aws/credentials` (`aws_access_key_id` and
  `aws_secret_access_key`)

* Configure stateless infrastructure:

      cd instance/
      terraform init
    
      # Add correct SSH keys from above
      vim terraform.tfvars

* Configure Zomboid server:

      vim conf/server.ini

### Game server

Create stateless infrastructure:

    cd instance/
    terraform apply
    terraform output
    
    # Public IP of the game server
    ip = 3.121.142.76

The game server is automatically started.

Destroy infrastructure after use:

    cd instance/
    terraform destroy


## Details

* `instance/` contains the Terraform module for the stateless server
  infrastructure. This includes the EC2 instance that runs the game server.

### Services

Several systemd services are provisioned to the server instance:

* `zomboid-headless.service`: Service to start/stop the headless game server.

You can use the `connect.sh` script to connect to the game server via SSH.

### Limitations

No save game backup/restore.
