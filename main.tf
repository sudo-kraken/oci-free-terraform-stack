# Tenancy OCID Value
variable "tenancy-ocid" {}

# User OCID Value
variable "user-ocid" {}

# Fingerprint Value
variable "fp" {}

# Private Key Contents
variable "pkey" {}

# SSH public key to use for SSH access
varibale "ssh_pub_key" {}

# Define the module source and its location                    
module "oci-stack-module" {
  source                   = "./oci-stack-module"
  tenancy_ocid             = var.tenancy-ocid
  user_ocid                = var.user-ocid
  compartment_name         = var.fp
  fingerprint              = var.pkey
  region                   = "uk-london-1"
  vm_name                  = "oci-stack-instance"
  vm_image_ocid_x86_64     = "ocid1.image.oc1.uk-london-1.aaaaaaaaojqrgcwxe5ft3tcoccighpeavtpnv5jcgi7pbvssqgibz7mczjeq"
  vm_image_ocid_ampere     = "ocid1.image.oc1.uk-london-1.aaaaaaaa57kek4gtk6exlfu7yijjsa26bdmm42ibogeqi7ehwah5fxd6ybda"
  private_key              = var.pkey
  ssh_public_key           = var.ssh_pub_key
  tags                     = { Project = "oci-tf-stack" }

output "public-ip-x86_64-instances" {
  value = oci_core_instance.vm_instance_x86_64.*.public_ip
}

output "public-ip-ampere-instance" {
  value = oci_core_instance.vm_instance_ampere.public_ip
}
