# Configure the Alicloud Provider and cn-shanghai region

provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

data "template_file" "user_data" {
  template = "${file("user-data.sh")}"
}

# create the new vpc,vswitch and security group in shanghai-g zone
resource "alicloud_vpc" "vpc" {
  name       = var.vpc_name
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_security_group" "group" {
  name        = var.security_group_name
  description = "security_group"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}


resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/16"
  availability_zone = var.availability_zone
} 

# Create the new ECS in Alicloud
resource "alicloud_instance" "instance" {
  availability_zone          = var.availability_zone
  security_groups            = alicloud_security_group.group.*.id
  instance_type              = var.instance_type
  system_disk_category       = var.system_disk_category
  image_id                   = var.image_id
  instance_name              = var.instance_name
  vswitch_id                 = alicloud_vswitch.vswitch.id
  internet_max_bandwidth_out = var.internet_max_bandwidth_out
  password                   = var.instance_password

  user_data = "${data.template_file.user_data.template}"
}
