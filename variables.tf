variable "access_key" {}
variable "secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}

variable "region" {
  default = "ap-southeast-1"
}

variable "ami" {
    default = "ami-03221428e6676db69"
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "web_subnet_cidr" {
    description = "CIDR for the WEB Public Subnet"
    default = "10.0.0.0/24"
}

variable "app_subnet_cidr" {
    description = "CIDR for the APP Private Subnet"
    default = "10.0.1.0/24"
}

variable "db_subnet_cidr" {
    description = "CIDR for the DB Private Subnet"
    default = "10.0.2.0/24"
}
