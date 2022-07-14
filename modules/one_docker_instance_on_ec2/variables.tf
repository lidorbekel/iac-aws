variable "name" {
    description = "Name to be used on all resources"
    type = string
}

variable "description" {
    description = "Description of the service for systemd"
    type = string
    default = ""
}

variable "availability_zone" {
    default = ""
    description = "The availability zone for both the AWS instance and the EBS volume."
    type = string
}

variable "systemd_after_stage" {
    description = "When to run our container. This usually does not need to change."
    type = string
    default = "network.target"
}

variable "user" {
    description = "What user to run as. You will need to run as root to use one of the lower ports."
    type = string
    default = "root"
}

variable "tags" {
    description = "Tags to put on the EC2 instance"
    type = map(string)
    default = {}
}

variable "key_name" {
    description = "Name of the SSH key to log in with"
    type = string
}

variable "instance_type" {
    description = "The default AWS instance size to run these containers on"
    type = string
}

variable "docker_compose_str" {
    description = "The entire docker compose file to write."
    type = string
}

variable "subnet_id" {
    description = "The VPC subnet to launch the instance in"
    type = string
}

variable "vpc_security_group_ids" {
    description = "The security groups that the instance should have"
    type = list(string)
    default = []
}

variable "iam_instance_profile" {
    description = "The name of the IAM instance profile to give to the EC2 instance"
    type = string
    default = ""
}

variable "associate_public_ip_address" {
    description = "Whether to associate a public IP address in the VPC"
    type = bool
    default = false
}

variable "persistent_volume_size_gb" {
    description = "The size of the volume mounted"
    type = number
}

variable "persistent_volume_mount_path" {
    description = "Where on the filesystem to mount our persistent volume"
    type = string
    default = "/persistent"
}

variable "iam_policy_arn" {
  description = "IAM Policy to be attached to role"
  type = list(string)
  default = ["arn:aws:iam::aws:policy/AmazonSSMFullAccess", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess","arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicFullAccess"]
}