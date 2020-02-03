resource "aws_instance" "ptfe" {

  ami                    = "ami-0be057a22c63962cb"
  instance_type          = "t2.large"
  subnet_id              = aws_subnet.ptfe-vpc-private-subnet.id        
  vpc_security_group_ids = [aws_security_group.vpc_ssh_icmp_echo_sg.id] 
  key_name               = aws_key_pair.yaro-ssh.id                     
  tags = {
    Name = "ptfe-instance"
  }
  availability_zone = "eu-west-2a"
  root_block_device {
    volume_size = 10
  }
  provisioner "file" {
    source      = "ptfe-ec2"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      host        = aws_instance.ptfe.private_ip
      user        = "ubuntu"
      private_key = file("./keys/id_rsa")

      bastion_host        = aws_instance.hopping-station.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("./keys/id_rsa")
    }

  }
  private_ip = "10.0.1.161"
  user_data  = file("./scripts/ptfe-script.sh")

  timeouts {
    delete = "1m"
  }


  depends_on = [aws_internet_gateway.ptfe-vpc-internet-gw]
}


resource "aws_key_pair" "yaro-ssh" {
  key_name   = "yaro-ssh"
  public_key = ""
}


resource "aws_volume_attachment" "docker" {
  device_name = "/dev/xvdh"
  volume_id   = aws_ebs_volume.docker.id
  instance_id = aws_instance.ptfe.id
}


resource "aws_ebs_volume" "docker" {
  availability_zone = "eu-west-2a"
  size              = 40
  tags = {
    Name = "ptfe-docker-ebs_volume"
  }

}

resource "aws_volume_attachment" "ptfe" {
  device_name = "/dev/xvdi"
  volume_id   = aws_ebs_volume.ptfe.id
  instance_id = aws_instance.ptfe.id
}


resource "aws_ebs_volume" "ptfe" {
  availability_zone = "eu-west-2a"
  size              = 5
  tags = {
    Name = "ptfe-ptfe-ebs_volume"
  }

}



resource "aws_volume_attachment" "snapshots" {
  device_name = "/dev/xvdj"
  volume_id   = aws_ebs_volume.snapshots.id
  instance_id = aws_instance.ptfe.id
}


resource "aws_ebs_volume" "snapshots" {
  availability_zone = "eu-west-2a"
  size              = 5
  tags = {
    Name = "ptfe-snapshots-ebs_volume""
  }

}






output "instance_ip_addr" {
  value = aws_instance.ptfe.private_ip
}