terraform {
  required_version = ">= 1.6.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.20.0"
    }
  }
}

provider "oci" {
  tenancy_ocid          = var.tenancy_ocid
  user_ocid             = var.user_ocid
  private_key_path      = var.private_key
  fingerprint           = var.fingerprint
  region                = var.region
}

# Cloud-Init file
locals {
  a1_cloud_init_template_file = "{path.module}/templates/a1-cloud-init.yaml.tpl"
  e2_cloud_init_template_file = "{path.module}/templates/e2-cloud-init.yaml.tpl"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_boot_volumes" "oci_stack_boot_volumes" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.oci_stack.id
}

resource "oci_identity_compartment" "oci_stack" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for oci_stack resources."
  name           = var.compartment_name
  freeform_tags  = var.tags
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.5.5"

  compartment_id = oci_identity_compartment.oci_stack.id
  region         = var.region
  vcn_name       = var.compartment_name
  vcn_dns_label  = var.compartment_name

  create_internet_gateway  = true
  create_nat_gateway       = false
  create_service_gateway   = false
  vcn_cidrs                = "10.0.0.0/16"
}

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
    search_domain_names = ["oci_stack.oraclevcn.com"]
  }

}

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

resource "oci_core_security_list" "public-security-list" {
  compartment_id = oci_identity_compartment.oci_stack.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-public"
  freeform_tags  = var.tags

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

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

resource "oci_core_network_security_group" "oci_stack-network-security-group" {
  compartment_id = oci_identity_compartment.oci_stack.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-oci_stack"
  freeform_tags  = var.tags
}

resource "oci_core_network_security_group_security_rule" "oci_stack-network-security-group-list-ingress" {
  network_security_group_id = oci_core_network_security_group.oci_stack-network-security-group.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.oci_stack-network-security-group.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

resource "oci_core_network_security_group_security_rule" "oci_stack-network-security-group-list-egress" {
  network_security_group_id = oci_core_network_security_group.oci_stack-network-security-group.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.oci_stack-network-security-group.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

resource "oci_core_instance" "vm_instance_ampere" {
  availability_domain                 = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id                      = oci_identity_compartment.oci_stack.id
  shape                               = "VM.Standard.A1.Flex"
  display_name                        = join("", [var.vm_name, "10"])
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

resource "oci_core_volume" "vm_instance_oci_stack_core_volume" {
  compartment_id       = oci_identity_compartment.oci_stack.id
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name         = join("-", [var.vm_name, "core", "volume"])
  freeform_tags        = var.tags
  size_in_gbs          = 59
  is_auto_tune_enabled = true
}

resource "oci_core_volume_backup_policy_assignment" "oci_stack_core_volume_backup_policy_assignment" {
  asset_id  = oci_core_volume.vm_instance_oci_stack_core_volume.id
  policy_id = oci_core_volume_backup_policy.oci_stack_volume_backup_policy.id

  depends_on = [
    oci_core_instance.vm_instance_x86_64,
    oci_core_instance.vm_instance_ampere
  ]
}

resource "oci_core_volume_attachment" "extra_volume_attachment" {
  attachment_type                     = "paravirtualized"
  instance_id                         = oci_core_instance.vm_instance_ampere.id
  volume_id                           = oci_core_volume.vm_instance_oci_stack_core_volume.id
  device                              = "/dev/oracleoci/oracleextravol"
  display_name                        = "oci_stack-core-volume-attachment"
  is_pv_encryption_in_transit_enabled = true
  is_read_only                        = false
}

resource "oci_core_volume_backup_policy" "oci_stack_volume_backup_policy" {
  compartment_id = oci_identity_compartment.oci_stack.id
  display_name   = "oci_stack"
  freeform_tags  = var.tags

  schedules {
    backup_type       = "INCREMENTAL"
    day_of_month      = 1
    day_of_week       = "FRIDAY"
    hour_of_day       = 4
    month             = "NOVEMBER"
    offset_seconds    = 0
    offset_type       = "STRUCTURED"
    period            = "ONE_WEEK"
    retention_seconds = 3024000
    time_zone         = "REGIONAL_DATA_CENTER_TIME"
  }
}

resource "oci_core_volume_backup_policy_assignment" "oci_stack_boot_volume_backup_policy_assignment" {
  count     = 3
  asset_id  = data.oci_core_boot_volumes.oci_stack_boot_volumes.boot_volumes[count.index].id
  policy_id = oci_core_volume_backup_policy.oci_stack_volume_backup_policy.id

  depends_on = [
    oci_core_instance.vm_instance_x86_64,
    oci_core_instance.vm_instance_ampere
  ]
}

# Output the "list" of all availability domains.
output "all-availability-domains-in-your-tenancy" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}

output "compartment-name" {
  value = oci_identity_compartment.oci_stack.name
}

output "public-ip-x86_64-instances" {
  value = oci_core_instance.vm_instance_x86_64.*.public_ip
}

output "public-ip-ampere-instance" {
  value = oci_core_instance.vm_instance_ampere.public_ip
}

