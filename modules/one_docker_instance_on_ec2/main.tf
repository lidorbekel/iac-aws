locals {
    block_device_path = "/dev/sdh"

    user_data = <<EOF
#!/bin/bash
set -Eeuxo pipefail
# Filesystem code is adapted from:
# https://github.com/GSA/devsecops-example/blob/03067f68ee2765f8477ae84235f7faa1d2f2cb70/terraform/files/attach-data-volume.sh

DEVICE=${local.block_device_path}
DEST=${var.persistent_volume_mount_path}
devpath=$(readlink -f $DEVICE)

if [[ $(file -s $devpath) != *ext4* && -b $devpath ]]; then
    # Filesystem has not been created. Create it!
    mkfs -t ext4 $devpath
fi

# add to fstab if not present
if ! egrep "^$devpath" /etc/fstab; then
  echo "$devpath $DEST ext4 defaults,nofail,noatime,nodiratime,barrier=0,data=writeback 0 2" | tee -a /etc/fstab > /dev/null
fi
mkdir -p $DEST
mount $DEST
chown ec2-user:ec2-user $DEST
chmod 0755 $DEST

# Filesystem code is over

# Now we install docker and docker-compose.
# Adapted from:
# https://gist.github.com/npearce/6f3c7826c7499587f00957fee62f8ee9
yum update -y
amazon-linux-extras install docker
systemctl start docker.service
usermod -a -G docker ec2-user
chkconfig docker on
yum install -y python3-pip
python3 -m pip install docker-compose

# Put the docker-compose.yml file at the root of our persistent volume
cat > $DEST/docker-compose.yml <<-TEMPLATE
${var.docker_compose_str}
TEMPLATE

# Write the systemd service that manages us bringing up the service
cat > /etc/systemd/system/my_custom_service.service <<-TEMPLATE
[Unit]
Description=${var.description}
After=${var.systemd_after_stage}

[Service]
Type=simple
User=${var.user}
ExecStart=/usr/local/bin/docker-compose -f $DEST/docker-compose.yml up
Restart=on-failure

[Install]
WantedBy=multi-user.target
TEMPLATE
# Start the service.
systemctl start my_custom_service
    

#!/bin/bash
echo "Before SSM installation"
cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
echo "Finished SSM installation"
    
EOF
}


resource "aws_ebs_volume" "persistent" {
    availability_zone = aws_instance.this.availability_zone
    size = var.persistent_volume_size_gb
}

resource "aws_volume_attachment" "persistent" {
    device_name = local.block_device_path
    volume_id = aws_ebs_volume.persistent.id
    instance_id = aws_instance.this.id
}

resource "aws_iam_role" "myrole" {
  name = "lidor-project-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.myrole.name
  count      = "${length(var.iam_policy_arn)}"
  policy_arn = "${var.iam_policy_arn[count.index]}"
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_profile"
    role = aws_iam_role.myrole.name
}

resource "aws_instance" "this" {
    ami = "ami-0d71ea30463e0ff8d"
    availability_zone = var.availability_zone
    instance_type = var.instance_type
    key_name = var.key_name
    associate_public_ip_address = var.associate_public_ip_address
    vpc_security_group_ids = var.vpc_security_group_ids
    subnet_id = var.subnet_id
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    user_data = local.user_data
    tags = merge (
        {
            Name = var.name
        },
        var.tags
    )
}
