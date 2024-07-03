provider "google" {
  credentials = "/home/suporte-gcp/.config/gcloud/legacy_credentials/EMAIL/adc.json"
  project     = "ID_PROJECT_DEFAULT"
  region      = "us-central1"
}

resource "google_compute_firewall" "allow_apache_server" {
  name    = "allow-apache-server"
  network = "app-network"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apache-server"]
}

resource "google_compute_address" "db_server_internal_ip" {
  name         = "db-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "app-subnet"
}

resource "google_compute_address" "web_server_internal_ip" {
  name         = "web-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "app-subnet"
}

resource "google_compute_address" "memcached_server_internal_ip" {
  name         = "memcached-server-internal-ip"
  region       = "us-central1"
  address_type = "INTERNAL"
  subnetwork   = "app-subnet"
}

resource "google_compute_address" "web_server_static_ip" {
  name   = "web-server-static-ip"
  region = "us-central1"
}

resource "google_compute_instance" "db_server" {
  name         = "db-server"
  machine_type = "e2-medium"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "app-network"
    subnetwork = "app-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.db_server_internal_ip.address
    }
    access_config {}
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      # Instalação do Docker
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh

      # Instalação do Docker Compose
      curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose

      # Clonar repositorio do curso
      git clone https://github.com/4linux/570.git

      # Inicia o container do banco de dados MySQL
      mkdir /opt/data
      docker-compose -f /570/compose/db-server/docker-compose.yml up -d
    EOF
  }
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-c"
  tags         = ["apache-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "app-network"
    subnetwork = "app-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.web_server_internal_ip.address
    }

    access_config {
      nat_ip = google_compute_address.web_server_static_ip.address
    }
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      # Instalação do Docker
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh

      # Instalação do Docker Compose
      curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose

      # Clonar repositorio do curso
      git clone https://github.com/4linux/570.git

      # Inicia o container do servidor web com suporte a PHP
      docker-compose -f /570/compose/web-server/docker-compose.yml up -d
    EOF
  }
}

resource "google_compute_instance" "memcached_server" {
  name         = "memcached-server"
  machine_type = "e2-medium"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = "30"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "app-network"
    subnetwork = "app-subnet"

    alias_ip_range {
      ip_cidr_range = google_compute_address.memcached_server_internal_ip.address
    }
    access_config {}
  }

  metadata = {
    startup-script = <<-EOF
      #! /bin/bash
      # Instalação do Docker
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh

      # Instalação do Docker Compose
      curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose

      # Clonar repositorio do curso
      git clone https://github.com/4linux/570.git

      # Inicia o container do servidor de cache
      docker-compose -f /570/compose/memcached-server/docker-compose.yml up -d
    EOF
  }
}
