provider "aws" {
  region = "us-east-1"
}

variable "allowed_ips_for_master" {
  description = "List of IPs allowed to access API server on master node"
  type        = list(string)
  default     = ["197.162.8.64/32"]
}

# ---------------------------
# Security Groups
# ---------------------------

# Master Node SG
resource "aws_security_group" "master_sg" {
  name        = "k8s-master-sg"
  description = "Security group for Kubernetes master node"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K8s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips_for_master
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Worker Node SG
resource "aws_security_group" "worker_sg" {
  name        = "k8s-worker-sg"
  description = "Security group for Kubernetes worker node"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer SG
resource "aws_security_group" "lb_sg" {
  name        = "nginx-lb-sg"
  description = "Security group for Nginx load balancer"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# Cross-SG Rules (Separate to avoid loops)
# ---------------------------

# Worker -> Master (all traffic)
resource "aws_security_group_rule" "worker_to_master" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.master_sg.id
  source_security_group_id = aws_security_group.worker_sg.id
}

# Master -> Worker (all traffic)
resource "aws_security_group_rule" "master_to_worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.master_sg.id
}

resource "aws_security_group_rule" "lb_to_worker_nodeports" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.lb_sg.id

  depends_on = [
    aws_security_group.worker_sg,
    aws_security_group.lb_sg
  ]
}


# ---------------------------
# EC2 Instances
# ---------------------------

resource "aws_instance" "master_node" {
  ami                    = "ami-08c40ec9ead489470"
  instance_type          = "t3.medium"
  key_name               = "my-keypair"
  vpc_security_group_ids = [aws_security_group.master_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-master-node"
  }
}

resource "aws_instance" "worker_node" {
  ami                    = "ami-08c40ec9ead489470"
  instance_type          = "t3.medium"
  key_name               = "my-keypair"
  vpc_security_group_ids = [aws_security_group.worker_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-worker-node"
  }
}

resource "aws_instance" "nginx_lb" {
  ami                    = "ami-08c40ec9ead489470"
  instance_type          = "t3.small"
  key_name               = "my-keypair"
  vpc_security_group_ids = [aws_security_group.lb_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "nginx-load-balancer"
  }
}
