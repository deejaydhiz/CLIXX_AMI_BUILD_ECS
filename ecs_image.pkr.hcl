variable "aws_source_ami" {
  default = "al2023-ami-ecs-hvm-2023.0.20251217-kernel-6.1-x86_64"
}

variable "aws_instance_type" {
  default = "t3.micro"
}

variable "ami_name" {
  default = "stack14-ecs_ami"
}

variable "component" {
  default = "clixx"
}

variable "aws_accounts" {
  type = list(string)
  default = ["186769093804", "055081916963"]
}

variable "ami_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "aws_region" {
  default = "us-east-1"
}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

data "amazon-ami" "source_ami" {
  filters = {
    name = "${var.aws_source_ami}"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = "${var.aws_region}"
}




# locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }


# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioners and post-processors on a
# source.


source "amazon-ebs" "amazon_ebs" {
  assume_role {
    role_arn     = "arn:aws:iam::186769093804:role/Engineer"
  }
  ami_name       = "${var.ami_name}"
  ami_regions    = "${var.ami_regions}"
  ami_users      = "${var.aws_accounts}"
  snapshot_users = "${var.aws_accounts}"
  encrypt_boot   = false
  instance_type  = "${var.aws_instance_type}"
  
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = false
    volume_size           = 30
    volume_type           = "gp3"
  }
  region                = "${var.aws_region}"
  source_ami            = "${data.amazon-ami.source_ami.id}"
  ssh_pty               = true
  ssh_timeout           = "5m"
  ssh_username          = "ec2-user"
  force_deregister      = true
  force_delete_snapshot = true
}


# a build block invokes sources and runs provisioning steps on them.
build {
  sources = ["source.amazon-ebs.amazon_ebs"]
  provisioner "shell" {
    script = "./setup.sh"
  }
}
