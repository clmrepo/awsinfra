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

for var in ${VAR_PATH}/* ; do
	v=$(echo ${var} | cut -d'/' -f3 | cut -d'.' -f1)
	if [[ ! -z ${APPLY} ]] ; then
		sleep 1
		if [[ -z $(terraform workspace list | grep ${v}) ]] ; then 
			terraform workspace new ${v}
		else 
			terraform workspace select ${v}
		fi
		sleep 1
		terraform plan -out=tfplan-${v} -input=false -var-file=${var} > /dev/null
		sleep 1
		terraform apply -input=false tfplan-${v} >> ./terraform.out/.apply.${v}.$(date +%H%M_%m%d%Y) 2>&1 &
	else
		if [[ -z $(terraform workspace list | grep ${v}) ]] ; then 
			echo "terraform workspace new ${v}"
		else 
			echo "terraform workspace select ${v}"
		fi
		#echo "terraform workspace select ${v}"
		echo "terraform plan -out=tfplan-${v} -input=false -var-file=${var}"
		echo "terraform apply -input=false tfplan-${v} >> ./terraform.out/.apply.${v}.$(date +%H%M_%m%d%Y) 2>&1 &"
	fi
done

