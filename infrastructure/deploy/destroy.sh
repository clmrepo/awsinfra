#!/bin/bash

POS=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--apply)
    APPLY=YES
    shift # past argument
    ;;
    *)    # unknown option
    POS+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POS[@]}" # restore positional parameters

#echo APPLY         = "${APPLY}"
VAR_PATH="./variables"


if [[ ! -z ${APPLY} ]] ; then
	cp -rp ./terraform.tfstate.d ./terraform.tfstate.d_$(date +%H:%M_%m-%d-%Y)
fi

for var in ${VAR_PATH}/* ; do
	v=$(echo ${var} | cut -d'/' -f3 | cut -d'.' -f1)
	if [[ ! -z ${APPLY} ]] ; then
		sleep 1
		terraform workspace select ${v}
		sleep 1
		terraform destroy -var-file=${var} -force >> ./terraform.out/.destroy.${v}.$(date +%H%M_%m%d%Y) 2>&1 &
	else
		echo "terraform workspace select ${v}"
		echo "terraform destroy -var-file=${var} -force >> ./terraform.out/.destroy.${v}.$(date +%H%M_%m%d%Y) 2>&1 &"
	fi
done

# dirty hack to make sure all garbage is cleaned from aws infra
#if [[ ! -z ${APPLY} ]] ; then
#	echo "Cleaning volumes and key-pairs.."
#	cd ../cleanup/ && . delete_volumes_keypairs.sh
#fi

