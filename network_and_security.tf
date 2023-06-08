#### Create Network ####
resource "openstack_networking_network_v2" "private_network" {
  name             = "private_network"
  admin_state_up   = "true"
}
#### End Network block ####

#### Сreate subnet for private network ####
resource "openstack_networking_subnet_v2" "private_subnet" {
  name             = "private_subnet"
  network_id       = openstack_networking_network_v2.private_network.id
  cidr             = "${var.private_subnet}"
  dns_nameservers  = var.dns_ips
  ip_version       = 4
  enable_dhcp      = "false"
  depends_on = [openstack_networking_network_v2.private_network]
}                                                          
#### End subnet block ####

#### Allocate floating ip to the project ####
resource "openstack_networking_floatingip_v2" "instance_fip" {
  pool             = "FloatingIP Net"
}
#### End Allocate IP block ####

#### Getting external network id (subnet id) for router ####
data "openstack_networking_network_v2" "ext_network" {
  name = "FloatingIP Net"
}
data "openstack_networking_subnet_ids_v2" "ext_subnets" {
  network_id = data.openstack_networking_network_v2.ext_network.id
}
#### End of Getting external network id (subnet id) for router ####

#### Create Router ####
resource "openstack_networking_router_v2" "router" {
  name             = "router"
  external_network_id = data.openstack_networking_network_v2.ext_network.id
  admin_state_up   = "true"
  depends_on = [openstack_networking_network_v2.private_network]
}
#### End router block ####

#### add subnet to router to be able to assign floating ip to local network. ####
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.private_subnet.id}"
}
#### end block adding local subnet to router ####


