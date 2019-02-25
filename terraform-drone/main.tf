data "google_compute_zones" "available" {
  project = "${var.project_id}"
  region  = "${var.region}"
}

resource "random_shuffle" "zone" {
  input        = ["${data.google_compute_zones.available.names}"]
  result_count = 1
}
resource "random_string" "autoscaler-token" {
  length = 32
  special = false
}
resource "random_string" "rpc-token" {
  length = 32
  special = false
}
resource "random_string" "database-password" {
  length = 16
  special = false
}
