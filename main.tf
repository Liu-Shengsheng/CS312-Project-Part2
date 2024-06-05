provider "aws" {
  region = "us-west-2"
}

# Create a new key pair
resource "tls_private_key" "minecraft_pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "minecraft_kp" {
  key_name   = "minecraft-key-pair-2"
  public_key = tls_private_key.minecraft_pk.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.minecraft_pk.private_key_pem}' > ./minecraft-key-pair.pem
      chmod 400 ./minecraft-key-pair.pem
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm ./minecraft-key-pair.pem"
  }
}

# Create a new security group
resource "aws_security_group" "minecraft_server_2_sg" {
  name_prefix = "minecraft-server-2-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "minecraft_server_2" {
  ami           = "ami-03c983f9003cb9cd1"
  instance_type = "t2.small"
  key_name      = aws_key_pair.minecraft_kp.key_name

  vpc_security_group_ids      = [aws_security_group.minecraft_server_2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "minecraft-server-2"
  }

  provisioner "local-exec" {
    command = "echo '${self.public_ip}' > ./server_public_ip.txt"
  }

}
