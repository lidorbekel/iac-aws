output "public_ip" {
  value = module.run_docker.public_ip
}
 
output "dns_name" {
  value = module.run_docker.public_dns
}
