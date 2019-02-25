module "container-autoscaler" {
  source = "github.com/terraform-google-modules/terraform-google-container-vm"
  version = "0.1.0"

  container = {
    image = "${var.drone_autoscaler_image}"

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
      {
        mountPath = "/root/.config/gcloud/application_default_credentials.json"
        name      = "google-service-account"
        readOnly  = "false"
      },
    ]
  # XXX Need firewall rule for 8080 for autoscaler
    env = [
      { name = "DRONE_SERVER_PROTO"   value = "http" },
      #{ name = "DRONE_TLS_AUTOCERT"   value = "${var.drone_tls_autocert}" },
      { name = "DRONE_SERVER_HOST"    value = "${var.drone_host}" },
      { name = "DRONE_SERVER_TOKEN"   value = "${random_string.autoscaler-token.result}" },
      { name = "DRONE_AGENT_TOKEN"    value = "${random_string.rpc-token.result}" },
      { name = "DRONE_GOOGLE_ZONE"    value = "${var.region}" },
      { name = "DRONE_GOOGLE_PROJECT" value = "${var.project_id}" },
      { name = "DRONE_GOOGLE_MACHINE_TYPE" value = "${var.drone_autoscaler_agent_machine_type}" },
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
    {
      name = "google-service-account"
      hostPath = {
        path = "/var/drone-gcp-service.account.json"
      }
    },
  ]

  restart_policy = "${var.restart_policy}"
}
#resource "google_compute_network" "default" {
#  name = "test-network"
#}
resource "google_compute_firewall" "default" {
  name    = "http-alternate"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags = ["http-alternate-server"]
}
resource "google_compute_firewall" "autoscaler-docker" {
  name = "default-allow-docker"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["2376"]
  }
  target_tags = ["allow-docker"]
}

resource "google_compute_address" "autoscaler" {
  name = "autoscaler"
}
resource "google_compute_instance" "autoscaler" {
  project      = "${var.project_id}"
  name         = "${var.drone_autoscaler_name}"
  machine_type = "${var.drone_autoscaler_machine_type}"
  zone         = "${random_shuffle.zone.result[0]}"

  boot_disk {
    initialize_params {
      image = "${module.container-autoscaler.source_image}"
    }
  }
  attached_disk {
    source      = "${google_compute_disk.pd-autoscaler.self_link}"
    device_name = "drone-data"
    mode        = "READ_WRITE"
  }

  #network_interface {
  #  subnetwork_project = "${var.subnetwork_project}"
  #  subnetwork         = "${var.subnetwork}"
  #  access_config      = {}
  #}
  network_interface {
    network = "default"
    access_config {
      nat_ip = "${google_compute_address.autoscaler.address}"
    }
  }

  metadata_startup_script = "echo ${google_service_account_key.autoscaler.private_key} | base64 -d > /var/drone-gcp-service.account.json"
  metadata = "${merge(var.additional_metadata, map("gce-container-declaration", module.container-autoscaler.metadata_value))}"

  labels {
    "container-vm" = "${module.container-autoscaler.vm_container_label}"
  }

  tags = [
    "${var.drone_autoscaler_name}",
    "http-server",
    "https-server",
    "http-alternate-server",
  ]

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_compute_disk" "pd-autoscaler" {
  project = "${var.project_id}"
  name    = "${var.drone_autoscaler_name}-data"
  type    = "pd-ssd"
  zone    = "${var.zone}"
  zone    = "${random_shuffle.zone.result[0]}"
  size    = "${var.drone_autoscaler_data_disk_size}"
}


# Autoscaler service account/key
resource "google_service_account" "autoscaler" {
  account_id   = "drone-autoscaler"
  display_name = "Drone Autoscaler Service Account"
}

resource "google_service_account_key" "autoscaler" {
  service_account_id = "${google_service_account.autoscaler.name}"
}

data "google_service_account_key" "autoscaler" {
  name = "${google_service_account_key.autoscaler.name}"
  public_key_type = "TYPE_X509_PEM_FILE"
}

## Autoscaler serivce account policy
# at the moment you'll need to add the appropriate permissions to the autoscaler service account
