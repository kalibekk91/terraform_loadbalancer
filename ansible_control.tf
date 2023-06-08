#### generate SSH key to connect to ansible-control machine using floating_ip ####
resource "openstack_compute_keypair_v2" "keypair" {
  name             = "keypair"
}
#### end keypair ####

#### generate ssh keypair to be able to login with them to managed nodes ####
resource "openstack_compute_keypair_v2" "ansible_keypair" {
  name = "ansible_keypair"
}
#### end keypair ####

#### create a server group for ansible ####
resource "openstack_compute_servergroup_v2" "server_group_ansible" {
  name     = "ansible"
  policies = ["soft-anti-affinity"]
}
#### end of server group creation block ####

#### Allocate floating ip to the ansible control host to be able to connect and execute remote-exec provisioner ####
resource "openstack_networking_floatingip_v2" "instance_fip_ansible" {
  pool             = "FloatingIP Net"
}
#### End Allocate IP block ####

#### Assign floating IP ####
resource "openstack_compute_floatingip_associate_v2" "instance_fip_association_ansible" {
  floating_ip      = openstack_networking_floatingip_v2.instance_fip_ansible.address
  instance_id      = openstack_compute_instance_v2.ansible_instance.id
}
#### End Assign floating IP block ####

#### Create security group #####
resource "openstack_compute_secgroup_v2" "security_group_ansible" {
  name             = "security_group_ansible"
  description      = "Security group for ansbile control server, open all icmp, and ssh"
  
  ##### rule to accept ssh from any ip #####
  rule {
    from_port      = "${var.ssh_port}"
    to_port        = "${var.ssh_port}"
    ip_protocol    = "${var.protocol_tcp}"
    cidr           = "${var.listen_all}"
  }
  ##### end of rule  #####
  
  ##### rule to accept icmp only from private network #####
  rule {
    from_port      = -1
    to_port        = -1
    ip_protocol    = "icmp"
    cidr           = "${var.private_subnet}"
  }   
  ##### end of rule  #####  
}
#### End security group block ####

#### create a port for private network interface of ansible instance ####
resource "openstack_networking_port_v2" "aport_1" {
  name               = "aport_1"
  network_id         = openstack_networking_network_v2.private_network.id
  admin_state_up     = "true"
  security_group_ids = [openstack_compute_secgroup_v2.security_group_ansible.id]

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private_subnet.id
    ip_address = var.ansible_private_ip
  }
}
#### create a port for private network ####

#### Create volume for haproxy_instance ####
resource "openstack_blockstorage_volume_v3" "volume_ansible" {
  name             = "volume_ansible"
  size             = var.volume_size
  image_id         = var.centos_7_image
  enable_online_resize = "true" 
}
#### End Create volume block ####

#### Create ansible control Instanse ####
resource "openstack_compute_instance_v2" "ansible_instance" {
  name             = "ansible_control"
  flavor_name      = "${var.flavor_name}"
  key_pair         = openstack_compute_keypair_v2.keypair.name
  security_groups  = [openstack_compute_secgroup_v2.security_group_ansible.name]
  config_drive     = true
   
  # dependecies   
  depends_on = [
                openstack_networking_network_v2.private_network,
                openstack_blockstorage_volume_v3.volume_ansible
  ]
  
  # provide s3 credentials to be able execute them on bash scripts to upload and download ansible roles
  user_data = "${templatefile("scripts/user_data_script.sh", {
    TF_VAR_S3_ACCESS_KEY="${var.s3_access_key}"
    TF_VAR_S3_SECRET_KEY="${var.s3_secret_key}"
	TF_VAR_S3_BUCKET_NAME="${var.s3_bucket_name}"
  })}"
  
  # assign server group to instance
  scheduler_hints {
    group = openstack_compute_servergroup_v2.server_group_ansible.id
  }
  
  # assign private network
  network {
    uuid           = openstack_networking_network_v2.private_network.id
    port           = openstack_networking_port_v2.aport_1.id
  }        

  # add block device    
  block_device {
    uuid           = openstack_blockstorage_volume_v3.volume_ansible.id
    boot_index     = 0
    source_type    = "volume"
    destination_type = "volume"
    delete_on_termination = false
  }

}
#### End Create Instans block ####