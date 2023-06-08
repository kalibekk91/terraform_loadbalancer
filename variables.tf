#########################################
############### varibles ################
#########################################

##### variables for project variables #####
variable "auth_url" {}

variable "region" {}

variable "user_name" {
    default = ""
	description = "username for openstack project"
	# make it hidden on output
	sensitive=true
}

variable "tenant_name" {
    default = ""
	description = "tenant_name for openstack project"
	# make it hidden on output
	sensitive=true
}

variable "password" {
    default = ""
	description = "password for openstack project"
	# make it hidden on output
	sensitive=true
}

variable "domain_name" {
    default = "Default"
	description = "domain_name for openstack project"
}
#### end of project variables ####


#### selected CentOS image_id ####
variable "centos_7_image" {
  default = ""
  description = "CentOS image"
}
#### end CentOS image_id ####

###### netwrok variables #####
variable "private_subnet" {
   default = ""
}

variable "haproxy_private_ip" {
   default = ""
}

variable "web_server_private_ips" {
  type        = list(string)
  default     = []
  description = "all fixed private ips of web-servers separated by comma, please note that number of IPs determines number of instances of web-servers"
}

variable "ansible_private_ip" {
   default = "10.10.0.14"
}

variable "dns_ips" {
  type    = list(string)
  default = []
  description = "all ips of dns-servers separated by comma"
}

variable "listen_all" {
   default = "0.0.0.0/0"
}

variable "ssh_port" {
   default     = "22"
   description = "port for ssh"
}

variable "protocol_tcp" {
   default = "tcp"
}
##### end of network variables ######

##### valume size for all instances #####
variable "volume_size" {
   default  = ""
   description = "volume size in GB"
}
##### end #####

###### flavor_name for all instances #####
variable "flavor_name" {
    default = ""
	description = "flavor_name for all instances"
}
#### end of flavor_name ####

#### S3 storage variables ####
variable "s3_access_key" {
    default = ""
	description = "access key for s3 storage"
	# make it hidden on output
	sensitive=true
}

variable "s3_secret_key" {
    default = ""
	description = "access key for s3 storage"
	# make it hidden on output
	sensitive=true
}

variable "s3_bucket_name" {
    default = ""
	description = "access key for s3 storage"
}

variable "s3_endpoint" {
    default = ""
	description = "s3 endpoint to upload and download roles"
}

variable "s3_bucket_template" {
    default = ""
	description = "s3 bucket template to upload and download roles"
}

#### end of S3 storage variables ####

#### ansible variables #####
variable "ansible_haproxy_mode" {
    default = ""
	description = "haproxy mode variable"
}

variable "ansible_haproxy_balancing_alg" {
    default = ""
	description = "haproxy balacing algorithm variable"
}

variable "ansible_haproxy_webserver_port" {
    default = ""
	description = "haproxy web server port to listen"
}

variable "ansible_haproxy_config_file" {
    default = ""
	description = "haproxy config file location variable"
}

variable "ansible_web_servers_httpd_document_root" {
    default = ""
	description = "web-servers httpd_document_root directory location variable"
}

variable "ansible_web_servers_http_port" {
    default = ""
	description = "web-servers http_port variable"
}

variable "ansible_env" {
    default = ""
	description = "ansible environment: production or staging"
}
#### end of ansible variables #####

