#!/bin/sh

EC2_GROUP_ID="sg-568d582e"
EC2_GROUP_NAME=""
KEY_NAME=""

IMAGE_ID="ami-0187f76b"
IMAGE_REGION="us-east-1"
AVAIL_ZONE="us-east-1a"

getOptions(){
    while getopts :m:v:h opt
    do
        case "$opt" in
        m) echo "Found the -m option, with value $OPTARG";;
        v) echo "Found the -v option, with value $OPTARG";;
        h) echo "Found the -h option" ;;
        *) echo "Unknown option: $opt";;
        esac
    done
    shift $[ $OPTIND - 1 ]

    count=1
    for param in "$@"
    do
        echo "Parameter $count: $param"
        count=$[ $count + 1 ]
    done
}

create-KeyPair()
{
    EC2_GROUP_NAME=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
    aws ec2 create-security-group --group-name $EC2_GROUP_NAME --description "For CS-615 HW6"
    while [ "$?" != "0" ]
    do
        EC2_GROUP_NAME=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
        aws ec2 create-security-group --group-name $EC2_GROUP_NAME --description "For CS-615 HW6"
    done
    aws ec2 authorize-security-group-ingress --group-name $EC2_GROUP_NAME --protocol tcp --port 22 --cidr '0.0.0.0/0'
    aws ec2 authorize-security-group-ingress --group-name $EC2_GROUP_NAME --protocol tcp --port 80 --cidr '0.0.0.0/0'

    KEY_NAME=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
    while [ "$?" != "0" ]
    do
        KEY_NAME=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 7)
        aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME.pem
    done
    
    chmod 400 $KEY_NAME.pem

    aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type t1.micro --key-name $KEY_NAME --security-groups $EC2_GROUP_NAME
}


delete-KeyPair()
{
    aws ec2 delete-key-pair --key-name $KEY_NAME
    aws ec2 delete-security-group --group-name $EC2_GROUP_NAME    
    rm -f $KEY_NAME.pem
}

create-KeyPair
#create_instance
echo "[Create Instance] Done"

#create_ebs_volume
#INSTANCE_ID="i-0d37dc90"
#TARGET_IP_ADDRESS="54.172.162.153"
#connect_instance
#create_ebs_volume
##sleep 10
#attach_volume
#sleep 10
#mount_filesystem
#rsync_backup
#terminate_instance
#delete-KeyPair

#echo "[Connect Instance] Successed"
#terminate_instance
#echo "[Terminate Instance] Done"