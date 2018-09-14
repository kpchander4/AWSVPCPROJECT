# AWSVPCPurpose:
	This terraform code creates the following in AWS Singapore region

	1. VPCs and Subnets
		- a VPC with 10.0.0.0/16 network
		- a public subnet WEB with 10.0.0.0/24 network
		- a private subnet APP with 10.0.1.0/24 network
		- a private subnet DB with 10.0.2.0/24 network 

	2. Instances
		- an NAT01 instance to act as default gateway for instances in private subnets with associated eip
		- an MGMT01 instance to act as a jump host to access instances in private subnets with associated eip
		- an WEB01 instance to act as a web server with associated eip
		- an APP01 instance to act as a tomcat server hosting openCMS
		- an DB01 instance to act as DB server for openCMS

Assumptions:
	1. Works only in AWS Singapore region
	2. Uses t2.micro instances to spin up all instances except the NAT01 instance
	3. Uses Ubuntu 16.04 as the base OS
	4. AWS user has full EC2 and VPC permissions
	5. You have already created an key-pair in AWS EC2 consolea
	6. The 10.0.0.0/16 subnet is not used in existing VPCs. If yes, change it network settings in variables.tf accordingly

Inputs Needed:
	You need to add the following variables to the file terraform.tfvars
		1. AWS access_key - access key of aws user with appropriate permissions
		2. AWS secret_key - secret key of access key
		3. aws_key_path - path to the private key of the aws key-pair on your local machine
		4. aws_key_name - name of the aws key-pair

How to run the code:
	1. Unzip the files to a directory, you will see 4 files
		- terraform.tf (the code)
		- variables.tf (the variables defined)
		- terraform.tfvars (where you input your variables)
		- README (this file)
	2. Download and Install the terraform binary
	3. CD to the directory from 1.
	4. Run 'terraform plan' to show the changes that will be made
	5. Run 'terraform apply' to bring up the setup
	6. Run 'terraform destroy' to destroy the setup

How to ssh to the instances
	1. For WEB01 and MGMT01, ssh as ubuntu user with the aws private key to their respective EIP
	2. For DB01 and APP01, ssh as ubuntu user with the aws private key to the MGMT01 instance. Use 'Agent Forwarding' or add the private key to the MGMT01 user to gain access to DB01/APP01 isntances. This is for security purposes, ssh access from public should be denied from DB and APP subnets
