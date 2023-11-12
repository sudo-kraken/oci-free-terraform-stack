output "public-ip-x86_64-instances" {
  description = "The public IP addresses assigned to the E2 instances"
  value = oci_core_instance.vm_instance_x86_64.*.public_ip
}

output "private-ip-x86_64-instances" {
  description = "The private IP addresses assigned to the E2 instances"
  value = oci_core_instance.vm_instance_x86_64.*.private_ip
}

output "instance-id-x86_64-instances" {
  description = "The OCID of the E2 instances"
  value = oci_core_instance.vm_instance_x86_64.*.id
}

output "public-ip-ampere-instance" {
  description = "The public IP addresse assigned to the A2 instance"
  value = oci_core_instance.vm_instance_ampere.public_ip
}

output "private-ip-ampere-instance" {
  description = "The private IP addresse assigned to the A2 instance"
  value = oci_core_instance.vm_instance_ampere.private_ip
}

output "instance-id-ip-ampere-instance" {
  description = "The OCID of the A1 instance"
  value = oci_core_instance.vm_instance_ampere.id
}
