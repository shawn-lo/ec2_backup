#!/bin/sh

EC2_GROUP_ID="sg-568d582e"
KEY_NAME="asuralo-key-pair-useast1"
IMAGE_ID="ami-0187f76b"
IMAGE_REGION="us-east-1"
AVAIL_ZONE="us-east-1a"

SOURCE_DIR="."
TARGET_DIR="/dev/xvdf"
SOURCE_SIZE=0
TARGET_SIZE=0
TARGET_IP_ADDRESS=""

INSTANCE_ID=""
VOLUME_ID=""

# Environment 
#EC2_BACKUP_FLAGS_AWS=""

get_dir_size()
{
    #local SIZE_IN_M=$(sudo du -hsm $SOURCE_DIR | awk '{print $1}')
    local SIZE_IN_M=$(du -hsm $SOURCE_DIR | awk '{print $1}')

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

attach_volume()
{
    aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device $TARGET_DIR
}

create_instance()
{
    echo $EC2_BACKUP_FLAGS_AWS
    # if EC2_BACKUP_FLAGS has been set, it covers old settigns.
    INSTANCE_ID=$(aws ec2 run-instances --security-group-ids $EC2_GROUP_ID --key-name $KEY_NAME --instance-type m1.small $EC2_BACKUP_FLAGS_AWS --image-id $IMAGE_ID | \
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
    ssh -o StrictHostKeyChecking=no $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "ls -a"
    while [ "$?" != "0" ]
    do
        ssh -o StrictHostKeyChecking=no $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "ls -a"
    done
    #aws ec2 describe-instance-status --instance-id $INSTANCE_ID
}

mount_filesystem()
{
    ssh $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "sudo mkdir /home/fedora/backup_shell"
    sleep 1
    ssh $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "sudo mkfs -t ext3 /dev/xvdf"
    sleep 1
    ssh $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "sudo mount /dev/xvdf /home/fedora/backup_shell"
    sleep 1
    ssh $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "sudo chgrp fedora /home/fedora/backup_shell | sudo chown fedora /home/fedora/backup_shell -R"
    sleep 2
}

rsync_backup()
{
    rsync -avz -e ssh $EC2_BACKUP_FLAGS_SSH dead.letter fedora@$TARGET_IP_ADDRESS:/home/fedora/backup_shell
}
create_instance
# echo "[Create Instance] Done"
# create_ebs_volume
#INSTANCE_ID="i-0d37dc90"
#TARGET_IP_ADDRESS="54.172.162.153"
connect_instance
#create_ebs_volume
# sleep 10
# attach_volume
# sleep 10
# mount_filesystem
# rsync_backup

#echo "[Connect Instance] Successed"
# terminate_instance
#echo "[Terminate Instance] Done"
