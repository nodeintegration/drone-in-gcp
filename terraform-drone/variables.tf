# Common
variable "project_id"           { description = "The project ID to deploy resources into" }
variable "region"               { description = "The region to deploy all resources into" }
variable "restart_policy"       { description = "The docker container restart policy"     default = "Always" }
variable "additional_metadata" {
  type        = "map"
  description = "Additional metadata to attach to instances"
  default     = {}
}
variable "github_user_filter"   { description = "Comma seperated list of users/orgs to allow access" }
variable "github_client_id"     { description = "Github Oauth client id"}
variable "github_client_secret" { description = "Github Oauth client secret"}
variable "github_server"        { default = "https://github.com" description = "Github server" }

variable "drone_proto"          { default = "https" description = "Drone in http/https mode"}
variable "drone_host"           { description = "Drone FQDN" }
variable "drone_tls_autocert"   { default = "true"  description = "Drone TLS Auto cert (true|false)"}

# Server Area
variable "drone_server_image"          { default = "drone/drone:1.0.0-rc.5" }
variable "drone_server_name"           { default = "drone-server" }
variable "drone_server_data_disk_size" { default = 10 }
variable "drone_server_ports"          { default = ["80", "443" ] }
variable "drone_server_machine_type"   { default = "n1-standard-2" }

# Autoscaler area
variable "drone_autoscaler_name"               { default = "drone-autoscaler" }
variable "drone_autoscaler_image"              { default = "drone/autoscaler:1.0.0-rc.1" }
variable "drone_autoscaler_machine_type"       { default = "n1-standard-2" }
variable "drone_autoscaler_data_disk_size"     { default = 10 }
variable "drone_autoscaler_agent_machine_type" { default = "n1-standard-1" }
