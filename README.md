# Headless Project Zomboid server

Terraform modules to provision a headless Project Zomboid server in AWS, with save game
backups to S3.

## Quick start

### Requirements

* [Terraform](https://www.terraform.io) version 0.12.x
* Amazon AWS account and [access keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys)
* SSH keypair for the EC2 instance

### Initial setup

* Put AWS credentials in `~/.aws/credentials` (`aws_access_key_id` and
  `aws_secret_access_key`)

* Configure and create stateful infrastructure:

      cd state/
      terraform init && terraform apply
      terraform output
      
      # Take note of bucket name in output
      bucket_name = zomboid20190602222917314000000001

* Configure stateless infrastructure:

      cd instance/
      terraform init
    
      # Add correct SSH keys and bucket_name from above
      vim terraform.tfvars

* Configure Zomboid server (see [Administrating a server
](https://pzwiki.net/wiki/Multiplayer_FAQ#Administrating_a_server)):

      vim conf/server.ini
      vim conf/server_SandboxVars.lua

### Game server

Create stateless infrastructure:

    cd instance/
    terraform apply
    terraform output
    
    # Public IP of the game server
    ip = 3.121.142.76

The game server is automatically started and the most recent save games from S3
are restored onto the instance.

Destroy infrastructure after use:

    cd instance/
    terraform destroy

This will automatically backup the save games to the specified S3 bucket.

## Details

* `state/` contains the Terraform module for the stateful server infrastructure.
  This includes the S3 bucket holding game state inbetween games, i.e. while the
  server instance does not exist.
* `instance/` contains the Terraform module for the stateless server
  infrastructure. This includes the EC2 instance that runs the game server.

### Services

Several systemd services are provisioned to the server instance:

* `zomboid-headless.service`: Service to start/stop the headless game server.
* `zomboid-restore.service`: One shot service that restores save games from S3.
* `zomboid-backup.service`: One shot service that backs up save games to S3.

You can use the `connect.sh` script to connect to the game server via SSH.
