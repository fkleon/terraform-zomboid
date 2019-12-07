terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = var.region
  version = "~> 2.13"
}

provider "template" {
  version = "~> 2.1"
}

locals {
  server_name = "pzserver"
  save_game_dir = "/home/steam/Zomboid"
  rcon_cli_version = "1.4.7"
  # Should match the value in server.ini
  rcon_password = "rcon"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-eoan-19.10-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "cloud_config" {
  template = file("./cloud-config.yml")
  vars = {
    rcon_cli_version = local.rcon_cli_version
    zomboid_app_id  = var.zomboid_app_id
  }
}

resource "aws_key_pair" "key" {
  key_name   = var.name
  public_key = var.ssh_public_key
}

resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "instance" {
  vpc_id = aws_default_vpc.default.id
  name   = "${var.name}-security-group"
  tags   = var.tags

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Steam
  ingress {
    protocol    = "udp"
    from_port   = 8766
    to_port     = 8767
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8766
    to_port     = 8767
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Zomboid server
  ingress {
    protocol    = "udp"
    from_port   = 16261
    to_port     = 16261
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 16262
    to_port     = 16272
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "zomboid" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone
  associate_public_ip_address = true
  tags                        = var.tags

  root_block_device {
    volume_size           = 8
    volume_type           = "gp2"
    delete_on_termination = true
  }

  iam_instance_profile = var.instance_profile

  key_name        = aws_key_pair.key.key_name
  user_data       = data.template_file.cloud_config.rendered
  security_groups = [aws_security_group.instance.name]

  provisioner "file" {
    source      = "conf"
    destination = "/tmp"
  }

  provisioner "file" {
    content     = <<ENV
# Server settings
SERVER_NAME=${local.server_name}
ADMIN_PASSWORD=${var.admin_password}
RCON_PASSWORD=${local.rcon_password}
# Backup settings
S3_BUCKET=${var.bucket_name}
SAVE_GAME_DIR=${local.save_game_dir}
ENV
    destination = "/tmp/zomboid-environment"
  }

  # Initialise Zomboid server settings, install systemd units.
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo cloud-init status --wait > /dev/null 2>&1",
      "sudo install -m 644 -o root -g root /tmp/zomboid-environment -D /etc/zomboid/environment",
      "sudo install -m 644 -o root -g root /tmp/conf/zomboid-headless.service /etc/systemd/system",
      "sudo install -m 644 -o root -g root /tmp/conf/zomboid-backup.service /etc/systemd/system",
      "sudo install -m 644 -o root -g root /tmp/conf/zomboid-restore.service /etc/systemd/system",
      "sudo install -m 644 -o steam -g steam /tmp/conf/server.ini -D /home/steam/Zomboid/Server/${local.server_name}.ini",
      "sudo systemctl daemon-reload",
    ]
  }

  # Restore save games from S3 and start headless server.
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo cloud-init status --wait > /dev/null 2>&1",
      "sudo systemctl start zomboid-restore.service && sudo systemctl start zomboid-headless.service",
    ]
  }

  # Stop headless server and backup save games to S3 on destroy.
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo systemctl stop zomboid-headless.service",
      "sudo systemctl start zomboid-backup.service",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.ssh_private_key
  }
}
