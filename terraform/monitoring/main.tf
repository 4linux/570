provider "google" {
  credentials = "/home/suporte-gcp/.config/gcloud/legacy_credentials/EMAIL/adc.json"
  project     = "ID_PROJECT_MONITORING"
  region      = "us-central1"
}

resource "google_compute_firewall" "allow_zabbix_server" {
  name    = "allow-zabbix-server"
  network = "monitoring-network"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["zabbix-server"]
}

resource "google_compute_firewall" "allow_grafana_server" {
  name    = "allow-grafana-server"
  network = "monitoring-network"

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["grafana-server"]
}

resource "google_compute_firewall" "allow_prometheus_server" {
  name    = "allow-prometheus-server"
  network = "monitoring-network"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["prometheus-server"]
}

resource "google_compute_firewall" "allow_alertmanager" {
  name    = "allow-alertmanager"
  network = "monitoring-network"

  allow {
    protocol = "tcp"
    ports    = ["9093"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["alertmanager"]
}

resource "google_compute_address" "zabbix_db_internal_ip" {
  name         = "zabbix-db-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "monitoring-subnet"
}

resource "google_compute_address" "zabbix_server_internal_ip" {
  name         = "zabbix-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "monitoring-subnet"
}

resource "google_compute_address" "prometheus_server_internal_ip" {
  name         = "prometheus-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "monitoring-subnet"
}

resource "google_compute_address" "zabbix_server_static_ip" {
  name   = "zabbix-server-static-ip"
  region = "us-central1"
}

resource "google_compute_address" "prometheus_server_static_ip" {
  name   = "prometheus-server-static-ip"
  region = "us-central1"
}

resource "google_compute_instance" "zabbix_db" {
  name         = "zabbix-db"
  machine_type = "e2-standard-2"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "monitoring-network"
    subnetwork = "monitoring-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.zabbix_db_internal_ip.address
    }
    access_config {}
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash

      # Clonar repositorio do curso
      git clone https://github.com/4linux/570.git
    EOF
  }
}

resource "google_compute_instance" "zabbix_server" {
  name         = "zabbix-server"
  machine_type = "e2-standard-4"
  zone         = "us-central1-c"
  tags         = ["zabbix-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "monitoring-network"
    subnetwork = "monitoring-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.zabbix_server_internal_ip.address
    }

    access_config {
      nat_ip = google_compute_address.zabbix_server_static_ip.address
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

resource "google_compute_instance" "prometheus_server" {
  name         = "prometheus-server"
  machine_type = "e2-standard-2"
  zone         = "us-central1-c"
  tags         = ["grafana-server", "prometheus-server", "alertmanager"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "monitoring-network"
    subnetwork = "monitoring-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.prometheus_server_internal_ip.address
    }

    access_config {
      nat_ip = google_compute_address.prometheus_server_static_ip.address
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
