# terrafrom_loadbalancer

# Introduction
- Hello. It is my first project with Terraform-Openstack.

##  :beginner: About
The project creates 5 CentOS virtual machines (1 for haproxy, 3 for web servers, 1 for ansible control host).

Deployment and configuration of the instances is done by ansible control host.

Ansible roles are stored on s3 storage.

The load balancing is done on haproxy host.

The number of web-servers can vary depending on number of private IPs provided in variables.

Each web server has static html page containing welcome text with its hostname.

Two servers have floating IP: haproxy and ansible control. haproxy for getting the web-pages from public network. Ansible to connect from public netwrok using ssh private key and remote provisioning.

## :zap: Usage
Download the project and try :)

###  :electric_plug: Installation
- get access to openstack cloud and create a project.
- install terraform to your machine from  [here](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform).
- create a folder, downlaod this Project files to the folder and init terraform running:

```
$ terraform init

```

Configure variables of the prject. 

Please note that terraform.tfvars file has not been uploaded here.

```
$ terraform plan

```

If no errors accured, then try to apply:


```
$ terraform apply

```

### :notebook: Pre-Requisites
Pre-Requisites:
- Access to Openstack cloud
- Download Terraform
- Configure variables of the project


###  :file_folder: File Structure
File structure of the project:

```
.
├── scripts
│   └── user_data_script.sh
│   ansible_control.tf
├── files.tar.gz
│   haproxy.tf
│   main.tf
│   network_and_security.tf
│   variables.tf
│   webservers.tf
└── README.md
```

| No | File Name | Details 
|----|------------|-------|
| 1  | scripts | folder with user_data_script.sh
| 2  | user_data_script.sh | script that exports S3 variables for bash script to upload and download roles which are stored on S3 storage.
| 3  | ansible_control.tf | code to create ansibe_control instance
| 4  | files.tar.gz | files for provisioning
| 5  | haproxy.tf | code to create haproxy instance
| 6  | main.tf | code for provisioning and outputs
| 7  | network_and_security.tf | code for network infrastructure
| 8  | variables.tf | variables to fill in before applying project
| 9  | webservers.tf | code to create web-servers instance
| 10  | README.md | README