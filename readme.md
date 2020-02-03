# CreateContainerConfigError

A lot of pods are stuck in status CreateContainerConfigError and that generate a big volume of logs recurrently (8% of the total number of pods on BUILD L1-C).

We did a test and proove that a pod generate 5logs/min on just one worker node.
We know that a pod depend of a controller.

[CreateContainerConfigError.sh] (CreateContainerConfigError.sh) will be run each day as a cron job and allow us to delete the controller of each pod in status CreateContainerConfigError aged more than 7 days.

```shell
 mkdir -p /opt/icp/exploitation/scripts/CreateContainerConfigError/Backup_YAML && vim /opt/icp/exploitation/scripts/CreateContainerConfigError/CreateContainerConfigError.sh && chmod 770 /opt/icp/exploitation/scripts/CreateContainerConfigError/CreateContainerConfigError.sh
```

And copy the following script into the new file:
[CreateContainerConfigError.sh] (CreateContainerConfigError.sh)

Add the script to the crontab to automatically complete the job:

```shell
crontab -e
```

```shell
######################DELETE CreateContainerConfigError Pods & Owners

0 0 * * * /opt/icp/exploitation/scripts/CreateContainerConfigError/CreateContainerConfigError.sh
```
