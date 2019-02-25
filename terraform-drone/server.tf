resource "google_compute_disk" "pd-server" {
  project = "${var.project_id}"
  name    = "${var.drone_server_name}-data"
  type    = "pd-ssd"
  zone    = "${var.zone}"
  zone    = "${random_shuffle.zone.result[0]}"
  size    = "${var.drone_server_data_disk_size}"
}

module "container-server" {
  source = "github.com/terraform-google-modules/terraform-google-container-vm"
  version = "0.1.0"

  container = {
    image = "${var.drone_server_image}"

    volumeMounts = [
      {
        mountPath = "/var/run/docker.sock"
        name      = "docker-sock"
        readOnly  = "false"
      },
      {
        mountPath = "/data"
        name      = "drone-data"
        readOnly  = "false"
      },
    ]
    env = [
      { name = "DRONE_GITHUB_SERVER"        value = "${var.github_server}" },
      { name = "DRONE_USER_FILTER"          value = "${var.github_user_filter}" },
      { name = "DRONE_GITHUB_CLIENT_ID"     value = "${var.github_client_id}" },
      { name = "DRONE_GITHUB_CLIENT_SECRET" value = "${var.github_client_secret}" },
      { name = "DRONE_USER_CREATE"          value = "username:autoscaler,admin:true,machine:true,token:${random_string.autoscaler-token.result}" },
      { name = "DRONE_RPC_SECRET"           value = "${random_string.rpc-token.result}" },
      { name = "DRONE_SERVER_HOST"          value = "${var.drone_host}" },
      { name = "DRONE_SERVER_PROTO"         value = "${var.drone_proto}" },
      { name = "DRONE_TLS_AUTOCERT"         value = "${var.drone_tls_autocert}" },
    ]
  }

  volumes = [
    {
      name = "docker-sock"
      hostPath = {
        path = "/var/run/docker.sock"
      }
    },
    {
      name = "drone-data"
      gcePersistentDisk = {
        pdName = "drone-data"
        fsType = "ext4"
      }
    },
  ]

  restart_policy = "${var.restart_policy}"
}

resource "google_compute_address" "server" {
  name = "ipv4-address"
}

resource "google_compute_instance" "server" {
  project      = "${var.project_id}"
  name         = "${var.drone_server_name}"
  machine_type = "${var.drone_server_machine_type}"
  zone         = "${random_shuffle.zone.result[0]}"

  boot_disk {
    initialize_params {
      image = "${module.container-server.source_image}"
    }
  }

  attached_disk {
    source      = "${google_compute_disk.pd-server.self_link}"
    device_name = "drone-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${google_compute_address.server.address}"
    }
  }

  metadata = "${merge(var.additional_metadata, map("gce-container-declaration", module.container-server.metadata_value))}"

  labels {
    "container-vm" = "${module.container-server.vm_container_label}"
  }

  tags = [
    "${var.drone_server_name}",
    "http-server",
    "https-server"
  ]

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
