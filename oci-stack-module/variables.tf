variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint for the key pair"
  type        = string
}

variable "region" {
  description = "The OCI region for resources"
  type        = string
}

variable "compartment_name" {
  description = "The name of the compartment"
  type        = string
}

variable "tags" {
  description = "Freeform tags for the resources"
  type        = map(any)
  default     = {}
}

variable "vm_name" {
  description = "The name of the VM instances"
  type        = string
}

variable "vm_image_ocid_ampere" {
  description = "The OCID of the Oracle Linux 9 image for Ampere architecture"
  type        = string
}

variable "vm_image_ocid_x86_64" {
  description = "The OCID of the Oracle Linux 9 image for x86_64 architecture"
  type        = string
}

variable "ssh_public_key" {
  description = "The public key for SSH access to instances"
  type        = string
}
