output "bctf_rg_id" {
  description = "Returns the ID of the created resource group"
  value       = azurerm_resource_group.bctf-rg.id
}

output "public_ip_address" {
  description = "The public IP address for the virtual machine"
  value       = azurerm_public_ip.bctf-pip.ip_address
}

# output "private_ssh_key" {
#   description = "The private SSH key to access the VRE"
#   value       = tls_private_key.bctf-ssh-key.private_key_pem
#   sensitive   = true
# }