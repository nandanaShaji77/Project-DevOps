data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"] # Canonical
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
}
resource "random_id" "random_node_id" {
    byte_length = 2
    count= var.main_instance_count

}
resource "aws_key_pair" "deployer_key" {
    key_name   = var.key_name
    public_key = file(var.public_key_path)

}
resource "aws_instance" "web_server" {
    count= var.main_instance_count
    ami=data.aws_ami.ubuntu.id
    instance_type=var.instance_type
    subnet_id=aws_subnet.public_subnet[count.index].id
    key_name=aws_key_pair.deployer_key.key_name
    vpc_security_group_ids=[aws_security_group.project_sg.id]
    user_data = templatefile("main-userdata.tpl", {
        new_hostname = "web-server-${random_id.random_node_id[count.index].dec}"
    })
    tags={
        Name="web-server-${random_id.random_node_id[count.index].dec}"   
    }
}
#     provisioner "local-exec" {
#         interpreter = ["C:\\Program Files\\Git\\bin\\bash.exe", "-c"]
#         command     = "printf \"\\n${self.public_ip}\" >> aws_host"
# }


#     provisioner "local-exec" {
#         when        = destroy
#         interpreter = [ "C:\\Program Files\\Git\\bin\\bash.exe", "-c" ]
#         command     = "sed -i '/^[0-9]/d' aws_host"
#     }
# }

# locals {
#   windows_key_path = var.private_key_path
#   wsl_key_path     = replace(local.windows_key_path, "C:/Users", "/mnt/c/Users")
# }

# resource "null_resource" "grafana_provisoner" {
#     depends_on = [aws_instance.web_server]

#     provisioner "remote-exec" {
#         connection {
#             type        = "ssh"
#             host        = aws_instance.web_server[0].public_ip
#             user        = "ubuntu"
#             private_key = file(local.windows_key_path)
#             timeout     = "5m"
#         }

#         inline = ["echo 'connection test successful! Instance is reachable by ssh'"]
#     }

#     provisioner "local-exec" {
#         interpreter = ["wsl", "bash", "-c"]
#         command = "ansible-playbook --private-key ${var.aws_private_key_path} playbooks/grafana.yml"

#     }

#     provisioner "local-exec" {
#   interpreter = ["wsl", "bash", "-c"]
#   command     = "ansible-playbook --private-key ${var.aws_private_key_path} playbooks/grafana.yml"
# }

# }


