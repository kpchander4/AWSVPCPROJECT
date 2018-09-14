provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

/*
  Create VPC
*/
resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "TEST VPC"
    }
}

/*
  Create VPC IGW
*/
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}

/*
  NAT Instance for instances in private vpc to access internet
*/
resource "aws_security_group" "nat" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.app_subnet_cidr}","${var.db_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.app_subnet_cidr}","${var.db_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "NAT SG"
    }
}

resource "aws_instance" "nat" {
    ami = "ami-03221428e6676db69" 
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.ap-southeast-1a-web.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags {
        Name = "NAT01"
    }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
}

/*
  Public Subnet WEB
*/
resource "aws_subnet" "ap-southeast-1a-web" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.web_subnet_cidr}"
    availability_zone = "ap-southeast-1a"

    tags {
        Name = "WEB"
    }
}

resource "aws_route_table" "ap-southeast-1a-web" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags {
        Name = "WEB"
    }
}

resource "aws_route_table_association" "ap-southeast-1a-web" {
    subnet_id = "${aws_subnet.ap-southeast-1a-web.id}"
    route_table_id = "${aws_route_table.ap-southeast-1a-web.id}"
}

/*
  Private Subnet APP
*/
resource "aws_subnet" "ap-southeast-1a-app" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.app_subnet_cidr}"
    availability_zone = "ap-southeast-1a"

    tags {
        Name = "APP"
    }
}

resource "aws_route_table" "ap-southeast-1a-app" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags {
        Name = "APP"
    }
}

resource "aws_route_table_association" "ap-southeast-1a-app" {
    subnet_id = "${aws_subnet.ap-southeast-1a-app.id}"
    route_table_id = "${aws_route_table.ap-southeast-1a-app.id}"
}

/*
  Private Subnet DB
*/
resource "aws_subnet" "ap-southeast-1a-db" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.db_subnet_cidr}"
    availability_zone = "ap-southeast-1a"

    tags {
        Name = "DB"
    }
}

resource "aws_route_table" "ap-southeast-1a-db" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags {
        Name = "DB"
    }
}

resource "aws_route_table_association" "ap-southeast-1a-db" {
    subnet_id = "${aws_subnet.ap-southeast-1a-db.id}"
    route_table_id = "${aws_route_table.ap-southeast-1a-db.id}"
}

/*
  Web and Management Servers in public WEB subnet
*/
resource "aws_security_group" "web" {
    name = "vpc_web"
    description = "Allow incoming HTTP connections."

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 8009
        to_port = 8009
        protocol = "tcp"
        cidr_blocks = ["${var.app_subnet_cidr}"]
    }
    egress { 
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["${var.db_subnet_cidr}"]
    }
    egress { 
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.app_subnet_cidr}","${var.db_subnet_cidr}","${var.web_subnet_cidr}"]
    }
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "WEB SG"
    }
}

resource "aws_instance" "web01" {
    ami = "${var.ami}"
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.web.id}"]
    subnet_id = "${aws_subnet.ap-southeast-1a-web.id}"
    associate_public_ip_address = true
    source_dest_check = false


    tags {
        Name = "WEB01"
    }
}

resource "aws_eip" "web01" {
    instance = "${aws_instance.web01.id}"
    vpc = true
}

resource "aws_instance" "mgmt01" {
    ami = "${var.ami}"
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.web.id}"]
    subnet_id = "${aws_subnet.ap-southeast-1a-web.id}"
    associate_public_ip_address = true
    source_dest_check = false


    tags {
        Name = "MGMT01"
    }
}

resource "aws_eip" "mgmt01" {
    instance = "${aws_instance.mgmt01.id}"
    vpc = true
}

/*
  App Servers in private APP subnet
*/
resource "aws_security_group" "app" {
    name = "vpc_app"
    description = "Allow incoming app connections."

    ingress {
        from_port = 8009
        to_port = 8009
        protocol = "tcp"
        security_groups = ["${aws_security_group.web.id}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

	egress {
		from_port = 0
		to_port = 65535
		protocol = "tcp"
		cidr_blocks = ["${var.web_subnet_cidr}","${var.db_subnet_cidr}"]
	}
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "APP SG"
    }
}

resource "aws_instance" "app01" {
    ami = "${var.ami}"
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.app.id}"]
    subnet_id = "${aws_subnet.ap-southeast-1a-app.id}"
    source_dest_check = false

    tags {
        Name = "APP01"
    }
}

/*
  Database Servers in private DB subnet
*/
resource "aws_security_group" "db" {
    name = "vpc_db"
    description = "Allow incoming database connections."

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["${aws_security_group.app.id}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

   egress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["${var.app_subnet_cidr}"]
    }
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "DB SG"
    }
}

resource "aws_instance" "db01" {
    ami = "${var.ami}"
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.micro"
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.db.id}"]
    subnet_id = "${aws_subnet.ap-southeast-1a-db.id}"
    source_dest_check = false

    tags {
        Name = "DB01"
    }
}
