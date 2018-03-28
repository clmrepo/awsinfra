#!/bin/bash

# Seem like terrafrom does not delete volumes and key-pairs after destroying infrastructure

REGION_LIST_FILE="./AWS_region.list"
IFS=$'\n'

for region in $(cat ${REGION_LIST_FILE}) ; do
	echo "Region: ${region}"
	for volume_id in $(aws --region ${region} ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text | sed -E -e 's/\s+/\n/g') ; do
		echo -ne "\tDeleting volume: ${volume_id} ..."
		ret_val=$(aws --region ${region} ec2 delete-volume --volume-id	${volume_id})
		if [[ $? == 0 ]] ;  then
			echo -e "\tdone"
		else
			echo -e "\terror: ${ret_val}"
		fi
	done
	for key_name in $(aws --region ${region} ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output text | sed -E -e 's/\s+/\n/g') ; do
		echo -ne "\tDeleting key-pair: ${key_name} ..."
		ret_val=$(aws --region ${region} ec2 delete-key-pair --key-name	${key_name})
		if [[ $? == 0 ]] ;  then
			echo -e "\tdone"
		else
			echo -e "\terror: ${ret_val}"
		fi
	done
done

