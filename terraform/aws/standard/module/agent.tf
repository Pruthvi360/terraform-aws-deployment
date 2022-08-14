resource "aws_instance" "kasm-agent" {
  count                       = "${var.num_agents}"
  ami                         = "${var.ec2_ami}"
  instance_type               = "${var.agent_instance_type}"
  vpc_security_group_ids      = ["${aws_security_group.kasm-agent-sg.id}"]
  subnet_id                   = "${aws_subnet.kasm-use-natgw-subnet.id}"
  key_name                    = "${var.aws_key_pair}"
  associate_public_ip_address = false

  root_block_device {
    volume_size = "50"
  }

  user_data = <<-EOF
              #!/bin/bash
              fallocate -l 5g /mnt/kasm.swap
              chmod 600 /mnt/kasm.swap
              mkswap /mnt/kasm.swap
              swapon /mnt/kasm.swap
              echo '/mnt/kasm.swap swap swap defaults 0 0' | tee -a /etc/fstab
              cd /tmp
              wget ${var.kasm_build}
              tar xvf kasm_*.tar.gz
              PRIVATE_IP=(`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`)
              bash kasm_release/install.sh -S agent -e  -p $PRIVATE_IP -m ${var.zone_name}-lb.${var.aws_domain_name} -M ${var.manager_token}
              EOF
  tags = {
    Name = "${var.project_name}-${var.zone_name}-kasm-agent"
  }
}
