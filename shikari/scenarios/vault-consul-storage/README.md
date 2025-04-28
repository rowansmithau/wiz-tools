# Vault Consul Storage

This scenario builds Vault cluster with Consul Storage with TLS. Specify the size of the cluster by setting number of servers using the `--servers/-s` flag.

## Usage


### Build

The following steps will build a Vault cluster.

```
shikari create -n <cluster_name> -s 3 -e VAULT_LICENSE=$(cat <vault_license_file>)
```

### Access

Export the Vault environment variable using the following command

```
eval $(shikari env -n <cluster_name> vault --tls)
```

Extract the Vault Token from the first server.

```
eval "export $(shikari exec -n <cluster_name> -i srv-01 env | grep TOKEN)"
```

### Destroy

```
shikari destroy -n <cluster_name> -f
```