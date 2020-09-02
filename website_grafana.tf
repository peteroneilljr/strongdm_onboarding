data "aws_ami" "amazon_linux_2" {
 most_recent = true
 owners = ["amazon"]
 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "apache" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  subnet_id = sort(data.aws_subnet_ids.public.ids)[1]

  user_data = <<EOF
  #!/bin/bash
  yum update -y
  amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
  yum install -y httpd mariadb-server
  systemctl start httpd
  systemctl enable httpd
  usermod -a -G apache ec2-user
  chown -R ec2-user:apache /var/www
  chmod 2775 /var/www
  find /var/www -type d -exec chmod 2775 {} \;
  find /var/www -type f -exec chmod 0664 {} \;
  echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
  EOF

  tags = merge({
    Name = "Apache"
  }, var.default_tags)
}

resource "sdm_resource" "apache_endpoint" {
  http_no_auth {
    name             = "${var.prefix}-apache"
    url              = "http://${aws_instance.apache.private_dns}"
    default_path     = "/phpinfo.php"
    healthcheck_path = "/phpinfo.php"
    subdomain        = "apache"

    tags = var.default_tags
  }
}

resource "sdm_resource" "ssh_ec2" {
  ssh_cert {
    # dependant on https://github.com/strongdm/issues/issues/1701
    name     = "${var.prefix}-ssh-ca"
    username = "ec2-user"
    hostname = aws_instance.apache.private_dns
    port     = 22
  }
}
