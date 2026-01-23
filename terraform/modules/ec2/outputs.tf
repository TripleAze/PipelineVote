output "instance_ids" {
  value = [for instance in aws_instance.app : instance.id]
}

output "instance_ids_map" {
  value = { for k, v in aws_instance.app : k => v.id }
}

output "private_ips" {
  value = [for instance in aws_instance.app : instance.private_ip]
}
