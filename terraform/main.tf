resource "random_id" "example" {
  byte_length = 2
}

resource "google_compute_network" "example" {
  project = var.project_id
  name    = "example-${random_id.example.hex}"

  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "example_nl" {
  project = var.project_id
  network = google_compute_network.example.id
  region  = "europe-west4"
  name    = "example-${random_id.example.hex}-nl"

  ip_cidr_range = "10.0.0.0/24"

  private_ip_google_access = true
}


data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

resource "google_compute_firewall" "example_allow_iap_rdp" {
  project     = var.project_id
  network     = google_compute_network.example.name
  name        = "example-${random_id.example.hex}-allow-iap-rdp"
  description = "Allows RDP connections from IAP addresses to instances with tag 'allow-rdp-access'."

  priority = 65534

  target_tags = [
    "allow-rdp-access",
  ]

  source_ranges = data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
}