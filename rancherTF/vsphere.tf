
terraform {
  required_providers {
    rancher2 = {
      source = "terraform.local/local/rancher2"
      version = "4.0.0-rc3"
    }
  }
}


provider "rancher2" {
  api_url   = var.rancher_url
  token_key = var.rancher_admin_token
  insecure  = true
}

### RKE2
# Create vsphere cloud credential
resource "rancher2_cloud_credential" "vsphereconfig1" {
  name = "vsphere1"
  vsphere_credential_config {
    username = var.vsphere_username
    password = var.vsphere_password
    vcenter = var.vsphere_vcenter
  }
}

# Create vsphere machine config v2
resource "rancher2_machine_config_v2" "machine1" {
  generate_name = format("%s%s", var.user_prefix, "-machine1")
  vsphere_config {
    cfgparam = ["disk.enableUUID=TRUE"]
    clone_from = format("%s%s%s%s", "/", var.vsphere_datacenter, "/vm/", var.vsphere_template_filepath)
    content_library = "rancher-approved"
    cpu_count = "4"
    creation_type = "template"
    datacenter = format("%s%s", "/", var.vsphere_datacenter)
    datastore = format("%s%s%s%s", "/", var.vsphere_datacenter, "/datastore/", var.vsphere_datastore)
    disk_size = "20000"
    folder = format("%s%s%s%s", "/", var.vsphere_datacenter, "/vm/", var.user_prefix)
    
    memory_size = "8192"
    network = [format("%s%s%s%s", "/", var.vsphere_datacenter, "/network/", var.vsphere_network)]
    pool = format("%s%s%s%s", "/", var.vsphere_datacenter, "/host/Cluster/Resources/", var.user_prefix)

    # new feature
    graceful_shutdown_timeout = "5"
  }
}
resource "rancher2_machine_config_v2" "machine2" {
  generate_name = format("%s%s", var.user_prefix, "-machine1")
  vsphere_config {
    cfgparam = ["disk.enableUUID=TRUE"]
    clone_from = format("%s%s%s%s", "/", var.vsphere_datacenter, "/vm/", var.vsphere_template_filepath)
    content_library = "rancher-approved"
    cpu_count = "4"
    creation_type = "template"
    datacenter = format("%s%s", "/", var.vsphere_datacenter)
    datastore = format("%s%s%s%s", "/", var.vsphere_datacenter, "/datastore/", var.vsphere_datastore)
    disk_size = "20000"
    folder = format("%s%s%s%s", "/", var.vsphere_datacenter, "/vm/", var.user_prefix)
    
    memory_size = "8192"
    network = [format("%s%s%s%s", "/", var.vsphere_datacenter, "/network/", var.vsphere_network)]
    pool = format("%s%s%s%s", "/", var.vsphere_datacenter, "/host/Cluster/Resources/", var.user_prefix)

    # new feature
    graceful_shutdown_timeout = "5"
  }
}



# Create a new rancher v2 rke2 RKE2 Cluster v2
resource "rancher2_cluster_v2" "cluster1" {
  name = format("%s%s", var.user_prefix, "-rke22")
  kubernetes_version = "v1.26.8+rke2r1"
  enable_network_policy = false
  default_cluster_role_for_project_members = "user"
  rke_config {
    machine_pools {
      name = format("%s%s", var.user_prefix, "p1")
      cloud_credential_secret_name = rancher2_cloud_credential.vsphereconfig1.id
      control_plane_role = true
      etcd_role = true
      worker_role = true
      quantity = 1
      machine_config {
        kind = rancher2_machine_config_v2.machine1.kind
        name = rancher2_machine_config_v2.machine1.name
      }
    }
      machine_pools {
      name = format("%s%s", var.user_prefix, "p2")
      cloud_credential_secret_name = rancher2_cloud_credential.vsphereconfig1.id
      control_plane_role = false
      etcd_role = false
      worker_role = true
      quantity = 1
      machine_config {
        kind = rancher2_machine_config_v2.machine2.kind
        name = rancher2_machine_config_v2.machine2.name
      }
    }
    machine_pools {
      name = format("%s%s", var.user_prefix, "p3")
      cloud_credential_secret_name = rancher2_cloud_credential.vsphereconfig1.id
      control_plane_role = false
      etcd_role = false
      worker_role = true
      quantity = 1
      machine_config {
        kind = rancher2_machine_config_v2.machine2.kind
        name = rancher2_machine_config_v2.machine2.name
      }
    }
  }
}

### RKE1
# Create vsphere node template config
resource "rancher2_node_template" "nodetemplate1" {
  name = format("%s%s", var.user_prefix, "-nt1")
  vsphere_config {
    cfgparam = ["disk.enableUUID=TRUE"]
    clone_from = format("%s%s%s%s", "/", var.vsphere_datacenter, "/vm/", var.vsphere_template_filepath)
    content_library = "rancher-approved"
    cpu_count = "4"
    creation_type = "template"
    datacenter = format("%s%s", "/", var.vsphere_datacenter)
    datastore = format("%s%s%s%s", "/", var.vsphere_datacenter, "/datastore/", var.vsphere_datastore)
    disk_size = "20000"
    folder = format("%s%s%s%s", "/", var.vsphere_datacenter, "/vm/", var.user_prefix)
    memory_size = "8192"
    network = [format("%s%s%s%s", "/", var.vsphere_datacenter, "/network/", var.vsphere_network)]
    pool = format("%s%s%s%s", "/", var.vsphere_datacenter, "/host/Cluster/Resources/", var.user_prefix)

    vcenter = var.vsphere_vcenter
    vcenter_port = "443"
    username = var.vsphere_username
    password = var.vsphere_password

    # new feature
    graceful_shutdown_timeout = "10"
  }
}

resource "rancher2_cluster" "rke1cluster1" {
  name = "rke1cluster1"
  rke_config {
    enable_cri_dockerd = true
    network {
      plugin = "canal"
    }
  }
}

resource "rancher2_node_pool" "pool1" {
  cluster_id = rancher2_cluster.rke1cluster1.id
  name = "pool1"
  hostname_prefix = format("a-%s",var.user_prefix)
  node_template_id = rancher2_node_template.nodetemplate1.id
  quantity = 1
  control_plane = true
  etcd = true
  worker = true
}

resource "rancher2_node_pool" "pool2" {
  cluster_id = rancher2_cluster.rke1cluster1.id
  name = "pool2"
  hostname_prefix = format("w-%s", var.user_prefix)
  node_template_id = rancher2_node_template.nodetemplate1.id
  quantity = 1
  control_plane = false
  etcd = false
  worker = true
}