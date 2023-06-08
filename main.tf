##### Terraform Block #####
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.51.0"
    }
  }
}
##### Terraform Block end #####

##### Configure the OpenStack Provider #####
provider "openstack" {

 user_name   = "${var.user_name}"
 tenant_name = "${var.tenant_name}"
 password    = "${var.password}"
 domain_name = "${var.domain_name}"
 auth_url    = "${var.auth_url}"
 region      = "${var.region}"
}
##### End config block #####

##### Generate ansible-inventory file for ansible environment #####
##### better to use cloud dynamic inventory in cloud #####
resource "local_file" "ansible_inventory_file" {
  #content of inverntory file
  content  = <<EOT
[${openstack_compute_servergroup_v2.server_group_haproxy.name}]
${var.haproxy_private_ip}

[${openstack_compute_servergroup_v2.server_group_webservers.name}]
%{ for web_servers_addr in var.web_server_private_ips ~}
${web_servers_addr}
%{ endfor ~}

[${openstack_compute_servergroup_v2.server_group_ansible.name}]
${var.ansible_private_ip}
  EOT
  #filename of inventory
  filename = "${var.ansible_env}-inventory"
}
##### end #####

##### Generate haproxy ansible group variables file for ansible environment #####
resource "local_file" "ansible_haproxy_group_vars" {
  #content of group variables file
  content  = <<EOT
---
# Variables for the HAproxy configuration

# HAProxy supports "http" and "tcp". For SSL, SMTP, etc, use "tcp".
mode: ${var.ansible_haproxy_mode}

# Balancing Algorithms. Available options:
# roundrobin, source, leastconn, source, uri
balancing_alg: ${var.ansible_haproxy_balancing_alg}


# Port on which HAProxy should listen
webserver_port: ${var.ansible_haproxy_webserver_port}

# Location of haproxy configuration file
haproxy_config_file: ${var.ansible_haproxy_config_file}

  EOT
  #filename of inventory
  filename = "group_vars_haproxy.yml"
}
##### end #####

##### Generate web-servers ansible group variables file for ansible environment #####
resource "local_file" "ansible_webservers_group_vars" {
  #content of group variables 
  content  = <<EOT
---
# Variables for the web-servers configuration

# document_root value
httpd_document_root: ${var.ansible_web_servers_httpd_document_root}

# default http port
http_port: ${var.ansible_web_servers_http_port}

  EOT
  #filename of inventory
  filename = "group_vars_webservers.yml"
}
##### end #####

##### provisioning resources and start required services #####
resource "null_resource" "provision" {
# check dependencies
  depends_on = [
                 local_file.ansible_inventory_file,
                 local_file.ansible_haproxy_group_vars,
                 local_file.ansible_webservers_group_vars,
                 openstack_networking_floatingip_v2.instance_fip_ansible, 
                 openstack_compute_instance_v2.haproxy_instance, 
                 openstack_compute_instance_v2.ansible_instance, 
                 openstack_compute_floatingip_associate_v2.instance_fip_association_ansible
               ]
               
# create connection to ansible-control hosts floating ip using ssh keys
  connection {
    user = "centos"
    private_key = "${openstack_compute_keypair_v2.keypair.private_key}"
    host = "${openstack_networking_floatingip_v2.instance_fip_ansible.address}"
  }

##### copy archive to ansible instace #####
  provisioner "file" {
    source = "files.tar.gz"
    destination = "/home/centos/files.tar.gz"
  }
  ##### end file provisioner #####
  
  ##### copy group vars for haproxy instace #####
  provisioner "file" {
    source = "group_vars_haproxy.yml"
    destination = "/home/centos/group_vars_haproxy.yml"
  }
  ##### end file provisioner #####
  
  ##### copy group vars for webserver instaces #####
  provisioner "file" {
    source = "group_vars_webservers.yml"
    destination = "/home/centos/group_vars_webservers.yml"
  }
  ##### end file provisioner #####
  
  ##### provision ansible inventory file to staging environment #####
  provisioner "file" {
    source = "${var.ansible_env}-inventory"
    destination = "/home/centos/${var.ansible_env}-inventory"
  }
  ##### end file provisioner #####

##### provision services and configuration #####
  provisioner "remote-exec" {
  
     inline = [
         # add generated ssh keys of ansible control machine to user's home location
         # these keys can be used to connect to exactly ansible-control machine, 
         # other machines have another keys to allow ansible-control machine login to them using another key    
         "sudo echo \"${openstack_compute_keypair_v2.ansible_keypair.public_key}\"  > ~/.ssh/id_rsa.pub",
         "sudo chmod 644 ~/.ssh/id_rsa.pub",
         "sudo echo \"${openstack_compute_keypair_v2.ansible_keypair.private_key}\"  > ~/.ssh/id_rsa",
		 "sudo chmod 600 ~/.ssh/id_rsa",
         # add ssh keys to authorized_keys
		 "sudo cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys",
         # install epel-release repository to be able installing ansible and s3cmd with their dependencies
		 "sudo yum install epel-release -y",
         # install ansible
         "sudo yum install ansible -y",
         # install s3cmd
         "sudo yum install s3cmd -y",
         # unzip archive 
         "tar -xzvf /home/centos/files.tar.gz",
         # place requierd group variable files to their locations
         "mv /home/centos/group_vars_webservers.yml /home/centos/inventories/${var.ansible_env}/group_vars/webservers.yml",
         "mv /home/centos/group_vars_haproxy.yml /home/centos/inventories/${var.ansible_env}/group_vars/haproxy.yml",
         # configure s3cmd tool 
         "s3cmd --access_key=\"${var.s3_access_key}\" --secret_key=\"${var.s3_secret_key}\" --region=\"US\" --host=\"${var.s3_endpoint}\" --host-bucket=\"${var.s3_bucket_template}\" --dump-config 2>&1 | tee .s3cfg",    
         # create a s3 bucket to load there ansible roles (create an inventory of ansible roles)
         "echo \"CREATING S3 BUCKET...\"",
         "s3cmd mb s3://${var.s3_bucket_name} --access_key=\"${var.s3_access_key}\" --secret_key=\"${var.s3_secret_key}\"",
         # give executable permissions for files to upload and download ansible roles
         "sudo chmod +x /home/centos/scripts/*.sh",
         "echo \"STARTING UPLOAD ROLES TO S3\"",
         # upload role files to s3 storage
         "sh /home/centos/scripts/upload_roles_to_s3.sh",
         "echo \"FINISHED UPLOAD ROLES TO S3\"",
         # delete roles from ansible host machine to downlaod them again from s3 :D 
         # because condition is to store ansible roles in s3 storage
         "echo \"DELETING ROLES FROM LOCAL STORAGE\"",
         "rm -rf /home/centos/roles/*",
         # download required ansible roles from s3
         "echo \"DOWNLOADING ROLES FROM S3 STORAGE\"",
         "sh /home/centos/scripts/download_roles_from_s3.sh",
         # copy ansible inventory file to its place, according its environment type
         "echo \"COPYING ${var.ansible_env} ANSIBLE INVENTORY FILE TO ${var.ansible_env} INVENTORY DIRECTORY\"",
         "cp /home/centos/${var.ansible_env}-inventory /home/centos/inventories/${var.ansible_env}/hosts",
         # disable host_key_checking for ansible
         "sudo sed -i \"s/#host_key_checking = False/host_key_checking = False/g\" /etc/ansible/ansible.cfg",
         # run ansible playbooks
         "ansible-playbook -i inventories/${var.ansible_env}/hosts provision_all.yml"
         ]
  }
  ##### end provisioner #####
}
##### end resource #####

##### Haproxy instance floating IP Output #####
output "ansible_floating_ip_address" {
  value = openstack_networking_floatingip_v2.instance_fip_ansible.address
 
}
##### end of Haproxy instance floating IP Output #####

##### Haproxy instance floating IP Output #####
output "haproxy_floating_ip_address" {
  value = openstack_networking_floatingip_v2.instance_fip.address
 
}
##### end of Haproxy instance floating IP Output #####