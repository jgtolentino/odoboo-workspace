# terraform/variables.tf - Variable definitions

variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for Odoo installation (e.g., odoo.example.com)"
  type        = string
}

variable "ssh_ip_allowlist" {
  description = "List of IP addresses allowed to SSH (CIDR notation)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "admin_password" {
  description = "Odoo admin master password"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet size for Odoo server"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "database_size" {
  description = "Database cluster size"
  type        = string
  default     = "db-s-1vcpu-1gb"
}
