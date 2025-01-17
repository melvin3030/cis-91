
variable "credentials_file" { 
  default = "../secrets/cis-91.key" 
}

variable "project" {
  default = "cis-91-terraform-325501"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region  = var.region
  zone    = var.zone 
  project = var.project
}

resource "google_compute_network" "lab11_vpc" {
  name = "cis91-lab11-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet01" {
  name          = "lab11-subnetwork01"
  ip_cidr_range = "10.17.0.0/21"
  region        = "us-central1"
  network       = google_compute_network.lab11_vpc.id
}

resource "google_compute_subnetwork" "subnet02" {
  name          = "lab11-subnetwork02"
  ip_cidr_range = "10.17.8.0/21"
  region        = "asia-southeast1"
  network       = google_compute_network.lab11_vpc.id
}

resource "google_compute_subnetwork" "subnet03" {
  name          = "lab11-subnetwork03"
  ip_cidr_range = "10.17.16.0/21"
  region        = "australia-southeast1"
  network       = google_compute_network.lab11_vpc.id
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.lab11_vpc.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}
