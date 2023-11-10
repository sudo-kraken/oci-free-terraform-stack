terraform {
  required_version = ">= 1.6.0"

  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.0.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}

resource "oci_core_volume_backup_policy" "homelab_volume_backup_policy" {
  compartment_id = oci_identity_compartment.homelab.id
  display_name   = "homelab"
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

resource "oci_core_volume_backup_policy_assignment" "homelab_boot_volume_backup_policy_assignment" {
  count     = 3
  asset_id  = data.oci_core_boot_volumes.homelab_boot_volumes.boot_volumes[count.index].id
  policy_id = oci_core_volume_backup_policy.homelab_volume_backup_policy.id

  depends_on = [
    oci_core_instance.vm_instance_x86_64,
    oci_core_instance.vm_instance_ampere
  ]
}

resource "oci_identity_compartment" "homelab" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for homelab resources."
  name           = var.compartment_name
  freeform_tags  = var.tags
}

resource "oci_core_instance" "vm_instance_ampere" {
  availability_domain                 = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id                      = oci_identity_compartment.homelab.id
  shape                               = "VM.Standard.A1.Flex"
  display_name                        = join("", [var.vm_name, "10"])
  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true
  freeform_tags                       = var.tags

  #   lifecycle {
  #     prevent_destroy = true
  #   }

  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
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
    nsg_ids                   = [oci_core_network_security_group.homelab-network-security-group.id]
    freeform_tags             = var.tags
  }
}

resource "oci_core_instance" "vm_instance_x86_64" {
  count                               = 2
  availability_domain                 = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id                      = oci_identity_compartment.homelab.id
  shape                               = "VM.Standard.E2.1.Micro"
  display_name                        = join("", [var.vm_name, "0", count.index + 1])
  preserve_boot_volume                = false
  is_pv_encryption_in_transit_enabled = true
  freeform_tags                       = var.tags

  #   lifecycle {
  #     prevent_destroy = true
  #   }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
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
    nsg_ids                   = [oci_core_network_security_group.homelab-network-security-group.id]
    freeform_tags             = var.tags
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_boot_volumes" "homelab_boot_volumes" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.homelab.id
}

# Source from https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_dhcp_options

resource "oci_core_dhcp_options" "dhcp-options" {
  compartment_id = oci_identity_compartment.homelab.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "homelab-dhcp-options"
  freeform_tags  = var.tags

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

  options {
    type                = "SearchDomain"
    search_domain_names = ["homelab.oraclevcn.com"]
  }

}

resource "oci_core_subnet" "vcn-public-subnet" {
  compartment_id = oci_identity_compartment.homelab.id
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
  compartment_id = oci_identity_compartment.homelab.id
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

resource "oci_core_network_security_group" "homelab-network-security-group" {
  compartment_id = oci_identity_compartment.homelab.id
  vcn_id         = module.vcn.vcn_id
  display_name   = "network-security-group-homelab"
  freeform_tags  = var.tags
}

resource "oci_core_network_security_group_security_rule" "homelab-network-security-group-list-ingress" {
  network_security_group_id = oci_core_network_security_group.homelab-network-security-group.id
  direction                 = "INGRESS"
  source                    = oci_core_network_security_group.homelab-network-security-group.id
  source_type               = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

resource "oci_core_network_security_group_security_rule" "homelab-network-security-group-list-egress" {
  network_security_group_id = oci_core_network_security_group.homelab-network-security-group.id
  direction                 = "EGRESS"
  destination               = oci_core_network_security_group.homelab-network-security-group.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  protocol                  = "all"
  stateless                 = true
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "2.2.0"

  compartment_id = oci_identity_compartment.homelab.id
  region         = "ap-southeast-2"
  vcn_name       = var.compartment_name
  vcn_dns_label  = var.compartment_name

  internet_gateway_enabled = true
  nat_gateway_enabled      = false
  service_gateway_enabled  = false
  vcn_cidr                 = "10.0.0.0/16"
}

resource "oci_core_volume" "vm_instance_homelab_core_volume" {
  compartment_id       = oci_identity_compartment.homelab.id
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name         = join("-", [var.vm_name, "core", "volume"])
  freeform_tags        = var.tags
  size_in_gbs          = 59
  is_auto_tune_enabled = true
}

resource "oci_core_volume_backup_policy_assignment" "homelab_core_volume_backup_policy_assignment" {
  asset_id  = oci_core_volume.vm_instance_homelab_core_volume.id
  policy_id = oci_core_volume_backup_policy.homelab_volume_backup_policy.id

  depends_on = [
    oci_core_instance.vm_instance_x86_64,
    oci_core_instance.vm_instance_ampere
  ]
}

resource "oci_core_volume_attachment" "test_volume_attachment" {
  attachment_type                     = "paravirtualized"
  instance_id                         = oci_core_instance.vm_instance_ampere.id
  volume_id                           = oci_core_volume.vm_instance_homelab_core_volume.id
  device                              = "/dev/oracleoci/oraclevdb"
  display_name                        = "homelab-core-volume-attachment"
  is_pv_encryption_in_transit_enabled = true
  is_read_only                        = false
}

# Output the "list" of all availability domains.
output "all-availability-domains-in-your-tenancy" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}

output "compartment-name" {
  value = oci_identity_compartment.homelab.name
}

output "public-ip-x86_64-instances" {
  value = oci_core_instance.vm_instance_x86_64.*.public_ip
}

output "public-ip-ampere-instance" {
  value = oci_core_instance.vm_instance_ampere.public_ip
}

