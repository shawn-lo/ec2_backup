#!/bin/sh

EC2_GROUP_ID="sg-568d582e"
KEY_NAME="asuralo-key-pair-useast1"
IMAGE_ID="ami-0187f76b"
IMAGE_REGION="us-east-1"
AVAIL_ZONE="us-east-1a"

SOURCE_DIR="."
SOURCE_SIZE=0
TARGET_SIZE=0
TARGET_IP_ADDRESS=""

INSTANCE_ID=""
VOLUME_ID=""

get_dir_size()
{
    local SIZE_IN_M=$(sudo du -hsm $SOURCE_DIR | awk '{print $1}')
    SOURCE_SIZE=`expr $SIZE_IN_M \\/ 1024`
    if [ "$SOURCE_SIZE" = "0" ]
    then
        SOURCE_SIZE=`expr $SOURCE_SIZE \\+ 1`
    fi
    TARGET_SIZE=`expr $SOURCE_SIZE \\* 2`
}

create_ebs_volume()
{
    get_dir_size
    VOLUME_ID=$(aws ec2 create-volume --size $TARGET_SIZE --region $IMAGE_REGION --availability-zone $AVAIL_ZONE --volume-type standard | \
        grep VolumeId | awk '{print $2}' | cut -d '"' -f 2)
    echo 'The Volume ID is'
    echo $VOLUME_ID
}

create_instance()
{
    INSTANCE_ID=$(aws ec2 run-instances --security-group-ids $EC2_GROUP_ID --key-name $KEY_NAME --image-id $IMAGE_ID | \
        grep InstanceId | awk '{print $2}' | cut -d '"' -f 2)
    echo 'The Instance ID is' 
    echo $INSTANCE_ID
    TARGET_IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | \
        grep PublicIpAddress | awk '{print $2}' | cut -d '"' -f 2)
    echo 'The server IP address is'
    echo $TARGET_IP_ADDRESS
}

terminate_instance()
{
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
}

connect_instance()
{
    ssh -o StrictHostKeyChecking=no fedora@$TARGET_IP_ADDRESS ls -a
    while [ "$?" != "0" ]
    do
        ssh -o StrictHostKeyChecking=no fedora@$TARGET_IP_ADDRESS ls -a
    done
    aws ec2 describe-instance-status --instance-id $INSTANCE_ID
}
create_instance
echo "[Create Instance] Done"
#create_ebs_volume
connect_instance
echo "[Connect Instance] Successed"
#terminate_instance
#echo "[Terminate Instance] Done"
