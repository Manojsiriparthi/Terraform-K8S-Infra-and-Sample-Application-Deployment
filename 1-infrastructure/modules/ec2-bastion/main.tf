# ============================================================================
# EC2 BASTION MODULE - PRODUCTION GRADE SECURITY
# ============================================================================

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Security Group - Restricted SSH Access
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for bastion host - restricted SSH access"
  vpc_id      = var.vpc_id

  # SSH access from allowed CIDRs only (your office/home IP)
  ingress {
    description = "SSH access from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Allow all outbound traffic (bastion needs to reach EKS API and nodes)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion-sg"
    }
  )
}

# Use existing AWS key pair (created manually in AWS Console)
data "aws_key_pair" "bastion" {
  key_name = var.key_name
}

# Elastic IP for bastion (static IP for whitelisting)
resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = aws_instance.bastion.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion-eip"
    }
  )

  depends_on = [aws_instance.bastion]
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.bastion.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = var.iam_instance_profile_name

  # Enable IMDSv2 (prevents SSRF attacks)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Enable EBS encryption
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  # Install SSM agent for secure access without SSH
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              EOF

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-bastion"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami, user_data]
  }
}
