resource "aws_instance" "posgresql" {
  ami                    = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnets[0]
  key_name               = var.key_name
  private_ip             = var.private_ip

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.key_path
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose;",
      "sudo docker network create web",
      "sudo docker run --restart=unless-stopped --name=postgres -d -p 5432:5432 -e POSTGRES_DB=${var.workspace} -e POSTGRES_USER=${var.workspace} -e POSTGRES_PASSWORD=${var.password} -v $(pwd)/data:/var/lib/postgresql/data postgres",
      "sudo docker run -d --restart=unless-stopped -p 3000:3000 -e PW2_ADHOC_CONN_STR=\"postgresql://${var.workspace}:${var.password}@${self.public_ip}:5432/${var.workspace}\" -e PW2_GRAFANAUSER=admin -e PW2_GRAFANAPASSWORD=admin -e PW2_ADHOC_CONFIG=exhaustive -e PW2_ADHOC_CREATE_HELPERS=true --name pw2 cybertec/pgwatch2-postgres",
      "sudo docker run -d --restart=unless-stopped --name=postgres_backup -e SCHEDULE='@hourly' -e S3_REGION=${var.region} -e S3_ACCESS_KEY_ID=${var.ACCESS_KEY} -e S3_SECRET_ACCESS_KEY=${var.SECRET_KEY} -e S3_BUCKET=${var.bucket} -e POSTGRES_DATABASE=${var.workspace} -e POSTGRES_USER=${var.workspace} -e POSTGRES_HOST=${self.public_ip} -e POSTGRES_PASSWORD=${var.password} -e S3_PREFIX=${var.workspace} -e POSTGRES_EXTRA_OPTS='--schema=public --blobs' schickling/postgres-backup-s3",
      "echo ${var.vault_private_addr} > /tmp/vault-private-addr"
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/shared/scripts/install.sh",
    ]
  }
  tags = {
    Name = "${var.workspace}-posgresql"
  }
}
