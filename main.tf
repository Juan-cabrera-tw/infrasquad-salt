module "nomad" {
  source   = "./modules/nomad"
  key_name = aws_key_pair.key.key_name
  key_path = var.PRIVATE_KEY_PATH
  region   = var.AWS_REGION
  vpc_id   = aws_default_vpc.default.id
  vpc_security_group_ids = ["${aws_security_group.lab_squad_sg.id}"]
  subnets = {
    "0" = aws_default_subnet.default_az1.id
    "1" = aws_default_subnet.default_az2.id
    "2" = aws_default_subnet.default_az3.id
  }
}

output "nomad-output" {
  value = module.nomad.server_address
}
