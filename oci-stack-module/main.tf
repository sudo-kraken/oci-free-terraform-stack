# Specify the required Terraform version and the required providers.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.20.0"
    }
  }
}

# Configure the Oracle Cloud Infrastructure (OCI) provider with necessary credentials and region.
provider "oci" {
  tenancy_ocid          = var.tenancy_ocid
  user_ocid             = var.user_ocid
  private_key_path      = var.private_key_path
  fingerprint           = var.fingerprint
  region                = var.region
}

# Define local variables for cloud-init template files.
locals {
  a1_cloud_init_template_file = "${path.module}/templates/a1-cloud-init.yaml.tpl"
  e2_cloud_init_template_file = "${path.module}/templates/e2-cloud-init.yaml.tpl"
}

# Fetch availability domain information for the specified compartment.
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Fetch boot volume information for instances in the availability domain.
data "oci_core_boot_volumes" "oci_stack_boot_volumes" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.oci_stack.id
}

# Create a new compartment for OCI stack resources.
resource "oci_identity_compartment" "oci_stack" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for oci_stack resources."
  name           = var.compartment_name
  freeform_tags  = var.tags
}

# Create a Virtual Cloud Network (VCN) in OCI.
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.5.5"

  compartment_id = oci_identity_compartment.oci_stack.id
  region         = var.region
  vcn_name       = "ocistack"
  vcn_dns_label  = "ocistackdns"

  create_internet_gateway  = true
  create_nat_gateway       = false
  create_service_gateway   = false
  vcn_cidrs                = ["10.0.0.0/16"]
}

# Configure DHCP options for the VCN.
resource "oci_core_dhcp_options" "dhcp-options" {
  compartment_id = oci_identity_compartment.oci_stack.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "oci_stack-dhcp-options"
  freeform_tags  = var.tags

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["ocistack.oraclevcn.com"]
  }

}

# Create a public subnet within the VCN.
resource "oci_core_subnet" "vcn-public-subnet" {
  compartment_id = oci_identity_compartment.oci_stack.id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.0.0/24"
  freeform_tags  = var.tags

  route_table_id = module.vcn.ig_route_id
  security_list_ids = [
    oci_core_security_list.public-security-list.id,
  ]

  display_name    = "public-subnet"
  dhcp_options_id = oci_core_dhcp_options.dhcp-options.id
  dns_label       = "publicsubnet"
}

# Define a security list with necessary egress and ingress rules.
resource "oci_core_security_list" "public-security-list" {
  compartment_id = oci_identity_compartment.oci_stack.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-public"
  freeform_tags  = var.tags

  # Egress rule to allow all outbound traffic.
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  # Ingress rules for SSH and ICMP
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    description = "SSH traffic"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    description = "ICMP Port Unreachable"

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    description = "ICMP Destination Unreachable"

    icmp_options {
      type = 3
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    description = "ICMP Echo Reply"

    icmp_options {
      type = 0
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "1"
    description = "ICMP Echo"

    icmp_options {
      type = 8
    }
  }
}

# Define network security group and its rules.
resource "oci_core_network_security_group" "oci_stack-network-security-group" {
  compartment_id = oci_identity_compartment.oci_stack.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-oci_stack"
  freeform_tags  = var.tags
}

# Ingress rule for the network security group.
resource "oci_core_network_security_group_security_rule" "oci_stack-network-security-group-list-ingress" {
  network_security_group_id = oci_core_network_security_group.oci_stack-network-security-group.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.oci_stack-network-security-group.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

# Egress rule for the network security group.
resource "oci_core_network_security_group_security_rule" "oci_stack-network-security-group-list-egress" {
  network_security_group_id = oci_core_network_security_group.oci_stack-network-security-group.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.oci_stack-network-security-group.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

# Define instances for Ampere and x86_64 architectures.
resource "oci_core_instance" "vm_instance_ampere" {
  availability_domain                 = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id                      = oci_identity_compartment.oci_stack.id
  shape                               = "VM.Standard.A1.Flex"
  display_name                        = join("", [var.vm_name, "a1"])
  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true
  freeform_tags                       = var.tags

  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = "${base64encode(file("${local.a1_cloud_init_template_file}"))}"
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  source_details {
    source_id   = var.vm_image_ocid_ampere
    source_type = "image"
  }

  availability_config {
    is_live_migration_preferred = true
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.vcn-public-subnet.id
    assign_private_dns_record = true
    hostname_label            = join("", [var.vm_name, "10"])
    private_ip                = join(".", ["10", "0", "0", 110])
    nsg_ids                   = [oci_core_network_security_group.oci_stack-network-security-group.id]
    freeform_tags             = var.tags
  }
}

resource "oci_core_instance" "vm_instance_x86_64" {
  count                               = 2
  availability_domain                 = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id                      = oci_identity_compartment.oci_stack.id
  shape                               = "VM.Standard.E2.1.Micro"
  display_name                        = join("", [var.vm_name, "0", count.index + 1])
  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true
  freeform_tags                       = var.tags

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = "${base64encode(file("${local.e2_cloud_init_template_file}"))}"
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  source_details {
    source_id   = var.vm_image_ocid_x86_64
    source_type = "image"
  }

  availability_config {
    is_live_migration_preferred = true
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.vcn-public-subnet.id
    assign_private_dns_record = true
    hostname_label            = join("", [var.vm_name, "0", count.index + 1])
    private_ip                = join(".", ["10", "0", "0", count.index + 101])
    nsg_ids                   = [oci_core_network_security_group.oci_stack-network-security-group.id]
    freeform_tags             = var.tags
  }
}

# Define an additional storage volume and attach it to the ampere instance.
resource "oci_core_volume" "vm_instance_oci_stack_core_volume" {
  compartment_id       = oci_identity_compartment.oci_stack.id
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name         = join("-", [var.vm_name, "core", "volume"])
  freeform_tags        = var.tags
  size_in_gbs          = 59
  is_auto_tune_enabled = true
  vpus_per_gb          = 0
}

resource "oci_core_volume_attachment" "extra_volume_attachment" {
  attachment_type                     = "paravirtualized"
  instance_id                         = oci_core_instance.vm_instance_ampere.id
  volume_id                           = oci_core_volume.vm_instance_oci_stack_core_volume.id
  device                              = "/dev/oracleoci/oraclevdb"
  display_name                        = "oci_stack-core-volume-attachment"
  is_pv_encryption_in_transit_enabled = true
  is_read_only                        = false
}

# Backup Policy
resource "oci_core_volume_backup_policy" "backup_policy" {
  count = 3
  compartment_id = oci_identity_compartment.oci_stack.id
  display_name = format("Daily %d", count.index)

  schedules {
    backup_type       = "INCREMENTAL"
    hour_of_day       = count.index
    offset_type       = "STRUCTURED"
    period            = "ONE_DAY"
    retention_seconds = 86400
    time_zone         = "REGIONAL_DATA_CENTER_TIME"
  }
}

resource "oci_core_volume_backup_policy_assignment" "backup_policy_assignment" {
  count = 3
  asset_id = (
    count.index < 2 ?
    oci_core_instance.vm_instance_x86_64[count.index].boot_volume_id :
    oci_core_instance.vm_instance_ampere.boot_volume_id
  )
  policy_id = oci_core_volume_backup_policy.backup_policy[count.index].id
}


