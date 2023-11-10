# Definition of Oracle Cloud Infrastructure Tenancy ID
variable "tenancy_id" {
  description = "The OCID of the tenancy"
  type        = string
}

# Definition of Oracle Cloud Infrastructure User ID
variable "user_id" {
  description = "The OCID of the user"
  type        = string
}

# Definition of the fingerprint for the public key
variable "fingerprint" {
  description = "Fingerprint for the public key used in OCI"
  type        = string
}

# Path to the private key file for OCI
variable "private_key_path" {
  description = "Path to the private key file used in OCI"
  type        = string
}

# The region in which to create the resources
variable "region" {
  description = "The region in which to create the resources"
  type        = string
}

# Number of instances to create
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
}

# The shape (type) of the instance
variable "instance_type" {
  description = "The shape (type) of the instance"
  type        = string
}

# Number of OCPUs for the instance
variable "instance_cpu_count" {
  description = "Number of OCPUs for the instance"
  type        = number
}

# Amount of memory in GB for the instance
variable "instance_memory_gb" {
  description = "Amount of memory in GB for the instance"
  type        = number
}

# Type of the instance image
variable "instance_image_type" {
  description = "Type of the instance image"
  type        = string
}

# OCID of the instance image per region
variable "instance_image_id" {
  description = "OCID of the instance image per region"
  type        = map(string)
}

# Size of the boot volume in GB
variable "boot_volume_size_gb" {
  description = "Size of the boot volume in GB"
  type        = number
}

# SSH public key
variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

# Compartment ID for the resources
variable "compartment_id" {
  description = "Compartment ID for the resources"
  type        = string
}

# Availability domain number
variable "ad_number" {
  description = "Availability domain number"
  type        = number
}

# Flag to enable iptables configuration
variable "enable_iptables_config" {
  description = "Flag to enable iptables configuration"
  type        = bool
  default     = false
}

# Path to the SSH private key for remote access
variable "ssh_private_key_path" {
  description = "Path to the SSH private key for remote access"
  type        = string
}

# Name format for the instance and associated resources
variable "instance_name" {
  description = "Name format for the instance and associated resources"
  type        = string
}
