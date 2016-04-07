#!/bin/sh

EC2_GROUP_ID="sg-568d582e"
KEY_NAME="asuralo-key-pair-useast1"
IMAGE_ID="ami-0187f76b"

INSTANCE_ID=""

#create_ebs_volume()
#{
#}

create_instance()
{
    INSTANCE_ID=$(aws ec2 run-instances --security-group-ids $EC2_GROUP_ID --key-name $KEY_NAME --image-id $IMAGE_ID | \
        grep InstanceId | awk '{print $2}' | cut -d '"' -f 2)
    echo 'The Instance ID is' 
    echo $INSTANCE_ID
}

#terminate_instance()
#{
#}
create_instance
