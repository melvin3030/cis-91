
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

resource "google_service_account" "dokuwiki-service-account" {
  account_id   = "dokuwiki-service-account"
  display_name = "dokuwiki-service-account"
  description = "Service account for dokuwiki"
}

resource "google_project_iam_member" "project_member" {
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dokuwiki-service-account.email}"
}

resource "google_compute_network" "vpc_network" {
  name = "cis91-network"
}

resource "google_compute_disk" "data-disk" {
  name  = "data-disk"
  type  = "pd-standard"
  size = 100
  zone  = var.zone
}

resource "google_storage_bucket" "backup" {
  name = "dokuwiki-melvin-cis91-backup"
  location = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
        age = 60
    }
    action {
        type = "Delete"
    }
  }  
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  attached_disk {
    source = google_compute_disk.data-disk.name
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  service_account {
    email  = google_service_account.dokuwiki-service-account.email
    scopes = ["cloud-platform"]
  }  
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_monitoring_uptime_check_config" "http" {
  display_name = "dokuwiki-uptime-check"
  timeout = "60s"
  period = "60s"    
  http_check {
    path = "/doku.php"
    port = "80"
    #period = "60"    
  }

  monitored_resource {
    type = "gce_instance"
    labels = {
      project_id = var.project
      instance_id = google_compute_instance.vm_instance.instance_id
      zone = var.zone
    }
  }
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

