#### create a server group ####
resource "openstack_compute_servergroup_v2" "server_group_webservers" {
  name     = "webservers"
  policies = ["soft-anti-affinity"]
}
#### end of server group ####

#### create private network ports for instances #### 
resource "openstack_networking_port_v2" "wport_" {

  count              = "${length(var.web_server_private_ips)}"
  name               = "wport_${count.index}"
  network_id         = openstack_networking_network_v2.private_network.id
  admin_state_up     = "true"
  security_group_ids = [openstack_compute_secgroup_v2.security_group_web.id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private_subnet.id
    ip_address = var.web_server_private_ips[count.index]
  }
}
#### end of network ports ####

#### Create security group for webservers #####
resource "openstack_compute_secgroup_v2" "security_group_web" {

  name             = "sg_webservers"
  description      = "Security group for Web-servers server, open all icmp, and ssh and 80 port"
  
  #### rule to accept http_port from private network ####
  rule {
    from_port      = "${var.ansible_web_servers_http_port}"
    to_port        = "${var.ansible_web_servers_http_port}"
    ip_protocol    = "${var.protocol_tcp}"
    cidr           = "${var.private_subnet}"
  }
  #### end of rule ####
  
  ##### rule to accept ssh only from private network #####
  rule {
    from_port      = "${var.ssh_port}"
    to_port        = "${var.ssh_port}"
    ip_protocol    = "${var.protocol_tcp}"
    cidr           = "${var.private_subnet}"
  }
  ##### end of rule  #####
  
}
#### End security group block ####

#### create webservers instances ####
resource "openstack_compute_instance_v2" "web-servers" {
  # number of instances to create, depends of number of private ips user provided in variables
  count            = "${length(var.web_server_private_ips)}" 
  # create instance names with prefix "VM-"
  name             = "VM-${count.index+1}"
  flavor_name      = "${var.flavor_name}"
  key_pair         = openstack_compute_keypair_v2.ansible_keypair.name
  security_groups  = [openstack_compute_secgroup_v2.security_group_web.name]
  config_drive     = true

  depends_on = [ openstack_compute_secgroup_v2.security_group_web,
                openstack_networking_network_v2.private_network
             ]
  ##### assign server group to the instances #### 
  scheduler_hints {
    group = openstack_compute_servergroup_v2.server_group_webservers.id
  }
  #### end of server group assignign ####

  ##### provide private network for instances ####
  network {
    uuid        =  openstack_networking_network_v2.private_network.id
    port        =  openstack_networking_port_v2.wport_.*.id["${count.index}"]
  }
  #### end of network ####
  
  #### assign block device to the instances ####
  block_device {
    uuid           = var.centos_7_image
    boot_index     = 0
    source_type    = "image"
    volume_size    = var.volume_size
    destination_type = "volume"
    delete_on_termination = false
  }
  #### end of block ####
}