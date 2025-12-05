resource "aws_security_group" "ec2_sg" {
  name        = "app-test-ec2-sg"
  description = "Security group para EC2 de app-test"
  vpc_id      =  aws_vpc.app_test.id  

  ingress {
    description = "SSH desde cualquier lado (demo)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["181.135.71.181/32"]
  }
  ingress {
    description = "HTTP (demo)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]

    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-test-ec2-sg"
  }
}


locals {
  subnet_map = {
    private_az1 = aws_subnet.private_az1.id
    private_az2 = aws_subnet.private_az2.id
  }
}

resource "aws_instance" "app_server" {
  for_each = var.instances

  ami                         = "ami-0fa3fe0fa7920f68e"
  instance_type               = "t3.micro"
  subnet_id                   = local.subnet_map[each.value.subnet_id]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data_replace_on_change = true

  user_data = <<-EOF
#!/bin/bash
ZIP_HASH="${data.aws_s3_object.zip_info.etag}"
sudo yum update -y
sudo yum install nginx unzip -y
sudo yum install python3-pip -y

sudo systemctl start nginx
sudo systemctl enable nginx

cd /home/ec2-user/
aws s3 cp s3://${aws_s3_bucket.zip_bucket.bucket}/miapp.zip /home/ec2-user/
unzip miapp.zip

sudo mv /home/ec2-user/miapp/flask-app.service /etc/systemd/system/flask-app.service
sudo systemctl daemon-reload
sudo systemctl enable --now flask-app.service

pip3 install -r /home/ec2-user/miapp/requirements.txt

echo "location / {
    proxy_pass http://127.0.0.1:5000;

    proxy_set_header Host            \\\$host;
    proxy_set_header X-Real-IP       \\\$remote_addr;
    proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \\\$scheme;
}" | sudo tee /etc/nginx/default.d/reverse-proxy.conf > /dev/null

sudo nginx -t
sudo systemctl reload nginx
EOF
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_s3_object.zip_file,
    data.aws_s3_object.zip_info
  ]

  tags = {
    Name = each.value.name
  }
}