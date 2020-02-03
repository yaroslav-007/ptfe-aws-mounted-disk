resource "aws_instance" "hopping-station" {

  ami                    = "ami-0be057a22c63962cb"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.ptfe-vpc-public-subnet.id         
  vpc_security_group_ids = [aws_security_group.vpc_ssh_icmp_echo_sg.id] 
  key_name               = aws_key_pair.yaro-ssh.id                     
  tags = {
    Name = "Yaro-ptfe-hopping-station"
  }

  user_data = <<-EOF
		#! /bin/bash
    chmod 400 /home/ubuntu/.ssh/id_rsa
    echo "ssh ptfe.iaroslav.eu" >> /home/ubuntu/.bash_history
	EOF

  provisioner "file" {
    source      = "./keys/id_rsa"
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
      type        = "ssh"
      host        = aws_instance.hopping-station.public_ip
      user        = "ubuntu"
      private_key = file("./keys/id_rsa")

    }


  }

  depends_on = [aws_internet_gateway.ptfe-vpc-internet-gw]
}





output "hopping-station" {
  value = aws_instance.hopping-station.public_ip
}