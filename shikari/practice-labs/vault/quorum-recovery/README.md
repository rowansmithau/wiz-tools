# Quorum Recovery

This scenario builds Vault cluster with Integrated Storage with TLS. Specify the size of the cluster by setting number of servers using the `--servers/-s` flag.

This scenario should be created with three servers/nodes.

Additionally, it then breaks quorum so you perform a quorum recovery. Once you have restored quorum you can validate the presence of a KV entry in order to confirm the original data is present.

This scenario typically takes around 40-60s to build.

## Prerequisities

This scenario includes the use of Consul as part of the bootstrap process. If you chose to use the enterprise binaries when building your image with packer, you will 
need to supply a license for both Vault and Consul - see the build command below for an example.

### Build

The following steps will build a Vault cluster.

```
shikari create -n <cluster_name> -s 3 -e VAULT_LICENSE=$(cat <vault_license_file>) -e CONSUL_LICENSE=$(cat <consul_license_file>)
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