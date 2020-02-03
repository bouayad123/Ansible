#!/bin/bash
#Date
datetoday=$(date +%Y-%m-%d)
# Set the directory variable
dirr=/opt/icp/exploitation/scripts/CreateContainerConfigError
##Detect the pods stuck in status CreateContainerConfigError aged more than 7 days
kubectl get pods --all-namespaces --sort-by=.metadata.creationTimestamp -o=jsonpath='{range .items[*]}{.metadata.namespace} {.metadata.name} {.metadata.creationTimestamp} {.status.containerStatuses..state...reason} {.metadata.ownerReferences..kind} {.metadata.ownerReferences..name} {"\n"}{end}' | awk '$3 <= "'$(date -d '7 days ago' -Ins --utc | sed 's/+0000/Z/')'" {for(i=1;i<NF;i++)printf"%s",$i OFS;if(NF)printf"%s",$NF;printf ORS}' | grep CreateContainerConfigError >$dirr/CreateContainerConfigError.txt
#Check if the file isn't empty
if [ -s $dirr/CreateContainerConfigError.txt ]
then
        #Create the pods namespaces tmp file
        cat  $dirr/CreateContainerConfigError.txt | awk '{print $1}' > $dirr/tmp_namespaces.txt
        #Create the pods owner-n_kind tmp file
        cat  $dirr/CreateContainerConfigError.txt | awk '{print $(NF-1)}' > $dirr/tmp_pods_owner-n_kind.txt
        #Create the pods owner-n_name tmp file
        cat  $dirr/CreateContainerConfigError.txt | awk '{print $NF}' > $dirr/tmp_pods_owner-n_name.txt
        #Create the pods owner-n tmp file
        while read -r x && read -r y <&3;
        do echo $x/$y >> $dirr/tmp_pods_owner-n.txt ;
        done <$dirr/tmp_pods_owner-n_kind.txt 3<$dirr/tmp_pods_owner-n_name.txt

        #Actions
        while read -r x && read -r y <&3;
        do
                #Set the tmp file for removed owner-n
                touch $dirr/tmp_rs.txt || exit 1
                #Check if the current owner-n is already removed
                if grep -Fwq "$x" $dirr/tmp_rs.txt
                        then
                        #Do nothing
                        :
                else
                        if [[ "$x" == "ReplicaSet"* ]]
                                then
                                #Set the owner-n+1_kind variable
                                owner_n1_kind=$(kubectl get $x -n $y -o go-template --template '{{(index (index .metadata.ownerReferences 0).kind)}}{{"\n"}}')
                                # Set the owner-n+1_kind variable
                                owner_n1_name=$(kubectl get $x -n $y -o go-template --template '{{(index (index .metadata.ownerReferences 0).name)}}{{"\n"}}')
                                #Backup the owner n+1
                                #Set the yaml file dir
                                file_dir=$dirr/Backup_YAML/
                                #Set the yaml file name
                                file_name=$y---$owner_n1_kind---$owner_n1_name.yaml
                                #Save the yaml
                                kubectl get $owner_n1_kind $owner_n1_name -n $y -o yaml > $file_dir$file_name
                                #Delete the owner-n+1 in cascade mode (This option will automatically delete dependants: Garbage Collector)
                                kubectl delete $owner_n1_kind $owner_n1_name -n $y --cascade=true
                                #Internal report
                                internal_report=$dirr/internal_report.log
                                echo "$datetoday: Le $owner_n1_kind $owner_n1_name du namespace:$y a ete supprime avec ses dependances ($x ...). Le fichier .yaml du $owner_n1_kind est:$file_dir$file_name" >>$internal_report
                                #External report
                                external_report=$dirr/external_report.log
                                echo "$datetoday: Le $owner_n1_kind $owner_n1_name du namespace:$y a ete supprime ses dependances ($x ...). Merci de desormais respecter la PSP" >>$external_report;
                                #Save the deleted owner-n in the tmp file
                                echo $x >>$dirr/tmp_rs.txt
                        else
                                #Set the yaml file dir
                                file_dir=$dirr/Backup_YAML/
                                #Set the yaml file name
                                file_name=$y---$x.yaml
                                #Save the yaml
                                kubectl get $x -n $y -o yaml > $file_dir$file_name
                                #Delete the owner-n+1 in cascade mode (This option will automatically delete dependants: Garbage Collector)
                                kubectl delete $x -n $y --cascade=true
                                #Internal report
                                internal_report=$dirr/internal_report.log
                                echo "$datetoday: Le $x du namespace:$y a ete supprime avec ses dependances . Le fichier .yaml du $x est:$file_dir$file_name" >>$internal_report
                                #External report
                                external_report=$dirr/external_report.log
                                echo "$datetoday: Le $x du namespace:$y a ete supprime ses dependances . Merci de desormais respecter la PSP" >>$external_report;
                                #Save the deleted owner-n in the tmp file
                                echo $x >>$dirr/tmp_rs.txt
                        fi

                fi
        done <$dirr/tmp_pods_owner-n.txt 3<$dirr/tmp_namespaces.txt
        rm $dirr/tmp_pods_owner-n.txt || exit 1
        rm $dirr/tmp_rs.txt || exit 1
else
        #Do nothing
        :
fi
exit 0
