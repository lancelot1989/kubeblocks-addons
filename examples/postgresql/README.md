# Postgresql

PostgreSQL (Postgres) is an open source object-relational database known for reliability and data integrity. ACID-compliant, it supports foreign keys, joins, views, triggers and stored procedures.

## Prerequisites

This example assumes that you have a Kubernetes cluster installed and running, and that you have installed the kubectl command line tool and helm somewhere in your path. Please see the [getting started](https://kubernetes.io/docs/setup/)  and [Installing Helm](https://helm.sh/docs/intro/install/) for installation instructions for your platform.

Also, this example requires KubeBlocks installed and running. Here is the steps to install kubeblocks, please replace "`$kb_version`" with the version you want to use.
```bash
# Add Helm repo
helm repo add kubeblocks https://apecloud.github.io/helm-charts
# If github is not accessible or very slow for you, please use following repo instead
helm repo add kubeblocks https://jihulab.com/api/v4/projects/85949/packages/helm/stable

# Update helm repo
helm repo update

# Get the versions of KubeBlocks and select the one you want to use
helm search repo kubeblocks/kubeblocks --versions
# If you want to obtain the development versions of KubeBlocks, Please add the '--devel' parameter as the following command
helm search repo kubeblocks/kubeblocks --versions --devel

# Create dependent CRDs
kubectl create -f https://github.com/apecloud/kubeblocks/releases/download/v$kb_version/kubeblocks_crds.yaml
# If github is not accessible or very slow for you, please use following command instead
kubectl create -f https://jihulab.com/api/v4/projects/98723/packages/generic/kubeblocks/v$kb_version/kubeblocks_crds.yaml

# Install KubeBlocks
helm install kubeblocks kubeblocks/kubeblocks --namespace kb-system --create-namespace --version="$kb_version"
```

## Examples

### [Create](cluster.yaml)
Create a postgresql cluster with two replicas:
```bash
kubectl apply -f examples/postgresql/cluster.yaml
```
You will see two pods, one headless service and one ClusterIP service created.
And you will see the postgresql cluster status is `Running` and each pod is `Running` with roles `primary` and `secondary`.

```bash
kubectl get pods,svc,cluster
```

To check the postgresql Pods roles, you can use following command:
```bash
kubectl get po -l  app.kubernetes.io/instance=<cluster-name> -L kubeblocks.io/role
```
Or login to the pod and use `patronictl` to check the roles:
```bash
kubectl exec -it <pod-name> -n default -- patronictl list
```

To create a postgresql cluster with a specified version, you can modify the `spec.componentSpecs.serviceVersion` field in the yaml file.
The list of supported versions can be found in
```bash
kubectl get cmpv postgresql
```

### Horizontal scaling

#### [Scale-out](scale-out.yaml)
Horizontal scaling out postgresql cluster by adding one more replica:
```bash
kubectl apply -f examples/postgresql/scale-out.yaml
```

After the operation, you will see a new pod created and the postgresql cluster status is `Running` and the newly created pod has a new role `secondary`.

#### [Scale-in](scale-in.yaml)
Horizontal scaling in postgresql cluster by deleting one replica:
```bash
kubectl apply -f examples/postgresql/scale-in.yaml
```
After the operation, you will see one pod deleted and the postgresql cluster status is `Running`.


Beside the yaml file, you can also use `kubectl edit` to scale in the cluster:
```bash
kubectl edit cluster pg-cluster
```
And modify the `replicas` field in the `spec.componentSpecs.replicas` section to the desired number.

### [Vertical scaling](verticalscale.yaml)
Vertical scaling up or down specified components requests and limits cpu or memory resource in the cluster
```bash
kubectl apply -f examples/postgresql/verticalscale.yaml
```
You will notice that the `secondary` pod is recreated first, followed by the `primary` pod, to ensure the availability of the cluster.

### [Expand volume](volumeexpand.yaml)
Increase size of volume storage with the specified components in the cluster
```bash
kubectl apply -f examples/postgresql/volumeexpand.yaml
```
After the operation, you will see the volume size of the specified component is increased to `30Gi` in this case.
You can check the volume size with following command:
```bash
kubectl get pvc
```

Make sure the storage class you use supports volume expansion, you can check the storage class with following command:
```bash
kubectl get sc
```
If the `ALLOWVOLUMEEXPANSION` column is `true`, the storage class supports volume expansion.

you can also use `kubectl edit` to expand the volume:
```bash
kubectl edit cluster pg-cluster
```
And modify the `spec.componentSpecs.volumeClaimTemplates.spec.resources.requests.storage` field to the desired size.

### [Restart](restart.yaml)
Restart the specified components in the cluster
```bash
kubectl apply -f examples/postgresql/restart.yaml
```

### [Stop](stop.yaml)
Stop the cluster and release all the pods of the cluster, but the storage will be reserved
```bash
kubectl apply -f examples/postgresql/stop.yaml
```

You can also use `kubectl edit` to stop the cluster:
```bash
kubectl edit cluster pg-cluster
```
And modify the `spec.componentSpecs.stop` field to `true`.


### [Start](start.yaml)
Start the stopped cluster
```bash
kubectl apply -f examples/postgresql/start.yaml
```

You can also use `kubectl edit` to stop the cluster:
```bash
kubectl edit cluster pg-cluster
```
And modify the `spec.componentSpecs.stop` field to `false` or remove the `spec.componentSpecs.stop` field.

### [Switchover](switchover.yaml)
Switchover a non-primary or non-leader instance as the new primary or leader of the cluster
```bash
kubectl apply -f examples/postgresql/switchover.yaml
```

By applying this yaml file, KubeBlocks will perform a switchover operation defined in postgresql's component definition, and you can checkout the details in `componentdefinition.spec.lifecycleActions.switchover`.

### [Switchover-specified-instance](switchover-specified-instance.yaml)
Switchover a specified instance as the new primary or leader of the cluster
```bash
kubectl apply -f examples/postgresql/switchover-specified-instance.yaml
```

You may need to modify the `opsrequest.spec.switchover.instanceName` field to the desired `secondary` instance name. By applying this yaml file, the `secondary` instance you specified will be promoted to the new primary instance.

### [Reconfigure](configure.yaml)
Reconfigure parameters with the specified components in the cluster
```bash
kubectl apply -f examples/postgresql/configure.yaml
```
This example will change the `max_connections` to `200`.

### [BackupRepo](backuprepo.yaml)
BackupRepo is the storage repository for backup data, using the full backup and restore function of KubeBlocks relies on BackupRepo

Before creating a BackupRepo, you need to create a secret to save the access key of the backup repository
```bash
# Create a secret to save the access key
kubectl create secret generic demo-credential-for-backuprepo\
  --from-literal=accessKeyId=<ACCESS KEY> \
  --from-literal=secretAccessKey=<SECRET KEY> \
  -n kb-system
```

Update the `examples/postgresql/backuprepo.yaml` file, and tail fields quoated with `<>` to your own settings and apply it.
```bash
kubectl apply -f examples/postgresql/backuprepo.yaml
```

After creating the BackupRepo, you can check the status of the BackupRepo with following command:
```bash
kubectl get backuprepo
```
And the expected output is like:
```bash
NAME     STATUS   STORAGEPROVIDER   ACCESSMETHOD   DEFAULT   AGE
kb-oss   Ready    oss               Tool           true      19h
```

### [Backup]
You can create a backup for the cluster with different methods, such as `pg-basebackup`, `volume-snapshot`, `wal-g`, etc.
The list of supported backup methods can be found in
```bash
kubectl get backuppolicy pg-cluster-postgresql-backup-policy # pg-cluster is the cluster name, postgresql is the component name
```
#### [pg-basebackup](backup.yaml)
To create a full backup with `pg-basebackup` for this cluster:
```bash
kubectl apply -f examples/postgresql/backup.yaml
```

After the operation, you will see a new backup created and the status of the backup is `Running` and a K8s Job is created to perform the backup.

```bash
kubectl get backup pg-cluster-backup -n default
```

#### [wal-g]

To Create wal-g backup for the cluster

1. you cannot do wal-g backup for a brand-new cluster, you need to insert some data before backup

1. config-wal-g backup to put the wal-g binary to postgresql pods and configure the archive_command

```bash
kubectl apply -f examples/postgresql/config-wal-g.yaml
```

1. set `archive_command` to `wal-g wal-push %p`

```bash
kubectl apply -f examples/postgresql/backup-wal-g.yaml
```

1. connect to the cluster, and manually upload wal with following sql statement

```sql
select pg_switch_wal();
```

> Note: if there is horizontal scaling out new pods after step 2, you need to do config-wal-g again

### [Restore](restore.yaml)

To restore a new cluster from a Backup:

1. Get backup connection password

```bash
kubectl get backup pg-cluster-backup -ojsonpath='{.metadata.annotations.kubeblocks\.io/encrypted-system-accounts}'
```
2. Update the `examples/postgresql/restore.yaml` file, and tail fields quoated with `<>` to your own settings and apply it.

```bash
kubectl apply -f examples/postgresql/restore.yaml
```

### Expose
Expose a cluster with a new endpoint
#### [Enable](expose-enable.yaml)
```bash
kubectl apply -f examples/postgresql/expose-enable.yaml
```
#### [Disable](expose-disable.yaml)
```bash
kubectl apply -f examples/postgresql/expose-disable.yaml
```

### [Upgrade](upgrade.yaml)
Upgrade postgresql cluster to another version
```bash
kubectl apply -f examples/postgresql/upgrade.yaml
```
In this example, the cluster will be upgraded to version `14.8.0`.
You can check the available versions with following command:
```bash
kubectl get cmpv postgresql
```
And you can also use `kubectl edit` to upgrade the cluster:
```bash
kubectl edit cluster pg-cluster
```
And modify the `spec.componentSpecs.serviceVersion` field to the desired version.

You are suggested to check the compatibility of versions before upgrading, using command:
```bash
kubectl get cmpv postgresql -ojson | jq '.spec.compatibilityRules'
```

The expected output is like:
```json
[
  {
    "compDefs": [
      "postgresql-12-"
    ],
    "releases": [
      "12.14.0",
      "12.14.1",
      "12.15.0"
    ]
  },
  {
    "compDefs": [
      "postgresql-14-"
    ],
    "releases": [
      "14.7.2",
      "14.8.0"
    ]
  }
]
```

Releases are grouped by component definitions, and each group has a list of compatible releases.
In this example, it shows you can upgrade from version `12.14.0` to `12.14.1` or `12.15.0`, and upgrade from `14.7.2` to `14.8.0`.
But cannot upgrade from `12.14.0` to `14.8.0`.

### Delete
If you want to delete the cluster and all its resource, you can modify the termination policy and then delete the cluster
```bash
kubectl patch cluster pg-cluster -p '{"spec":{"terminationPolicy":"WipeOut"}}' --type="merge"

kubectl delete cluster pg-cluster
```
