#!/bin/sh

EC2_GROUP_ID="sg-568d582e"
KEY_NAME="asuralo-key-pair-useast1"
IMAGE_ID="ami-0187f76b"
IMAGE_REGION="us-east-1"
AVAIL_ZONE="us-east-1a"

SOURCE_DIR=" "
TARGET_DIR="/dev/xvdf"
SOURCE_SIZE=0
TARGET_SIZE=0
TARGET_IP_ADDRESS=""

INSTANCE_ID=""
VOLUME_ID="1"

BACKUP_METHOD="dd"

get_dir_size()
{
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
    #echo 'The Volume ID is'
    #echo $VOLUME_ID
}

attach_volume()
{
    aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device $TARGET_DIR 1>&2
}

create_instance()
{
    #echo $EC2_BACKUP_FLAGS_AWS
    # if EC2_BACKUP_FLAGS has been set, it covers old settigns.
    INSTANCE_ID=$(aws ec2 run-instances --security-group-ids $EC2_GROUP_ID --key-name $KEY_NAME --instance-type m1.small $EC2_BACKUP_FLAGS_AWS --image-id $IMAGE_ID | \
        grep InstanceId | awk '{print $2}' | cut -d '"' -f 2)
    #echo 'The Instance ID is' 
    #echo $INSTANCE_ID
    TARGET_IP_ADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | \
        grep PublicIpAddress | awk '{print $2}' | cut -d '"' -f 2)
    #echo 'The server IP address is'
    #echo $TARGET_IP_ADDRESS
}

terminate_instance()
{
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID 1>&2
}

connect_instance()
{
    ssh -o StrictHostKeyChecking=no $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "exit"
    while [ "$?" != "0" ]
    do
        echo "Waiting for Port 22."
        sleep 3
        ssh -o StrictHostKeyChecking=no $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "exit"
    done
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

umount_filesystem()
{
    ssh $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "sudo umount /home/fedora/backup_shell" 1>&2
    sleep 1
    aws ec2 detach-volume --volume-id $VOLUME_ID 1>&2
}

rsync_backup()
{
    FLAGS="\"ssh $EC2_BACKUP_FLAGS_SSH\""
    eval rsync -avz -e $FLAGS $SOURCE_DIR fedora@$TARGET_IP_ADDRESS:/home/fedora/backup_shell
}

dd_backup()
{
    tar cvf - $SOURCE_DIR | ssh $EC2_BACKUP_FLAGS_SSH fedora@$TARGET_IP_ADDRESS "dd of=/home/fedora/back_up.tar"
}

usage()
{
	cat <<EOH
usage: $0 [-hvm]
	-h Print help me
    -m Print all MAC addresses.
	-n Print all netmasks.
EOH
}

usage_help()
{
    cat <<EOH
NAME
     ec2-backup -- backup a directory into Elastic Block Storage (EBS)

SYNOPSIS
     ec2-backup [-h] [-m method] [-v volume-id] dir

DESCRIPTION
     The ec2-backup tool performs a backup of the given directory into Amazon
     Elastic Block Storage (EBS).  This is achieved by creating a volume of
     the appropriate size, attaching it to an EC2 instance and finally copying
     the files from the given directory into this volume.

OPTIONS
     ec2-backup accepts the following command-line flags:

     -h 	   Print a usage statement and exit.

     -m method	   Use the given method to perform the backup.	Valid methods
		   are 'dd' and 'rsync'; default is 'dd'.

     -v volume-id  Use the given volume instead of creating a new one.

DETAILS
     ec2-backup will perform a backup of the given directory to an ESB volume.
     The backup is done in one of two ways: via direct write to the volume as
     a block device (utilizing tar(1) on the local host and dd(1) on the
     remote instance), or via a (possibly incremental) filesystem sync (uti-
     lizing rsync(1)).

     Unless the -v flag is specified, ec2-backup will create a new volume, the
     size of which will be at least two times the size of the directory to be
     backed up.

     ec2-backup will create an instance suitable to perform the backup, attach
     the volume in question and then back up the data from the given directory
     using the specified method and then shut down and terminate the instance
     it created.

OUTPUT
     By default, ec2-backup prints the volume ID of the volume to which it
     backed up the data as the only output.  If the EC2_BACKUP_VERBOSE envi-
     ronment variable is set, it may also print out some useful information
     about what steps it is currently performing.

     Any errors encountered cause a meaningful error message to be printed to
     STDERR.

ENVIRONMENT
     ec2-backup assumes that the user has set up their environment for general
     use with the EC2 tools.  That is, it will not set or modify any environ-
     ment variables.

     ec2-backup allows the user to add custom flags to the commands related to
     starting a new EC2 instance via the EC2_BACKUP_FLAGS_AWS environment
     variable.

     ec2-backup also assumes that the user has set up their ~/.ssh/config file
     to access instances in EC2 via ssh(1) without any additional settings.
     It does allow the user to add custom flags to the ssh(1) commands it
     invokes via the EC2_BACKUP_FLAGS_SSH environment variable.

     As noted above, the EC2_BACKUP_VERBOSE variable may cause ec2-backup to
     generate informational output as it runs.

EXIT STATUS
     The ec2-backup will exit with a return status of 0 under normal circum-
     stances.  If an error occurred, ec2-backup will exit with a value >0.

EXAMPLES
     The following examples illustrate common usage of this tool.

     To back up the entire filesystem using rsync(1):

	   $ ec2-backup -m rsync /
	   vol-a1b2c3d4
	   $ echo $?
	   0
	   $

     To create a complete backup of the current working directory using
     defaults (and thus not requiring a filesystem to exist on the volume) to
     the volume with the ID vol-1a2b3c4d:

	   ec2-backup -v vol-1a2b3c4d .

     Suppose a user has their ~/.ssh/config set up to use the private key
     ~/.ec2/stevens but wishes to use the key ~/.ssh/ec2-key instead:

	   $ export EC2_BACKUP_FLAGS_SSH="-i ~/.ssh/ec2-key"
	   $ ec2-backup .
	   vol-a1b2c3d4
	   $

     To force creation of an instance type of t1.micro instead of whatever
     defaults might apply

	   $ export EC2_BACKUP_FLAGS_AWS="--instance-type t1.micro"
	   $ ec2-backup .
	   vol-a1b2c3d4
	   $

SEE ALSO
     aws help, dd(1), tar(1), rsync(1)

HISTORY
     ec2-backup was originally assigned by Jan Schaumann
     <jschauma@cs.stevens.edu> as a homework assignment for the class "Aspects
     of System Administration" at Stevens Institute of Technology in the
     Spring of 2011.
LiINK
    https://www.cs.stevens.edu/~jschauma/615/ec2-backup.txt
EOH
}

###############
# main
###############
while getopts ":m:v:h" opt; do
    case "$opt" in
        m) 
            echo "Found the -m option, with value $OPTARG"
            if [ $OPTARG = "dd" ]
            then
                BACKUP_METHOD=$OPTARG
                echo $BACKUP_METHOD
            elif [ $OPTARG = "rsync" ]
            then
                BACKUP_METHOD=$OPTARG
            else
                usage
                exit 1
            fi  
        ;;
        v) 
            echo "Found the -v option, with value $OPTARG"
            VOLUME_ID=$OPTARG
        ;;
        h) 
            usage_help
            exit 0
        ;;
        *) 
            echo "Unknown option: $opt"
        ;;
    esac
done
shift $(( ${OPTIND} - 1 ))
SOURCE_DIR=$@


###############
#main
###############
create_instance
echo "[Create Instance] Done"
if [ $VOLUME_ID = "1" ]
then
    create_ebs_volume
fi
echo $VOLUME_ID
echo "[Create Volume] Done"
connect_instance
#create_ebs_volume
sleep 10
attach_volume
sleep 10
mount_filesystem
if [ $BACKUP_METHOD = "dd" ]
then
    dd_backup
else
    rsync_backup
fi
umount_filesystem
echo "[Umount Filesystem] Done"
sleep 1
terminate_instance
echo "[All Done]"
