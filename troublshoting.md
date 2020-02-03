# Table des matières
1. [Clignotement de la page Images dans la console](#Ancre1)
2. [Messages récurrents de démarrage de containers zombies dans /var/log/messages ou /var/log/icp/docker.log](#Ancre2)
3. [Problème de création de pvc "Kubernetes node nodeVmDetail details is empty"](#Ancre3)
4. [Pods restants en "ContainerCreating"](#Ancre4)
5. [Interception des access logs d'une appli client](#Ancre5)
6. [icp-cloudant-backup pod restart X times within the last 15 minutes](#Ancre6)
7. [Pas de donées dans la console VA](#Ancre7)
8. [impossible de changer les paramètres de policy VA](#Ancre8)
9. [impossible d'envoyer un requete curl trop longue](#Ancre9)
10. [ElasticSearch "Failed to create node environment"](#Ancre10)
11. [Le POD k8s-mariadb ne démarre pas](#Ancre11)
12. [Problème d'authentification sur la Plateforme L1C prod](#Ancre12)
13. [Les quotas ne sont pas mis à jour](#Ancre13)
14. [No space left on device elasticsearch-data](#Ancre14)
15. [Not enough space on device lors d'une installation de patch](#Ancre15)
16. [Orphan Pods Deletion](#Ancre16)
17. [réinstallation mgmt-repo après suppression de la release](#Ancre17)
18. [Récuperer des helm charts dans l'image inception](#Ancre18)
19. [Résolution de l’incident Pod service-catalog-controller-manager CrashLoopBackOff (TS002723392)](#Ancre19)

### 1. Clignotement de la page Images dans la console<a id="Ancre1"></a>

1-	Voir l’état des pods Image-manager :

```shell
kubectl get po -n kube-system -s 127.0.0.1:8888 -o wide| grep image
image-manager-0                                           2/2       Running   0          14d       10.241.76.155   s00vl9984053
image-manager-1                                           2/2       Running   0          20h       10.241.81.111   s00vl9984067
image-manager-2                                           2/2       Running   0          3d        10.241.67.54    s00vl9984074
```

2-	Aller dans chacun des pods et énumérer les images :

```shell
kubectl exec -it image-manager-X -n kube-system -s 127.0.0.1:8888 bash
cd /var/lib/registry/docker/registry/v2/repositories
ls -l * | wc –l
```

-->	1 des 3 pods n’avait pas le même nombre de lignes

3-	Sur le master hébergeant ce pod, vérifier le FS /var/lib/registry :
Exemple d’un montage NFS absent :

```console
root@s00vl9984067:/var/lib/registry$ df -h .
Filesystem              Size  Used Avail Use% Mounted on
/dev/mapper/rootvg-var  3.9G  1.7G  2.1G  46% /var
```

4-	Réaliser le montage du FS sur le master en question :

```shell
mount -a
```

Vérification :

```console
root@s00vl9984067:/var/lib/registry$ df -h .
Filesystem                                                                         Size  Used Avail Use% Mounted on
s00vf9982338.fr.net.intra:/vol_SVM_DMZ_MULTI_NPRD_018/a00nn9383032_qtree/registry  200G   63G  138G  32% /var/lib/registry
```

5-	Supprimer le pod image-manager qui tournait sur le master en question :

```shell
kubectl delete po image-manager-1 -n kube-system -s 127.0.0.1:8888 --force --grace-period=0
```

6-	Vérifier en lançant la commande de la tâche 2 et que le montage NFS est toujours actif (tâche 4)


### 2. Messages récurrents de démarrage de containers zombies dans /var/log/messages ou /var/log/icp/docker.log<a id="Ancre2"></a>

1- Exemple de message dans les fichiers /var/log/messages ou /var/log/icp/docker.log :

Oct 10 10:49:29 s00vl9994554 hyperkube[1137]: E1010 08:49:29.756618    1137 kuberuntime_manager.go:874] getPodContainerStatuses for pod "auth-idp-t66qk_kube-system(dfc3b1e2-bb54-11e8-a487-00505600bc1c)" failed: rpc error: code = Unknown desc = unable to inspect docker image "sha256:5907c0a2654c85674cac1f73e8c479572e03cb2f2b4c51077db7f1703b25ae99" while inspecting docker container __"0c949b47ef92c910293fa7d5f376875041828ff54a77e7cc1becd291cb6c95f4"__: no such image: "sha256:5907c0a2654c85674cac1f73e8c479572e03cb2f2b4c51077db7f1703b25ae99"

Attention : ces messages peuvent polluer rapidement les fichiers de log et remplir le file system concerné.

2- Arrêter docker

```shell
systemctl stop docker
```

3- Supprimer les containers zombies

```shell
cd /var/lib/docker/containers

rm -rf 0c949b47ef92c910293fa7d5f376875041828ff54a77e7cc1becd291cb6c95f4
```

4- Démarrer docker

```shell
systemctl start docker
```

5- Vérifier l'absence des messages dans /var/log/messages ou /var/log/icp/docker.log

```shell
tail -f /var/log/message

ou

tail -f /var/log/icp/docker.log
```

### 3. Problème de création de pvc "Kubernetes node nodeVmDetail details is empty"<a id="Ancre3"></a>

1- symptôme

```
Après le build d'une infrastructure ICP, les PVC restent en statut "pending"
En faisant un describe du pvc on observe le message d'erreur suivant:
Failed to provision volume with StorageClass "pvcstorage": Kubernetes node nodeVmDetail details is empty. nodeVmDetails : [
```

2- Résolution

```
Pour résoudre le problème, nosu avons redémarré le service kubelet sur les trois masters, node après node.
>systemctl restart kubelet
```

### 4. Pods restant en "ContainerCreating"<a id="Ancre4"></a>

1- symptôme

Les pods qui démarrent sur des nodes spécifiques restent en statut "ContainerCreating".
Pour détecter ces nodes, il suffit de taper la commande suivante:

```shell
kubectl get pod --all-namespaces -o wide | grep -i ContainerCreating
```

2- Résolution

Voici le retour d'IBM concernant ce problème:
Please provide the output from the mustgather [script](collect.sh) to follow this email.

The script's intent is to facilitate the log collection during a problem report to IBM. Please provide the output of this script with the information accordingly the issue that you are facing
To run this script, Log in to the boot node as a user with root permissions
The Script will collect the information below:

```
Hostname
Memory information
CPU Informatio
Filesystems
/etc/hosts file
route information
Network adapters information
ports that are listening
docker version
docker information
docker images
Kubernetes Status
Docker status
Docker logs
Disk performance
Kubernetes pods
last 1000 lines for kubernetes logs
```

Par la suite, il faudra créer un nouveau ticket avec les logs en faisant référence au ticket TS001606890.


### 5. Interception des access logs d'une appli client<a id="Ancre5"></a>

1- Use case

Un client a besoin des access logs de son ingress.

2- Mode opératoire

Il faut lui demande d'ajouter deux lignes dans le snippet de son ingress afin d'avoir les logs access et error

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    ingress.kubernetes.io/configuration-snippet: |
      access_log /var/log/nginx/<nom de l'appli>-log-access.log;
      error_log /var/log/nginx/<nom de l'appli>-log-error.log;
```

33 Récupérer les logs

Les fichiers peuvent être récupérés dans les pods `nginx-ingress-lb-amd64-` dans le répertoire indiqué dans le config.

### 6. icp-cloudant-backup pod restart X times within the last 15 minutes<a id="Ancre6"></a>

1- symptôme

Reception d'un incident MICA avec le contenu suivant:


Pod /icp-cloudant-backup-1543537800-knq5t was restarted 5.569180555555555 times within the last 15 minutes
Résumé complet : Date: 30/11/2018 00:43:29
Node: S00VL9994549
OS: Linux
Env: PRODUCTION
Appli: PAAS BLUEMIX
Alerte: Pod /icp-cloudant-backup-1543537800-knq5t was restarted 5.569180555555555 times within the last 15 minutes


2- Résolution

a- se connecter au boot node présent dans l'incident et identifier le pod

```shell
kubectl -n kube-system get pod -o wide | grep icp-cloudant-backup
NAME                                   READY     STATUS             RESTARTS   AGE       IP              NODE
icp-cloudant-backup-1543537800-knq5t   0/1       CrashLoopBackOff   98         8h        10.241.89.125   s00vl9994552
```

b- regarder les logs du pod

```shell
kubectl -n kube-system logs icp-cloudant-backup-1543537800-knq5t
[...]
mkdir: can't create directory '/backup/icp-cloudant-backup-2018-11-30-08-27-59': No space left on device
```

c- se connecter au worker hébergeant le pod et identifier le container

```shell
ssh s00vl9994552
docker ps -a | grep -i backup
6f81367f0410        90d711b501e0               "/cloudant-backup.sh"    4 minutes ago       Exited (4) 4 minutes ago                       k8s_icp-cloudant-backup_icp-cloudant-backup-1543537800-knq5t_kube-system_16302de0-f437-11e8-a396-00505600bc1c_98
049edfbec2d8        ibmcom/pause:3.0           "/pause"                 8 hours ago         Up 8 hours                                     k8s_POD_icp-cloudant-backup-1543537800-knq5t_kube-system_16302de0-f437-11e8-a396-00505600bc1c_0
c59686006b09        90d711b501e0               "/cloudant-backup.sh"    2 days ago          Exited (0) 2 days ago                          k8s_icp-cloudant-backup_icp-cloudant-backup-1543365000-kgzsc_kube-system_bf4ea641-f2a4-11e8-a396-00505600bc1c_3
914117d7f7b8        ibmcom/pause:3.0           "/pause"                 2 days ago          Exited (0) 2

```

d- faire un inspect du pod pour récupérer le path sur le worker

```
docker inspect 6f81367f0410 | grep -i HostsPath 
        "HostsPath": "/var/lib/kubelet/pods/16302de0-f437-11e8-a396-00505600bc1c/etc-hosts",
```

e- Se placer dans le répertoire du volume icp-backup et lister les backups

```console
cd /var/lib/kubelet/pods/16302de0-f437-11e8-a396-00505600bc1c/volumes/kubernetes.io~nfs/icp-backup
ls -lrth
total 208K
drwxr-xr-x 2 root root 4.0K Nov 13 04:07 icp-cloudant-backup-2018-11-13-01-49-45
drwxr-xr-x 2 root root 4.0K Nov 13 05:26 icp-cloudant-backup-2018-11-13-03-08-01
drwxr-xr-x 2 root root 4.0K Nov 14 02:53 icp-cloudant-backup-2018-11-14-00-30-04
drwxr-xr-x 2 root root 4.0K Nov 14 04:15 icp-cloudant-backup-2018-11-14-01-53-25
drwxr-xr-x 2 root root 4.0K Nov 14 05:38 icp-cloudant-backup-2018-11-14-03-15-22
drwxr-xr-x 2 root root 4.0K Nov 15 02:54 icp-cloudant-backup-2018-11-15-00-30-03
drwxr-xr-x 2 root root 4.0K Nov 15 04:21 icp-cloudant-backup-2018-11-15-01-54-20
drwxr-xr-x 2 root root 4.0K Nov 15 05:47 icp-cloudant-backup-2018-11-15-03-21-14
drwxr-xr-x 2 root root 4.0K Nov 16 02:58 icp-cloudant-backup-2018-11-16-00-30-08
drwxr-xr-x 2 root root 4.0K Nov 16 04:23 icp-cloudant-backup-2018-11-16-01-58-23
drwxr-xr-x 2 root root 4.0K Nov 16 05:51 icp-cloudant-backup-2018-11-16-03-24-08
drwxr-xr-x 2 root root 4.0K Nov 17 02:59 icp-cloudant-backup-2018-11-17-00-30-09
drwxr-xr-x 2 root root 4.0K Nov 17 04:29 icp-cloudant-backup-2018-11-17-01-59-21
drwxr-xr-x 2 root root 4.0K Nov 17 05:57 icp-cloudant-backup-2018-11-17-03-30-09
drwxr-xr-x 2 root root 4.0K Nov 18 03:00 icp-cloudant-backup-2018-11-18-00-30-08
drwxr-xr-x 2 root root 4.0K Nov 18 04:34 icp-cloudant-backup-2018-11-18-02-00-09
drwxr-xr-x 2 root root 4.0K Nov 18 06:08 icp-cloudant-backup-2018-11-18-03-34-10
drwxr-xr-x 2 root root 4.0K Nov 19 03:03 icp-cloudant-backup-2018-11-19-00-30-07
drwxr-xr-x 2 root root 4.0K Nov 19 04:37 icp-cloudant-backup-2018-11-19-02-03-43
drwxr-xr-x 2 root root 4.0K Nov 19 06:13 icp-cloudant-backup-2018-11-19-03-38-00
drwxr-xr-x 2 root root 4.0K Nov 20 03:06 icp-cloudant-backup-2018-11-20-00-30-06
drwxr-xr-x 2 root root 4.0K Nov 20 04:43 icp-cloudant-backup-2018-11-20-02-07-00
drwxr-xr-x 2 root root 4.0K Nov 20 06:23 icp-cloudant-backup-2018-11-20-03-43-37
drwxr-xr-x 2 root root 4.0K Nov 21 03:07 icp-cloudant-backup-2018-11-21-00-30-12
drwxr-xr-x 2 root root 4.0K Nov 21 04:43 icp-cloudant-backup-2018-11-21-02-07-25
drwxr-xr-x 2 root root 4.0K Nov 21 06:21 icp-cloudant-backup-2018-11-21-03-44-07
drwxr-xr-x 2 root root 4.0K Nov 22 03:10 icp-cloudant-backup-2018-11-22-00-30-11
drwxr-xr-x 2 root root 4.0K Nov 22 04:50 icp-cloudant-backup-2018-11-22-02-10-26
drwxr-xr-x 2 root root 4.0K Nov 22 06:32 icp-cloudant-backup-2018-11-22-03-50-41
drwxr-xr-x 2 root root 4.0K Nov 23 03:10 icp-cloudant-backup-2018-11-23-00-30-09
drwxr-xr-x 2 root root 4.0K Nov 23 04:52 icp-cloudant-backup-2018-11-23-02-10-47
drwxr-xr-x 2 root root 4.0K Nov 23 06:32 icp-cloudant-backup-2018-11-23-03-52-40
drwxr-xr-x 2 root root 4.0K Nov 24 03:14 icp-cloudant-backup-2018-11-24-00-30-09
drwxr-xr-x 2 root root 4.0K Nov 24 04:56 icp-cloudant-backup-2018-11-24-02-14-25
drwxr-xr-x 2 root root 4.0K Nov 24 06:40 icp-cloudant-backup-2018-11-24-03-56-56
drwxr-xr-x 2 root root 4.0K Nov 25 03:16 icp-cloudant-backup-2018-11-25-00-30-03
drwxr-xr-x 2 root root 4.0K Nov 25 05:06 icp-cloudant-backup-2018-11-25-02-16-26
drwxr-xr-x 2 root root 4.0K Nov 25 06:56 icp-cloudant-backup-2018-11-25-04-06-25
drwxr-xr-x 2 root root 4.0K Nov 26 03:17 icp-cloudant-backup-2018-11-26-00-30-09
drwxr-xr-x 2 root root 4.0K Nov 26 05:05 icp-cloudant-backup-2018-11-26-02-17-21
drwxr-xr-x 2 root root 4.0K Nov 26 06:53 icp-cloudant-backup-2018-11-26-04-05-22
drwxr-xr-x 2 root root 4.0K Nov 26 08:42 icp-cloudant-backup-2018-11-26-05-53-32
drwxr-xr-x 2 root root 4.0K Nov 27 03:22 icp-cloudant-backup-2018-11-27-00-30-09
drwxr-xr-x 2 root root 4.0K Nov 27 05:14 icp-cloudant-backup-2018-11-27-02-22-21
drwxr-xr-x 2 root root 4.0K Nov 27 07:05 icp-cloudant-backup-2018-11-27-04-14-34
drwxr-xr-x 2 root root 4.0K Nov 27 08:54 icp-cloudant-backup-2018-11-27-06-05-48
drwxr-xr-x 2 root root 4.0K Nov 28 03:24 icp-cloudant-backup-2018-11-28-00-30-06
drwxr-xr-x 2 root root 4.0K Nov 28 05:18 icp-cloudant-backup-2018-11-28-02-24-09
drwxr-xr-x 2 root root 4.0K Nov 28 07:11 icp-cloudant-backup-2018-11-28-04-18-45
drwxr-xr-x 2 root root 4.0K Nov 28 09:07 icp-cloudant-backup-2018-11-28-06-11-47
drwxr-xr-x 2 root root 4.0K Nov 29 03:08 icp-cloudant-backup-2018-11-29-00-30-12
drwxr-xr-x 2 root root 4.0K Nov 29 03:51 icp-cloudant-backup-2018-11-29-02-08-37
```

f- garder 7 jours de backups

```shell
rm -rf ./icp-cloudant-backup-2018-11-13-01-49-45
rm -rf ./icp-cloudant-backup-2018-11-13-03-08-01
rm -rf ./icp-cloudant-backup-2018-11-14-00-30-04
rm -rf ./icp-cloudant-backup-2018-11-14-01-53-25
rm -rf ./icp-cloudant-backup-2018-11-14-03-15-22
rm -rf ./icp-cloudant-backup-2018-11-15-00-30-03
rm -rf ./icp-cloudant-backup-2018-11-15-01-54-20
rm -rf ./icp-cloudant-backup-2018-11-15-03-21-14
rm -rf ./icp-cloudant-backup-2018-11-16-00-30-08
rm -rf ./icp-cloudant-backup-2018-11-16-01-58-23
rm -rf ./icp-cloudant-backup-2018-11-16-03-24-08
rm -rf ./icp-cloudant-backup-2018-11-17-00-30-09
rm -rf ./icp-cloudant-backup-2018-11-17-01-59-21
rm -rf ./icp-cloudant-backup-2018-11-17-03-30-09
rm -rf ./icp-cloudant-backup-2018-11-18-00-30-08
rm -rf ./icp-cloudant-backup-2018-11-18-02-00-09
rm -rf ./icp-cloudant-backup-2018-11-18-03-34-10
rm -rf ./icp-cloudant-backup-2018-11-19-00-30-07
rm -rf ./icp-cloudant-backup-2018-11-19-02-03-43
rm -rf ./icp-cloudant-backup-2018-11-19-03-38-00
rm -rf ./icp-cloudant-backup-2018-11-20-00-30-06
rm -rf ./icp-cloudant-backup-2018-11-20-02-07-00
rm -rf ./icp-cloudant-backup-2018-11-20-03-43-37
rm -rf ./icp-cloudant-backup-2018-11-21-00-30-12
rm -rf ./icp-cloudant-backup-2018-11-21-02-07-25
rm -rf ./icp-cloudant-backup-2018-11-21-03-44-07
rm -rf ./icp-cloudant-backup-2018-11-22-00-30-11
rm -rf ./icp-cloudant-backup-2018-11-22-02-10-26
rm -rf ./icp-cloudant-backup-2018-11-22-03-50-41
```
g- vérifier l'espace disponible, se reconnecter au boot node et redemarrer le pod

```shell
df -h /var/lib/kubelet/pods/16302de0-f437-11e8-a396-00505600bc1c/volumes/kubernetes.io~nfs/icp-backup/
Filesystem                                                                Size  Used Avail Use% Mounted on
s00vf9993942.fr.net.intra:/vol_SVM_DMZ_MULTI_PROD_046/a00nn9395634_qtree  300G  143G  158G  48% /var/lib/kubelet/pods/16302de0-f437-11e8-a396-00505600bc1c/volumes/kubernetes.io~nfs/icp-backup

kubectl -n kube-system get pod -o wide icp-cloudant-backup-1543537800-knq5t                                                                                                                                             NAME                                   READY     STATUS             RESTARTS   AGE       IP              NODE
icp-cloudant-backup-1543537800-knq5t   0/1       CrashLoopBackOff   101        8h        10.241.89.125   s00vl9994552

kubectl -n kube-system delete pod icp-cloudant-backup-1543537800-knq5t
pod "icp-cloudant-backup-1543537800-knq5t" deleted

kubectl -n kube-system get pod -o wide | grep -i icp-cloudant-backup
icp-cloudant-backup-1543537800-7rqsn                      1/1       Running   0          20s       10.241.95.24    s00vl9994547

kubectl -n kube-system logs icp-cloudant-backup-1543537800-7rqsn
[...]
2018-11-30T08:47:59.661Z couchbackup:backup Written batch ID: 63 Total document revisions written: 32500 Time: 92.677
2018-11-30T08:48:04.898Z couchbackup:backup Written batch ID: 65 Total document revisions written: 33000 Time: 97.907
2018-11-30T08:48:05.490Z couchbackup:backup Written batch ID: 69 Total document revisions written: 33500 Time: 98.493
2018-11-30T08:48:05.619Z couchbackup:backup Written batch ID: 67 Total document revisions written: 34000 Time: 98.628
```

### 7. Pas de donées dans la console VA<a id="Ancre7"></a>

1 Identifier l'IP et le port du service va-elasticsearch

```shell
kubectl get svc -n kube-system | grep va-ela
va-elasticsearch               ClusterIP   10.0.0.79    <none>        9200/TCP                              3h
va-elasticsearch-data          ClusterIP   None         <none>        9300/TCP                              3h
va-elasticsearch-master        ClusterIP   10.0.0.51    <none>        9300/TCP                              3h
```

2 Arrêter les replicaset py-indexer et sas_api

```yaml
kubectl edit deploy py-config-indexer -n kube-system
spec:
  replicas: 1   ---->0
  selector:
    matchLabels:

kubectl edit deploy sas-api-server -n kube-system
spec:
  replicas: 1   ---> 0
  selector:
    matchLabels:
      app: sas-api-server
```

2 Lancer un pods disposant de curl

L'image alpine-curl est disponible sur le cluster de build

3 Supprimer les index

```shell
curl -k -s -XDELETE http://10.0.0.79:9200/sas_info
curl -k -s -XDELETE http://10.0.0.79:9200/compliance-*
curl -k -s -XDELETE http://10.0.0.79:9200/vulnerabilityscan-*
curl -k -s -XDELETE http://10.0.0.79:9200/config-*
```

4 Réactiver les replicaset py-indexer et sas_api

```shell
kubectl edit deploy sas-api-server -n kube-system
kubectl edit deploy py-config-indexer -n kube-system
```

5 Redémarrer live-crawler, live-scan-proxy et reg-crawler

```shell
for pods in $(kubectl get pods | egrep -i "live|reg-crawler" | cut -d " " -f1)
do
kubectl delete pods $pods --cascade=true
done
```

### 8. impossible de changer les paramètres de policy VA<a id="Ancre8"></a>

Ce problème vient d'un soucis avec les index de VA-elasticsearch

1 Mise en évidence
On récupère l'IP et le port du service

```shell
kubectl get ep | grep va-elasticsearch
va-elasticsearch                         10.241.93.194:9200                                                    256d
```

Puis on fait un curl sur cette adresse depuis un containter qui en dispose, voir le fichier d'[exemple](sas_policy_mauvais)

```shell
 curl 10.241.93.194:9200/sas_policy/_mapping?pretty
```

2 Correction

On exécute ces commandes :

```shell
kubectl scale deploy sas-api-server --replicas=0
kubectl exec -ti alpine-curl-f968577cd-q65jg -- "curl -XDELETE http://10.241.93.194:9200/sas_policy"
kubectl scale deploy sas-api-server --replicas=1
```

On réessaie de changer une policy afin de regénérer l'index puis on reteste depuis un container qui a curl :

```shell
kubectl exec -ti alpine-curl-f968577cd-q65jg -- "curl 10.241.93.194:9200/sas_policy/_mapping?pretty"
```

Et on vérifie qu'il ressemble au fichier d'[exemple](sas_policy_bon)


### 9. impossible d'envoyer un requete curl trop longue<a id="Ancre9"></a>

1 Mise en évidence

Un requete curl ne fonctionne pas (timeout) si elle est trop longue.

2 Correction

Il faut appliquer une régle de post-routing sur les proxy node

```shell
for serveur in $(cat proxy.txt )
do
echo $serveur
ssh -q $serveur 'iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o eth0 -j TCPMSS --clamp-mss-to-pmtu'
done
```

### 10. ElasticSearch "Failed to create node environment" <a id="Ancre10"></a>

1- symptôme

Un pod elasticsearch-data sur un management node ne démarre pas correctement. Voici le résultat des logs :

```console
root@s00vl9998186:~$ kubectl -n kube-system logs elasticsearch-data-0
[2018-12-26T09:23:57,906][INFO ][o.e.n.Node               ] [] initializing ...
[2018-12-26T09:23:57,971][INFO ][o.e.e.NodeEnvironment    ] [2hqLezb] using [1] data paths, mounts [[/usr/share/elasticsearch/data (/dev/mapper/vg_apps-lv_ibm_cfc)]], net usable_space [80.4gb], net total_space [95.9gb], spins? [possibly], types [ext4]
[2018-12-26T09:23:57,971][INFO ][o.e.e.NodeEnvironment    ] [2hqLezb] heap size [990.7mb], compressed ordinary object pointers [true]
[2018-12-26T09:23:57,984][WARN ][o.e.b.ElasticsearchUncaughtExceptionHandler] [] uncaught exception in thread [main]
org.elasticsearch.bootstrap.StartupException: java.lang.IllegalStateException: Failed to create node environment
...
```

L'erreur à noter est "Failed to create node environment"

2- résolution

chercher le fichier .es_temp_file et le supprimer sur le management node impacté :

```shell
> find /opt/ibm/cfc/ -name *es_temp_file*
/opt/ibm/cfc/logging/elasticsearch/nodes/0/indices/rTFrFrr2SJWN2VrV3csVyA/.es_temp_file
> rm /opt/ibm/cfc/logging/elasticsearch/nodes/0/indices/rTFrFrr2SJWN2VrV3csVyA/.es_temp_file
rm: remove regular empty file ‘/opt/ibm/cfc/logging/elasticsearch/nodes/0/indices/rTFrFrr2SJWN2VrV3csVyA/.es_temp_file’? y
```

### 11. Le POD k8s-mariadb ne démarre pas<a id="Ancre11"></a>

1- symptôme

Un des POD k8s-mariadb ne démarre pas.
Les logs mariadb montrent l'erreur suivante :

```console
~$ kubectl  logs k8s-mariadb-s00vl9984067 mariadb
2018-12-27 13:19:41 140329051219712 [Warning] WSREP: 1.0 (s00vl9984053): State transfer to 0.0 (s00vl9984067) failed: -1 (Operation not permitted) 
```

Ces logs montrent que le serveur s00vl9984053 est le master.
Les logs du pod sur le master mettent en évidence le problème:

```console
~$ kubectl  logs k8s-mariadb-s00vl9984053 mariadb
2018-12-27 13:19:41 140548878890752 [Warning] WSREP: close file(/var/lib/mysql//gvwstate.dat.tmp) failed(No space left on device) 
```

Après vérification, le filesystem /var est bien full:

```console
root@s00vl9984053:~$ df -h | grep -i 100%
/dev/mapper/rootvg-var                                                             3.9G  3.9G  0.0G  100% /var
```

2- Impact

Cette erreur peut provoquer des problèmes d'authentification sur l'infrastructure.

Erreurs remontées par nos clients :

```
Cas 1 :
[Pipeline] withDockerRegistry
$ docker login -u c59897 -p ******** https://cloudngc01.group.echonet:8500
Error response from daemon: login attempt to https://cloudngc01.group.echonet:8500/v2/ failed with status: 401 Unauthorized

Cas 2 :
[Pipeline] withDockerRegistry
$ docker login -u c59897 -p ******** https://cloudngc01.group.echonet:8500
Login Succeeded
[Pipeline] {
[Pipeline] sh
[delivery-prod-opstore] Running shell script
+ deployFiles=("kubernetes/opstore-deployement-front.yml" "kubernetes/opstore-deployement-back.yml")
+ for file in '$deployFiles'
++ grep image: kubernetes/opstore-deployement-front.yml
++ awk '-Fimage: ' '{print $2}'
+ imagesToPush='{{RegistryUrl}}:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123
{{RegistryUrl}}:8500/bnpp-itg-8183-opstore/opstore_exposition_front_java:build_46'
+ for image in '$imagesToPush'
++ echo '{{RegistryUrl}}:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123'
++ sed -e 's/{{RegistryUrl}}/cloudngc01.staging.echonet/g'
++ echo '{{RegistryUrl}}:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123'
++ sed -e 's/{{RegistryUrl}}/cloudngc01.group.echonet/g'
+ docker tag cloudngc01.staging.echonet:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123 cloudngc01.group.echonet:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123
++ echo '{{RegistryUrl}}:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123'
++ sed -e 's/{{RegistryUrl}}/cloudngc01.group.echonet/g'
+ docker push cloudngc01.group.echonet:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache:build_123
The push refers to a repository [cloudngc01.group.echonet:8500/bnpp-itg-8183-opstore/opstore_exposition_front_apache]
2916c016bd57: Preparing
c070bc8a1d73: Preparing
......
unauthorized: authentication required
```

3- Résolution

Après analyse de l'occupation du filesystem /var, on observe un gros fichier dans /var/log/old:

```console
root@s00vl9984053:~$ ls -lrh /var/log/old/
total 2.3G
-rw-r----- 1 root root 6.5K Dec 26 11:33 secure-20181227
-rw-r----- 1 root root  22K Dec 21 17:00 secure-20181222
-rw-r----- 1 root root  18K Dec 20 22:08 secure-20181221
-rw-r----- 1 root root 8.6K Dec 19 14:13 secure-20181220
-rw-r----- 1 root root 2.3G Dec 27 03:35 messages-20181227
-rw-r----- 1 root root  16M Dec 26 03:28 messages-20181226
-rw-r----- 1 root root  17M Dec 25 03:20 messages-20181225
-rw-r----- 1 root root  19M Dec 24 03:48 messages-20181224
```

Ce fichier montre des logs récurrentes concernant le service kdump :

```shell
tail /var/log/old/messages-20181227
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: Another app is currently holding the kdump lock; waiting for it to exit...
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: flock: 9: Bad file descriptor
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: Another app is currently holding the kdump lock; waiting for it to exit...
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: flock: 9: Bad file descriptor
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: Another app is currently holding the kdump lock; waiting for it to exit...
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: flock: 9: Bad file descriptor
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: Another app is currently holding the kdump lock; waiting for it to exit...
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: flock: 9: Bad file descriptor
Dec 26 23:54:06 s00vl9984053 kdumpctl[1088]: Another app is currently holding the kdump lock; waiting for it to exit...
```

pour résoudre le problème il faut dans un premier temps écraser le fichier de logs volumineux, puis redémarrer le service kdump :

```shell
root@s00vl9984053:~$ cat > /var/log/old/messages-20181227
root@s00vl9984053:~$ systemctl restart kdump
```
### 12. Problème d'authenification sur la Plateforme L1C prod<a id="Ancre12"></a>

1- symptôme

Lorsque l'on essaye de connecter au portail ICP, nous rencontrons des soucis d'authentification avec des redirections vers le l'ingress interne du cluster. Il se peut que l'on obtienne aussi une erreur "Error response from server. Status code: 403; message: Error 403 : Access Forbidden"

2- Prise de logs et workarround

Récupératopn des logs de mariadb:

a. identifier les pods

```shell
kubectl get pod -n kube-system -o wide | grep -i maria
k8s-mariadb-s00vl9994547                                  2/2       Running   13         93d       10.241.204.16   s00vl9994547
k8s-mariadb-s00vl9994552                                  2/2       Running   6          7d        10.241.204.18   s00vl9994552
k8s-mariadb-s00vl9994554                                  2/2       Running   16         85d       10.241.204.23   s00vl9994554
```

b. Récupérer les outputs des commandes suivantes:

```shell
kubectl logs k8s-mariadb-s00vl9994547 -c mariadb -n kube-system
kubectl logs k8s-mariadb-s00vl9994552 -c mariadb -n kube-system
kubectl logs k8s-mariadb-s00vl9994554 -c mariadb -n kube-system
```

Une fois les logs récupérées, il faut utiliser l'ip d'un des pod au lieu du service name mariadb

```yaml
kubectl edit cm platform-auth-idp -n kube-system
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  BASE_AUTH_URL: /v1
  BASE_OIDC_URL: https://127.0.0.1:9443/oidc/endpoint/OP
  CLOUDANT_DB_NAME: platform-db
  CLUSTER_NAME: cloudngc01
  HTTP_ONLY: "true"
  IDENTITY_AUTH_DIRECTORY_URL: http://127.0.0.1:3100
  IDENTITY_AUTH_SERVICE: https://cloudngc01.group.echonet:8443/idauth
  IDENTITY_PROVIDER_URL: http://127.0.0.1:4300
  IDENTITY_URL: https://cloudngc01.group.echonet:8443
  MASTER_HOST: cloudngc01.group.echonet
  NODE_ENV: production
  OAUTH2DB_DB_HOST: mariadb 
  ```
  __=> à remplacer par l'IP de l'un des pods de mariadb__
  ```
  OAUTH2DB_DB_PORT: "3306"
  OIDC_ISSUER_URL: https://cloudngc01.group.echonet:9443/oidc/endpoint/OP
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"BASE_AUTH_URL":"/v1","BASE_OIDC_URL":"https://127.0.0.1:9443/oidc/endpoint/OP","CLOUDANT_DB_NAME":"platform-db","CLUSTER_NAME":"cloudngc01","HTTP_ONLY":"true","IDENTITY_AUTH_DIRECTORY_URL":"http://127.0.0.1:3100","IDENTITY_AUTH_SERVICE":"https://cloudngc01.group.echonet:8443/idauth","IDENTITY_PROVIDER_URL":"http://127.0.0.1:4300","IDENTITY_URL":"https://cloudngc01.group.echonet:8443","MASTER_HOST":"cloudngc01.group.echonet","NODE_ENV":"production","OAUTH2DB_DB_HOST":"mariadb","OAUTH2DB_DB_PORT":"3306","OIDC_ISSUER_URL":"https://cloudngc01.group.echonet:9443/oidc/endpoint/OP"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"platform-auth-idp","namespace":"kube-system"}}
  creationTimestamp: 2018-09-17T09:48:45Z
  name: platform-auth-idp
  namespace: kube-system
  resourceVersion: "32561605"
  selfLink: /api/v1/namespaces/kube-system/configmaps/platform-auth-idp
  uid: de227d68-ba5e-11e8-a6de-00505600bc1c

  
puis delete des pods auth-idp
kubectl delete pods k8s-mariadb-s00vl9994547 -c mariadb -n kube-system
kubectl delete pods k8s-mariadb-s00vl9994552 -c mariadb -n kube-system
kubectl delete pods k8s-mariadb-s00vl9994554 -c mariadb -n kube-system
```

Pour finir, il faut uploader les logs dans le tiket TS001533193 pour investigation d'IBM.

### 13. Les quotas ne sont pas mis à jour<a id="Ancre13"></a>

Identifier le master primaire en consultant, sur chaque master, les logs du controller-manager :

```shell
docker ps | grep hyper
```

Si les logs ressemblent à ça, le master n'est pas primaire :

```shell
docker logs 0174916a4e7a
I0919 09:42:27.329017       1 feature_gate.go:184] feature gates: map[TaintBasedEvictions:true PersistentLocalVolumes:true VolumeScheduling:true]
I0919 09:42:27.329102       1 controllermanager.go:108] Version: v1.9.1.1+icp-ee
I0919 09:42:27.333323       1 leaderelection.go:174] attempting to acquire leader lease...
E0919 09:42:27.333743       1 leaderelection.go:224] error retrieving resource lock kube-system/kube-controller-manager: Get https://127.0.0.1:8001/api/v1/namespaces/kube-system/endpoints/kube-controller-manager: dial tcp 127.0.0.1:8001: getsockopt: connection refused
```

Sur le master primaire, tuer le container k8s_controller-manager_k8s-master :

```shell
root@s00vl9985015:~$ docker ps | grep hyper
97b2ee85d1c7        7439f0c84857        "/hyperkube apiser..."   2 days ago          Up 2 days                               k8s_apiserver_k8s-master-s00vl9985015_kube-system_70309c07be393ed99cd95c61951c5ad8_24
a664c14d7eae        7439f0c84857        "/hyperkube contro..."   2 days ago          Up 2 days                               k8s_controller-manager_k8s-master-s00vl9985015_kube-system_70309c07be393ed99cd95c61951c5ad8_15
0bda392ef82b        7439f0c84857        "/hyperkube schedu..."   3 days ago          Up 3 days                               k8s_scheduler_k8s-master-s00vl9985015_kube-system_70309c07be393ed99cd95c61951c5ad8_14
cd2f6c054c5f        7439f0c84857        "/hyperkube proxy ..."   3 days ago          Up 3 days                               k8s_proxy_k8s-proxy-s00vl9985015_kube-system_f196507caa37cd16481b60f8db10ebf3_15

docker stop a664c14d7eae

docker rm a664c14d7eae
```

Vérifier ensuite qu'un nouveau container k8s_controller-manager_k8s-master a bien été régénéré et que les quotas d'une organisation ont bien été mis à jour.

### 14. Elasticsearch-data's PVC full (No space left on device elasticsearch-data)<a id="Ancre14"></a>

Procédure IBM: 

1 log onto the nodes and identify which workload directory is filling up

2 if clearing up elasticsearch data is needed (data WILL BE GONE, back up if needed)

  a scale down replica of kibana to 0 (take note of how many replicas you have)

  b. scale down replica of logstash to 0 (take note of how many replicas you have)

  c. scale down replica of elasticsearch data, master and client to 0 (take note of how many replicas you have)

  d. remove content INSIDE the elasticsearch data directory on ALL nodes that are running elasticsearch data pods

  e. restore replicas as noted before, in the reverse order of scale down

  f. wait a few minutes and logging should come back
  
### 15. Not enough space on device lors d'une installation de patch<a id="Ancre15"></a>
  
  Lors de l'installation de patches hyperkube ou docker sur ICP, les procédures IBM nous font lancer une commande utilisant l'image Inception. Cette image Inception lance un playbook ansible qui échoue régulièrement avec le message d'erreur, "not enough space on device". Cette erreur qui survient à l'étape de l'installation du patch est dû au fait que lors du lancement du script de patch sur un node, les scripts IBM essayent de décompresser l'archive du patch dans /tmp ou /root. Afin d'éviter ce genre de problème nous pouvons modifier les variables du script de patching afin d'utiliser /op/icp par exemple.
 
 
 Variables à modifier :
 
 ```shell
vim /opt/icp/ibm-cloud-private-3.1.1/cluster/patches/master/k8s-hyperkube-3.1.1-20181205-18594.patch
[...]
TMPROOT=${TMPDIR:=/opt/icp} # par défaut /tmp
[...]
targetdir="/opt/icp/k8s-hyperkube-3.1.1-20181205-18594" # par défaut k8s-hyperkube-3.1.1-20181205-18594
[...]
 ```
 
En lançant la commande patche vous obtiendrais une erreur sur le hash de l'archive décompressée. Afin de pallier à cette erreur, il faut récupérer le nouveau hash dans l'erreur et modifier la variable suivante dans le scipt de patching:

 ```shell
vim /opt/icp/ibm-cloud-private-3.1.1/cluster/patches/master/k8s-hyperkube-3.1.1-20181205-18594.patch
[...]
MD5="d62318a7125acaed2ef6ccae04bdb308" 
[...]
 ```

### 16. Orphan Pods Deletion<a id="Ancre16"></a>

Pour **nettoyer les orphan pods** sur les workers, utiliser le script 

Le lancer pour **chaque worker** (après l'avoir déployé) avec un *timeout* de 1m (sinon il *ne se termine pas*)

```shell
chmod u+x rm_orphans.sh
for i in $(cat icp/exploitation/workers.txt);do scp rm_orphans.sh $i:/opt/;done
for i in $(cat icp/exploitation/workers.txt);do echo $i;ssh -qT $i "timeout 1m /opt/rm_orphans.sh";done
```


### 17.réinstallation mgmt-repo après suppression de la release<a id="Ancre17"></a>

1- download du .tar sur une autre plateforme ICP de la même version. Example: https://cloudngc02.group.echonet:8443/mgmt-repo/requiredAssets/mgmt-repo-3.1.1-patch-20190107.tgz

2- upload de l'archive sur le boot node du cluster à réparer

3- Déploiement de la release Helm à partir de l'archive:
```
helm install mgmt-repo-3.1.1.tgz --name mgmt-repo --namespace kube-system  --set helminit.image.repository='cloudngh02.staging.echonet:8500/ibmcom/icp-helm-repo-init',mgmtrepo.image.repository='cloudngh02.staging.echonet:8500/ibmcom/icp-helm-repo',auditService.image.repository='cloudngh02.staging.echonet:8500/ibmcom/icp-audit-service',mgmtrepo.env.CLUSTER_CA_DOMAIN='cloudngh02.staging.echonet' --version 3.1.1-patch-20190107 --tls
```

Attention, il est important de mettre les bonnes values. Si vous vous trompez, vous pouvez suppirmer la release à partir de l'interface graphique et la recréer avec la commande helm et les bonnes values


### 18.Récuperer des helm charts dans l'image inception<a id="Ancre18"></a>

Dans certains cas, il se peut que les helm charts ne soient pas présent dans le catalog avec la bonne version.

Grâce à l'image inception, nous pouvons charger les charts que l'on souhaite en prenant la bonne version de l'image inception.

1. créer un répertoire chart dans `/opt/icp/ibm-cloud-private-3.X.X/cluster/` sur le boot node

    ```shell
    mkdir /opt/icp/ibm-cloud-private-3.X.X/cluster/chart
    ```

2. lancer l'image ineception, puis copier le binaire cloudctl et les archives des charts

    ```shell
    cd /opt/icp/ibm-cloud-private-3.X.X/cluster
    docker run -e LICENSE=accept -e ANSIBLE_REMOTE_TEMP=/opt/icp/.ansible/tmp --net=host --rm -ti -v "$(pwd)":/installer/cluster ibmcom/icp-inception-amd64:3.X.X-ee bash
    cp /addon/*.tgz /installer/cluster/chart/
    cp /usr/local/platform-api/cloudctl /installer/cluster/chart/
    exit
    ```
    
3. s'identifier avec la commande cloudctl login, puis charger les charts dans le catgalog en spécifiant la registry de la plate-forme

    ```shell
    cd /opt/icp/ibm-cloud-private-3.X.X/cluster/chart
    ./cloudctl login -n kube-system -a https://cloudngX0X.staging.echonet:8443
    for i in $(ls -lrth | awk '$9 ~ /tgz/ {print $9}' ); do ./cloudctl catalog load-chart --archive ./$i --registry cloudngX0X.staging.echonet:8500/ibmcom --trim-images --repo mgmt-charts --no-sync;done
    ```
    ne pas hésiter à relancer la boucle une seconde fois, s'il y a des échecs.
    
4. syncrhoniser les "helm repositories" sur la console ICP dans "https://cloudngx0x.staging.echonet:8443/catalog/repositories", bouton "sync all"

### 19.Résolution de l’incident Pod service-catalog-controller-manager CrashLoopBackOff (TS002723392) <a id="Ancre19"></a>

Après un fresh install de la version 3.2.0 le pod service-catalog-controller-manager est en statut CrashLoopBackOff et redémarre plusieurs fois.

1. Test de l'api

    ```shell
    kubectl get --raw /apis/servicecatalog.k8s.io/v1beta1/clusterserviceplans
    error: You must be logged in to the server (Unauthorized)
    ```


2. Vérifier le certificat (n’est pas expiré et signé par la bonne ca)

    ```shell
    openssl x509  -noout -text -in /etc/cfc/conf/front/front-proxy-client.pem
    ```

3. Comparer le <caBundle> dans le apiserver servicecatalog avec le <ca.cert> dans le secret service-catalog-apiserver-cert

    ```shell
    kubectl get apiservices v1beta1.servicecatalog.k8s.io -o yaml
    kubectl -n kube-system get secret service-catalog-apiserver-cert -o yaml
    ```
Enregistrer le caBundle et le ca.cert (en bade64) dans deux fichier d1.crt et c2.crt.
Puis comparer le md5sum des deux (02) fichier

```shell
    md5sum d1.crt
    a06780c513f90b8e5c30a65fd08f38f9 d1.crt
    md5sum d2.crt
    7772ae30f92b6cefd1e68d3326a273d2 d2.crt
```

4. Régénération des certificats cert/key


Nous allons mettre à jour les cert/key suivants:

   ```shell
   --proxy-client-cert-file=/etc/cfc/conf/front/front-proxy-client.pem
   --proxy-client-key-file=/etc/cfc/conf/front/front-proxy-client-key.pem
   --requestheader-client-ca-file=/etc/cfc/conf/front/front-proxy-ca.pem
   ```

Nous allons suivre les étapes suivantes:


•	Back up your installation dir cluster/cfc-certs. And remove cert file cluster/cfc-certs/front/front-proxy-ca.pem

•	Run installer to replace cert of front-proxy
   ```shell
   docker run -t -e LICENSE=accept --net host -v $(pwd):/installer/cluster ibmcom/icp-inception:3.2.0-ee replace-certificates --tag front-proxy-certs
   ```

•	Delete configmap extension-apiserver-authentication and restart kube-apiserver to make it recreated with new cert.
   ```shell
   kubectl -n kube-system delete configmap extension-apiserver-authentication
   ```

•	Delete service-catalog apiserver pod to make it restarted
   ```shell
   kubectl -n kube-system delete pods <service-catalog-apiserver pod>
   ```

•	Verify the service catalog API
   ```shell
   kubectl get --raw /apis/servicecatalog.k8s.io/v1beta1/clusterserviceplans
   ```

Pour plus de détails, merci de se réfèrer à la documentation IBM :
[https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/user_management/refresh_certs.html](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/user_management/refresh_certs.html)


5. Actions complémentaires

•	Delete configmap extension-apiserver-authentication

   ```shell
   kubectl -n kube-system delete configmap extension-apiserver-authentication
   ```

•	restart kube-apiserver

•	Delete service-catalog apiserver pod

   ```shell
   kubectl -n kube-system delete pods <service-catalog-apiserver pod>
   ```
•	Vérifier l’api  service catalog

   ```shell
   kubectl get --raw /apis/servicecatalog.k8s.io/v1beta1/clusterserviceplans
   {"kind":"ClusterServicePlanList","apiVersion":"servicecatalog.k8s.io/v1beta1","metadata":{"selfLink":"/apis/servicecatalog.k8s.io/v1beta1/clusterserviceplans","resourceVersion":"24434312"},"items":[]}
   ```

