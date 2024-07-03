provider "google" {
  credentials = "/home/suporte-gcp/.config/gcloud/legacy_credentials/EMAIL/adc.json"
  region      = "us-central1"
}

resource "google_compute_network" "app_network" {
  name                    = "app-network"
  project                 = "ID_PROJECT_DEFAULT"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "app_subnet" {
  name                     = "app-subnet"
  ip_cidr_range            = "10.1.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.app_network.id
  project                  = "ID_PROJECT_DEFAULT"
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_route" "app_route" {
  name              = "app-route"
  network           = google_compute_network.app_network.id
  dest_range        = "0.0.0.0/0"
  next_hop_gateway  = "default-internet-gateway"
  project           = "ID_PROJECT_DEFAULT"
  depends_on        = [google_compute_subnetwork.app_subnet]
}

resource "google_compute_router" "app_router" {
  name     = "app-router"
  network  = google_compute_network.app_network.id
  region   = "us-central1"
  project  = "ID_PROJECT_DEFAULT"
  depends_on = [google_compute_subnetwork.app_subnet]
}

resource "google_compute_router_nat" "app_nat" {
  name                               = "app-nat"
  router                             = google_compute_router.app_router.name
  region                             = "us-central1"
  project                            = "ID_PROJECT_DEFAULT"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_router.app_router]
}

resource "google_compute_firewall" "app_network_allow_internal" {
  name    = "app-network-allow-internal"
  network = google_compute_network.app_network.self_link
  project = "ID_PROJECT_DEFAULT"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.1.0.0/24"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "google_compute_firewall" "app_network_allow_ssh" {
  name    = "app-network-allow-ssh"
  network = google_compute_network.app_network.self_link
  project = "ID_PROJECT_DEFAULT"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "google_compute_network" "monitoring_network" {
  name                    = "monitoring-network"
  project                 = "ID_PROJECT_MONITORING"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "monitoring_subnet" {
  name                     = "monitoring-subnet"
  ip_cidr_range            = "10.2.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.monitoring_network.id
  project                  = "ID_PROJECT_MONITORING"
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_route" "monitoring_route" {
  name              = "monitoring-route"
  network           = google_compute_network.monitoring_network.id
  dest_range        = "0.0.0.0/0"
  next_hop_gateway  = "default-internet-gateway"
  project           = "ID_PROJECT_MONITORING"
  depends_on        = [google_compute_subnetwork.monitoring_subnet]
}

resource "google_compute_router" "monitoring_router" {
  name     = "monitoring-router"
  network  = google_compute_network.monitoring_network.id
  region   = "us-central1"
  project  = "ID_PROJECT_MONITORING"
  depends_on = [google_compute_subnetwork.monitoring_subnet]
}

resource "google_compute_router_nat" "monitoring_nat" {
  name                               = "monitoring-nat"
  router                             = google_compute_router.monitoring_router.name
  region                             = "us-central1"
  project                            = "ID_PROJECT_MONITORING"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_router.monitoring_router]
}

resource "google_compute_firewall" "monitoring_network_allow_internal" {
  name    = "monitoring-network-allow-internal"
  network = google_compute_network.monitoring_network.self_link
  project = "ID_PROJECT_MONITORING"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.1.0.0/24", "10.2.0.0/24", "10.3.0.0/24"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "google_compute_firewall" "monitoring_network_allow_ssh" {
  name    = "monitoring-network-allow-ssh"
  network = google_compute_network.monitoring_network.self_link
  project = "ID_PROJECT_MONITORING"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "google_compute_network" "observability_network" {
  name                    = "observability-network"
  project                 = "ID_PROJECT_OBSERVABILITY"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "observability_subnet" {
  name                     = "observability-subnet"
  ip_cidr_range            = "10.3.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.observability_network.id
  project                  = "ID_PROJECT_OBSERVABILITY"
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_route" "observability_route" {
  name              = "observability-route"
  network           = google_compute_network.observability_network.id
  dest_range        = "0.0.0.0/0"
  next_hop_gateway  = "default-internet-gateway"
  project           = "ID_PROJECT_OBSERVABILITY"
  depends_on        = [google_compute_subnetwork.observability_subnet]
}

resource "google_compute_router" "observability_router" {
  name     = "observability-router"
  network  = google_compute_network.observability_network.id
  region   = "us-central1"
  project  = "ID_PROJECT_OBSERVABILITY"
  depends_on = [google_compute_subnetwork.observability_subnet]
}

resource "google_compute_router_nat" "observability_nat" {
  name                               = "observability-nat"
  router                             = google_compute_router.observability_router.name
  region                             = "us-central1"
  project                            = "ID_PROJECT_OBSERVABILITY"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_router.observability_router]
}

resource "google_compute_firewall" "observability_network_allow_internal" {
  name    = "observability-network-allow-internal"
  network = google_compute_network.observability_network.self_link
  project = "ID_PROJECT_OBSERVABILITY"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.1.0.0/24", "10.2.0.0/24", "10.3.0.0/24"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "google_compute_firewall" "observability_network_allow_ssh" {
  name    = "observability-network-allow-ssh"
  network = google_compute_network.observability_network.self_link
  project = "ID_PROJECT_OBSERVABILITY"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"
  priority      = 65534
}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "google_compute_network_peering" "app_monitoring_peering" {
  name         = "app-monitoring-peering"
  network      = google_compute_network.app_network.id
  peer_network = google_compute_network.monitoring_network.id
  depends_on   = [google_compute_network.app_network, google_compute_network.monitoring_network]
}

resource "google_compute_network_peering" "monitoring_app_peering" {
  name         = "monitoring-app-peering"
  network      = google_compute_network.monitoring_network.id
  peer_network = google_compute_network.app_network.id
  depends_on   = [google_compute_network.app_network, google_compute_network.monitoring_network]
}

resource "google_compute_network_peering" "app_observability_peering" {
  name         = "app-observability-peering"
  network      = google_compute_network.app_network.id
  peer_network = google_compute_network.observability_network.id
  depends_on   = [google_compute_network.app_network, google_compute_network.observability_network]
}

resource "google_compute_network_peering" "observability_app_peering" {
  name         = "observability-app-peering"
  network      = google_compute_network.observability_network.id
  peer_network = google_compute_network.app_network.id
  depends_on   = [google_compute_network.app_network, google_compute_network.observability_network]
}
