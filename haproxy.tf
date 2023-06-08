#### Create security group for haproxy instance #####
resource "openstack_compute_secgroup_v2" "security_group_haproxy" {
  
  name             = "sg_haproxy"
  description      = "Security group for HAProxy server"
  
  ##### rule to accept http from any IP address #####
  rule {
    from_port      = "${var.ansible_haproxy_webserver_port}"
    to_port        = "${var.ansible_haproxy_webserver_port}"
    ip_protocol    = "${var.protocol_tcp}"
    cidr           = "${var.listen_all}"
  }
  ##### end of rule #####
  
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


#### create a port for private network interface of HAproxy instance ####
resource "openstack_networking_port_v2" "port_1" {
  name               = "port_1"
  network_id         = openstack_networking_network_v2.private_network.id
  admin_state_up     = "true"
  security_group_ids = [openstack_compute_secgroup_v2.security_group_haproxy.id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private_subnet.id
    ip_address = "${var.haproxy_private_ip}"
  }
}
#### create a port for private network ####

#### Create volume for haproxy_instance ####
resource "openstack_blockstorage_volume_v3" "volume_hap" {
  name             = "volume_hap"
  size             = var.volume_size
  image_id         = "${var.centos_7_image}"
  enable_online_resize = "true"
}
#### End Create volume block ####

#### Create a haproxy instanse ####
resource "openstack_compute_instance_v2" "haproxy_instance" {
  
  name             = "haproxy"
  flavor_name      = "${var.flavor_name}"
  key_pair         = openstack_compute_keypair_v2.ansible_keypair.name
  security_groups  = [openstack_compute_secgroup_v2.security_group_haproxy.name]
  config_drive     = true
              
  # dependencies
  depends_on = [
                openstack_networking_network_v2.private_network,
                openstack_blockstorage_volume_v3.volume_hap
  ]
  
  # provide server group to an instance      
  scheduler_hints {
    group = openstack_compute_servergroup_v2.server_group_haproxy.id
  }
  
  # provide private network to the instance
  network {
    uuid           = openstack_networking_network_v2.private_network.id
    port           = openstack_networking_port_v2.port_1.id
  }        
  
  # provide block device to and instance 
  block_device {
    uuid           = openstack_blockstorage_volume_v3.volume_hap.id
    boot_index     = 0
    source_type    = "volume"
    destination_type = "volume"
    delete_on_termination = false
  }
               
}
#### End Create Instans block ####

#### Assign floating IP ####
resource "openstack_compute_floatingip_associate_v2" "instance_fip_association" {
  floating_ip      = openstack_networking_floatingip_v2.instance_fip.address
  instance_id      = openstack_compute_instance_v2.haproxy_instance.id
                                                                                }
#### End Assign floadting IP block ####
resource "openstack_compute_servergroup_v2" "server_group_haproxy" {
  name     = "haproxy"
  policies = ["soft-anti-affinity"]
}