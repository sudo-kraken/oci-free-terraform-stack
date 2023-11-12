# Tenancy OCID Value
variable "tenancy_ocid" {}

# User OCID Value
variable "user_ocid" {}

# Fingerprint Value
variable "fp" {}

# Private Key Contents
variable "pkey_path" {}

# SSH public key to use for SSH access
variable "ssh_pub_key" {}

# Define the module source and its location                    
module "oci-stack" {
  source                   = "./oci-stack-module"
  tenancy_ocid             = var.tenancy_ocid
  user_ocid                = var.user_ocid
  compartment_name         = "oci-stack"
  fingerprint              = var.fp
  region                   = "uk-london-1"
  vm_name                  = "oci-stack-instance"
  vm_image_ocid_x86_64     = "ocid1.image.oc1.uk-london-1.aaaaaaaaojqrgcwxe5ft3tcoccighpeavtpnv5jcgi7pbvssqgibz7mczjeq"
  vm_image_ocid_ampere     = "ocid1.image.oc1.uk-london-1.aaaaaaaa57kek4gtk6exlfu7yijjsa26bdmm42ibogeqi7ehwah5fxd6ybda"
  private_key_path         = var.pkey_path
  ssh_public_key           = var.ssh_pub_key
  tags                     = { Project = "oci-tf-stack" }

}

output "module_public_ips_x86_64" {
  value = module.oci-stack.public-ip-x86_64-instances
}

output "module_private_ips_x86_64" {
  value = module.oci-stack.private-ip-x86_64-instances
}

output "module_instance_id_x86_64" {
  value = module.oci-stack.instance-id-x86_64-instances
}

output "module_public_ip_ampere" {
  value = module.oci-stack.public-ip-ampere-instance
}

output "module_private_ip_ampere" {
  value = module.oci-stack.private-ip-ampere-instance
}

output "module_instance_id_ampere" {
  value = module.oci-stack.instance-id-ampere-instance
}
