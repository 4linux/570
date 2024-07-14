provider "google" {
  credentials = "/home/suporte-gcp/.config/gcloud/legacy_credentials/EMAIL/adc.json"
  project     = "ID_PROJECT_OBSERVABILITY"
  region      = "us-central1"
}

resource "google_compute_firewall" "allow_graylog_server" {
  name    = "allow-graylog-server"
  network = "observability-network"

  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["graylog-server"]
}

resource "google_compute_firewall" "allow_kibana_server" {
  name    = "allow-kibana-server"
  network = "observability-network"

  allow {
    protocol = "tcp"
    ports    = ["5601"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kibana-server"]
}

resource "google_compute_address" "graylog_server_internal_ip" {
  name         = "graylog-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "observability-subnet"
}

resource "google_compute_address" "elk_server_internal_ip" {
  name         = "elk-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "observability-subnet"
}

resource "google_compute_address" "graylog_server_static_ip" {
  name   = "graylog-server-static-ip"
  region = "us-central1"
}

resource "google_compute_address" "elk_server_static_ip" {
  name   = "elk-server-static-ip"
  region = "us-central1"
}

resource "google_compute_instance" "graylog_server" {
  name         = "graylog-server"
  machine_type = "e2-standard-4"
  zone         = "us-central1-c"
  tags         = ["graylog-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = "observability-network"
    subnetwork = "observability-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.graylog_server_internal_ip.address
    }

    access_config {
      nat_ip = google_compute_address.graylog_server_static_ip.address
    }
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash

      # Clonar repositorio do curso
      git clone https://github.com/4linux/570.git
    EOF
  }
}

resource "google_compute_instance" "elk_server" {
  name         = "elk-server"
  machine_type = "e2-standard-4"
  zone         = "us-central1-c"
  tags         = ["kibana-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = "observability-network"
    subnetwork = "observability-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.elk_server_internal_ip.address
    }

    access_config {
      nat_ip = google_compute_address.elk_server_static_ip.address
    }
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash

      # Clonar repositorio do curso
      git clone https://github.com/4linux/570.git
    EOF
  }
}
