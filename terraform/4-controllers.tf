############################
# K8s Control Pane instances
############################

resource "aws_instance" "controller" {
    count = "${var.number_of_controller}"
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.controller_instance_type}"

    iam_instance_profile = "${aws_iam_instance_profile.kubernetes.id}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 20 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"
    tags = "${merge(
    local.common_tags,
      map(
        "Owner", "${var.owner}",
        "Name", "controller-${count.index}",
        "ansibleFilter", "${var.ansibleFilter}",
        "ansibleNodeType", "controller",
        "ansibleNodeName", "controller.${count.index}"
      )
    )}"
}

resource "aws_instance" "controller_etcd" {
    count = "${var.number_of_controller_etcd}"
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.controller_instance_type}"

    iam_instance_profile = "${aws_iam_instance_profile.kubernetes.id}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 40 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"

    tags = "${merge(
    local.common_tags,
      map(
        "Owner", "${var.owner}",
        "Name", "controller-etcd-${count.index}",
        "ansibleFilter", "${var.ansibleFilter}",
        "ansibleNodeType", "controller.etcd",
        "ansibleNodeName", "controller.etcd.${count.index}"
      )
    )}"
}

###############################
## Kubernetes API Load Balancer
###############################


############
## Security
############

resource "aws_security_group" "kubernetes_api" {
  vpc_id = "${aws_vpc.kubernetes.id}"
  name = "kubernetes-api"

  # Allow inbound traffic to the port used by Kubernetes API HTTPS
  ingress {
    from_port = 6443
    to_port = 6443
    protocol = "TCP"
    cidr_blocks = ["${var.control_cidr}"]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.common_tags,
      map(
        "Name", "kubernetes-api",
        "Owner", "${var.owner}"
      )
  )}"
}

############
## Outputs
############


