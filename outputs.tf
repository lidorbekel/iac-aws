output "public_ip" {
  value = module.run_docker_example.public_ip
}
 
output "dns_name" {
  value = module.run_docker_example.public_dns
}
