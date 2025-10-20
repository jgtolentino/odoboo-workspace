# terraform/main.tf - Infrastructure as Code for Odoo 18.0 on DigitalOcean

terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for Odoo installation"
  type        = string
}

variable "ssh_ip_allowlist" {
  description = "IP addresses allowed to SSH (CIDR notation)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_password" {
  description = "Odoo admin password"
  type        = string
  sensitive   = true
}

provider "digitalocean" {
  token = var.do_token
}

# SSH Key
data "digitalocean_ssh_keys" "existing" {}

resource "digitalocean_ssh_key" "odoo" {
  count      = length(data.digitalocean_ssh_keys.existing.ssh_keys) == 0 ? 1 : 0
  name       = "odoo-terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

locals {
  ssh_key_ids = length(data.digitalocean_ssh_keys.existing.ssh_keys) > 0 ? [
    data.digitalocean_ssh_keys.existing.ssh_keys[0].id
  ] : [digitalocean_ssh_key.odoo[0].id]
}

# VPC
resource "digitalocean_vpc" "odoo_vpc" {
  name     = "odoo-vpc"
  region   = "nyc3"
  ip_range = "10.0.0.0/16"
}

# Managed PostgreSQL Database
resource "digitalocean_database_cluster" "postgres" {
  name       = "odoo-postgres-cluster"
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-1gb"
  region     = "nyc3"
  node_count = 1

  private_network_uuid = digitalocean_vpc.odoo_vpc.id

  tags = ["odoo", "database", "production"]
}

# Database
resource "digitalocean_database_db" "odoo_db" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "odoo18"
}

# Database User
resource "digitalocean_database_user" "odoo_user" {
  cluster_id = digitalocean_database_cluster.postgres.id
  name       = "odoo"
}

# Firewall for database
resource "digitalocean_database_firewall" "postgres_fw" {
  cluster_id = digitalocean_database_cluster.postgres.id

  rule {
    type  = "droplet"
    value = digitalocean_droplet.odoo_server.id
  }
}

# Spaces (Object Storage) for file attachments
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "digitalocean_spaces_bucket" "odoo_files" {
  name   = "odoo-files-${random_id.bucket_suffix.hex}"
  region = "nyc3"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }
}

# Droplet for Odoo
resource "digitalocean_droplet" "odoo_server" {
  name     = "odoo18-server"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-22-04-x64"
  region   = "nyc3"
  vpc_uuid = digitalocean_vpc.odoo_vpc.id

  ssh_keys = local.ssh_key_ids

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    db_host     = digitalocean_database_cluster.postgres.private_host
    db_port     = digitalocean_database_cluster.postgres.port
    db_user     = digitalocean_database_user.odoo_user.name
    db_password = digitalocean_database_user.odoo_user.password
    db_name     = digitalocean_database_db.odoo_db.name
    admin_pass  = var.admin_password
  })

  tags = ["odoo", "production", "web-server"]
}

# Load Balancer
resource "digitalocean_loadbalancer" "odoo_lb" {
  name   = "odoo-lb"
  region = "nyc3"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 8069
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 8069
    target_protocol = "http"

    certificate_name = digitalocean_certificate.cert.name
  }

  healthcheck {
    port     = 8069
    protocol = "http"
    path     = "/web/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    unhealthy_threshold      = 3
    healthy_threshold        = 2
  }

  droplet_ids = [digitalocean_droplet.odoo_server.id]

  vpc_uuid = digitalocean_vpc.odoo_vpc.id
}

# SSL Certificate (Let's Encrypt)
resource "digitalocean_certificate" "cert" {
  name    = "odoo-cert"
  type    = "lets_encrypt"
  domains = [var.domain_name]
}

# Firewall
resource "digitalocean_firewall" "odoo_firewall" {
  name = "odoo-firewall"

  droplet_ids = [digitalocean_droplet.odoo_server.id]

  # SSH access
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.ssh_ip_allowlist
  }

  # HTTP access (from load balancer only)
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.odoo_lb.id]
  }

  # HTTPS access (from load balancer only)
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "443"
    source_load_balancer_uids = [digitalocean_loadbalancer.odoo_lb.id]
  }

  # Odoo HTTP (internal VPC only)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8069"
    source_addresses = [digitalocean_vpc.odoo_vpc.ip_range]
  }

  # Odoo longpolling (internal VPC only)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8072"
    source_addresses = [digitalocean_vpc.odoo_vpc.ip_range]
  }

  # Allow all outbound
  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Outputs
output "odoo_server_ip" {
  description = "Public IP address of Odoo server"
  value       = digitalocean_droplet.odoo_server.ipv4_address
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = digitalocean_loadbalancer.odoo_lb.ip
}

output "database_uri" {
  description = "PostgreSQL connection URI"
  value       = digitalocean_database_cluster.postgres.uri
  sensitive   = true
}

output "database_host" {
  description = "PostgreSQL private host"
  value       = digitalocean_database_cluster.postgres.private_host
}

output "database_port" {
  description = "PostgreSQL port"
  value       = digitalocean_database_cluster.postgres.port
}

output "spaces_bucket_name" {
  description = "Spaces bucket name for file storage"
  value       = digitalocean_spaces_bucket.odoo_files.name
}

output "spaces_endpoint" {
  description = "Spaces endpoint URL"
  value       = "https://${digitalocean_spaces_bucket.odoo_files.region}.digitaloceanspaces.com"
}
