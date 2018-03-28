
variable "aws_region" {
  description = "Region for the VPC"
}

variable "access_key" {}

variable "secret_key" {}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default = "10.0.1.0/24"
}

variable "ami" {
  description = "CentOS Linux 7.4 AMI"
}

variable "ssh_key_pub" {
  description = "SSH Public Key"
  default = "./.ssh/id_rsa.pub"
}

variable "ssh_key" {
	default = "./.ssh/id_rsa"
}

#AWS as our provider
provider "aws" {
	version 		= "~> 1.10"
  region 			= "${var.aws_region}"
	access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
}

# Define our VPC
resource "aws_vpc" "clm_vpc" {
  cidr_block 						= "${var.vpc_cidr}"
  enable_dns_hostnames	= true
  tags {
    Name = "clm_vpc"
  }
}

# Define the public subnet
resource "aws_subnet" "clm_public_subnet" {
  vpc_id									= "${aws_vpc.clm_vpc.id}"
  cidr_block							= "${var.public_subnet_cidr}"
	map_public_ip_on_launch	= true 
  tags {
    Name = "clm_public_subnet"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.clm_vpc.id}"
  tags {
    Name = "clm_igw"
  }
}

# Define the route table
resource "aws_route_table" "clm_internet_gw_rt" {
  vpc_id = "${aws_vpc.clm_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "clm_internet_gw_rt_assoc" {
  subnet_id				= "${aws_subnet.clm_public_subnet.id}"
  route_table_id	= "${aws_route_table.clm_internet_gw_rt.id}"
}

# Define the security group for public subnet
resource "aws_security_group" "clm_security_grp" {
	vpc_id	= "${aws_vpc.clm_vpc.id}"
	name		= "clm_secutiry_grp"
  
	ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
	tags {
		Name = "clm_secutiry_grp"
	}
}

# Define SSH key pair for our instances
resource "aws_key_pair" "clm_deployer_key" {
  public_key = "${file("${var.ssh_key_pub}")}"
}

resource "aws_eip" "clm_eip" {
  instance = "${aws_instance.clm.id}"
  vpc      = true
}


# Define webserver inside the public subnet
resource "aws_instance" "clm" {
	ami											= "${var.ami}"
	instance_type						= "t2.micro"
	key_name								= "${aws_key_pair.clm_deployer_key.id}"
  subnet_id								= "${aws_subnet.clm_public_subnet.id}"
	vpc_security_group_ids	= ["${aws_security_group.clm_security_grp.id}"]

  tags {
    Name = "clm_client"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
      "sudo yum update -y",
      "sudo yum install iperf3 python34 python34-pip git vim -y",
			"sudo mkdir -p /opt/projects/clm && sudo chmod 777 /opt/projects/clm",
			"sudo echo region=${var.aws_region} >> /opt/projects/clm/attributes",
			"sudo echo provider=aws >> /opt/projects/clm/attributes"
    ]
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${var.ssh_key}")}"
    }
  }

  provisioner "file" {
    source      = "provision/meter_client"
    destination = "/opt/projects/clm"
  	connection {
    	type     = "ssh"
    	user     = "centos"
    	private_key = "${file("${var.ssh_key}")}"
  	}
  }
	
  provisioner "remote-exec" {
    inline = [
      "cd /opt/projects/clm/meter_client && sudo pip3 install -r requirements.txt",
      #"nohup sudo python3 /opt/projects/clm/meter_client/iperf3_server.py &",
			"sudo cp /opt/projects/clm/meter_client/iperf3_sched.service /lib/systemd/system/iperf3_sched.service",
			"sudo systemctl enable iperf3_sched.service && sudo systemctl start iperf3_sched.service",
			"sudo cp /opt/projects/clm/meter_client/iperf3_server.service /lib/systemd/system/iperf3_server.service",
			"sudo systemctl enable iperf3_server.service && sudo systemctl start iperf3_server.service",
			"sudo sleep 1"
    ]
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${var.ssh_key}")}"
    }
  }
}






