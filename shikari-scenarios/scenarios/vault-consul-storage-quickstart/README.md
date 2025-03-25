# Consul as Storage Backend for Vault

This is a quickstart scenario for Consul as Storage Backend for Vault without ACLs and TLS implementation. Consul clients are installed within Vault servers


### Usage

#### Create

Use the following command to launch the scenario using Shikari.
```
$ shikari create --name murphy \
                 --servers 3 \
                 --clients 3 \
                 --env CONSUL_LICENSE=$(cat /location/to/consul/license) \
                 --env VAULT_LICENSE=$(cat /location/to/vault/license) \
                 --image  ~/.shikari/<image_dir>/<image-file>.qcow2

```
#### List

List the VMs in the cluster
```
$ shikari list
CLUSTER       VM NAME             SATUS         DISK(GB)       MEMORY(GB)       CPUS
murphy        murphy-cli-01       Running       100            4                4
murphy        murphy-cli-02       Running       100            4                4
murphy        murphy-cli-03       Running       100            4                4
murphy        murphy-srv-01       Running       100            4                4
murphy        murphy-srv-02       Running       100            4                4
murphy        murphy-srv-03       Running       100            4                4
```


#### Access

You can export the required environment variables to access both Vault and Consul
```
$ eval $(shikari env -n murphy consul)
$ export VAULT_ADDR=http://lima-murphy-cli-01.local:8200
$ eval "export $(shikari exec -n murphy -i cli-01 env | grep TOKEN)"
```

#### Environment:
- `lima-murphy-srv-xx` : Consul servers
- `lima-murphy-cli-xx` : Vault Servers with Consul clients

- Snippet of example cluster below, where `lima-murphy-srv-xx` are consul backend servers, and `lima-murphy-cli-xx` are Vault servers, also running Consul client agents

$ env|egrep 'CONSUL|NOMAD'

$ consul members
Node                Address              Status  Type    Build   Protocol  DC      Partition  Segment
lima-murphy-srv-01  192.168.105.13:8301  alive   server  1.18.2  2         murphy  default    <all>
lima-murphy-srv-02  192.168.105.12:8301  alive   server  1.18.2  2         murphy  default    <all>
lima-murphy-srv-03  192.168.105.11:8301  alive   server  1.18.2  2         murphy  default    <all>
lima-murphy-cli-01  192.168.105.10:8301  alive   client  1.18.2  2         murphy  default    <default>
lima-murphy-cli-02  192.168.105.14:8301  alive   client  1.18.2  2         murphy  default    <default>
lima-murphy-cli-03  192.168.105.9:8301   alive   client  1.18.2  2         murphy  default    <default>


$ vault status                                        
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.15.5+ent
Build Date      2024-01-26T21:04:45Z
Storage Type    consul
Cluster Name    vault-cluster-a9fc7877
Cluster ID      4d12d18c-7e3c-3d3d-ae7d-f92c9db91cd2
HA Enabled      true
HA Cluster      http://lima-murphy-cli-01.local:8201
HA Mode         active
Active Since    2024-09-11T23:26:25.420508309Z
Last WAL        24

```

#### Destroy

```
$ shikari destroy -f -n murphy
```