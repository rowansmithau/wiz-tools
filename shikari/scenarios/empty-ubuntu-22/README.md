# Scenario: Empty

This scenario launches the cluster but doesn't include any provisioning scripts and as a result won't configure or start any services.

This can be used when learning to configure and build clusters manually. The scenario takes care of the networking and other necessary VM level configurations.

## Prerequsites

This scenario has the following pre-requsites:

* Requires a base VM image built using packer (`../../packer/hashibox.pkr.hcl`)

### Usage

#### Create

Use the following command to launch the scenario using Shikari.

```
$ shikari create --name murphy \
                 --servers 3 \
                 --clients 3 \
                 --image ../../packer/.artifacts/<imagedir>/<image-file>.qcow2
```

#### List

List the VMs in the cluster

```
shikari list
CLUSTER       VM NAME             SATUS         DISK(GB)       MEMORY(GB)       CPUS
murphy        murphy-cli-01       Running       100            4                4
murphy        murphy-cli-02       Running       100            4                4
murphy        murphy-cli-03       Running       100            4                4
murphy        murphy-srv-01       Running       100            4                4
murphy        murphy-srv-02       Running       100            4                4
murphy        murphy-srv-03       Running       100            4                4
```


#### Access

You can export the required environment variables to access the required products

Example:

```
$ eval $(shikari env -n murphy -ta consul)
$ eval $(shikari env -n murphy -ta nomad)
```

> NOTE: While this command works, you have to make sure that the services are configured and started to access it.


#### Destroy

```
$ shikari destroy -f -n murphy
```
