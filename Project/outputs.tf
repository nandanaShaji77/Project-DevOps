output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = "3.238.240.184" //aws_instance.web_server[0].public_ip
}
output "instance_id" {
  value = "i-0365f0b4ff7876be2" //aws_instance.web_server[0].id
  description = "The ID of the provisioned EC2 instance."
}