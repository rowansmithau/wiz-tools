# Shikari scenarios for HashiCorp engineers
A collection of Lima Templates that will be used with Shikari.

## Prerequisites

The following tools are required to run these scenarios:

* HashiCorp [Packer](https://developer.hashicorp.com/packer) (if you are building custom images)
* CDRtools (if you are building custom images)
* [Lima](https://lima-vm.io/)
* [Shikari](https://github.com/ranjandas/shikari)

You can use the [Brewfile](Brewfile) shipped in this repository to install all the dependent tools.

```
$ brew bundle
Using hashicorp/tap
Tapping ranjandas/shikari
Installing ranjandas/shikari/shikari
Using hashicorp/tap/packer
Using hashicorp/tap/nomad
Using hashicorp/tap/consul
Using cdrtools
Using qemu
Using lima
Using socket_vmnet
Homebrew Bundle complete! 10 Brewfile dependencies now installed.
```

### Setup socket_vmnet

The following commands must be run once to complete the required socket_vmnet configuration.

```
$ limactl sudoers > etc_sudoers.d_lima
$ sudo install -o root etc_sudoers.d_lima /etc/sudoers.d/lima
```

### Run Test VM

Run a test VM to verify socket_vmnet is configured properly. Verify that the `lima0` interface inside the VM has an IP Address.

```
$ limactl start template://alpine --network=lima:shared

$ limactl shell alpine ifconfig lima0
lima0     Link encap:Ethernet  HWaddr 52:55:55:96:B6:B1
          inet addr:192.168.105.2  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::5055:55ff:fe96:b6b1/64 Scope:Link
          inet6 addr: fdff:bed9:f801:6df1:5055:55ff:fe96:b6b1/64 Scope:Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:6 errors:0 dropped:0 overruns:0 frame:0
          TX packets:9 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1252 (1.2 KiB)  TX bytes:1291 (1.2 KiB)

```

Remove the test instance.

```
$ limactl stop alpine; limactl delete alpine
```

Once the above pre-requisites are met you can proceed with using Shikari to launch scenarios, such as the ones in this repo.

## Usage - Quickstart Example

The following steps will build a VM image with Consul and Nomad installed, which will be used as the source of the VMs created using Shikari.

1. Build the base VM image

    ```
    $ cd packer
    $ packer init hashibox.pkr.hcl
    $ packer build -var-file variables.pkrvars.hcl hashibox.pkr.hcl
    ```
    > NOTE: Pass `-var enterprise=true` for Enterprise binaries and `-var fips=true` for fips binaries repsectively.
    
    This will build the VM image into the `.shikari` directory within your home directory (`~/.shikari`).

2. Now you can run the scenarios by going into specific scenario directory and invoking the template using Shikari.

    ```
    $ cd scenarios/nomad-consul-quickstart
    $ shikari create --name demo --servers 3 --clients 3 -i ~/.shikari/<image-dir>/<image-file>.cqow2
    ```

    > NOTE: You can avoid passing the image on the CLI by setting the `image.location` inside the template file (hashibox.yaml) to point to the newly created image file in the previous step. (this should end with `.qcow2`). Run the following command to get the absolute path to the image file, for example:
    > ```
    > $ readlink -f ~/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    > /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    > ```

    The above example command will create 3 servers and 3 clients using the image we previously built using Packer.

3. Export the environment variables to access the cluster services.

    ```
    $ eval $(shikari env -n demo consul)
    ```

4. The `shikari list` command can be used to view a list of vm's and their status.

    ```
    $ shikari list
    CLUSTER    VM NAME        IP(lima0)         STATUS     SCENARIO                   DISK(GB)    MEMORY(GB)    CPUS    IMAGE
    demo       demo-cli-01    192.168.105.8     Running    nomad-consul-quickstart    100         4             4       /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    demo       demo-cli-02    192.168.105.9     Running    nomad-consul-quickstart    100         4             4       /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    demo       demo-cli-03    192.168.105.10    Running    nomad-consul-quickstart    100         4             4       /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    demo       demo-srv-01    192.168.105.6     Running    nomad-consul-quickstart    100         4             4       /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    demo       demo-srv-02    192.168.105.5     Running    nomad-consul-quickstart    100         4             4       /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    demo       demo-srv-03    192.168.105.7     Running    nomad-consul-quickstart    100         4             4       /Users/Billy/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
    ```

5. A shell can be opened in a VM using the `shikari shell <vm-name>` command, or commands can be run in one or more VM's from your local shell using the `shikari exec <vm-name>` command.

```
$ shikari shell -h         
Get a shell inside the VM

Usage:
 shikari shell <vm-name>

Flags:
 -h, --help help for shell
```

```
$ shikari exec -h                                     
Execute commands inside the VMs. For example:

You can run commands against specific class of servers (clients, servers or all)

Usage:
  shikari exec [flags]

Flags:
  -a, --all               run commands against all instances in the cluster
  -c, --clients           run commands against client instances in the cluster
  -h, --help              help for exec
  -i, --instance string   name of the specific instance to run the command against
  -n, --name string       name of the cluster to run the command against
  -s, --servers           run commands against server instances in the cluster
```

## Creating Scenarios

See the [scenario creation guide](scenario-creation.md).

---

## Frequently Asked Questions

**Q: Can I use a mix of enterprise and community edition binaries when creating an image?**

**A:** No, at present you must make the decision when creating the image as to whether all products will use enterprise or community edition binaries, there is no ability to specify a mix, for example, Vault Enterprise and Consul Community Edition.

**Q: Which apps are installed by default?**

**A:** Docker, Consul, Nomad, Boundary, Vault.

**Q: How do I configure the amount of disk/CPU/memory assigned to each VM?**

**A:** Compute resource assignment is controlled in the `hashibox.yaml` Lima template file for each scenario (undefined in our existing scenarios as of writing) and defaults to 4 CPU, 4GB memory, 100GB thin provisioned disk. See the [Lima repo's template](https://github.com/lima-vm/lima/blob/74e2fda81b8d367a3bee3dcec92f2b83f575460b/examples/default.yaml#L40-L50) for an example of how to customise this.

**Q: Why does Shikari keep showing a message like `[hostagent] Waiting for the final requirement 1 of 1: "boot scripts must have finished"`?**

**A:** This typically means one of tasks you have configured in `hashibox.yaml` is either yet to complete or has failed unexpectedly. `hashibox.yaml` effectively becomes a [cloud-init](https://cloud-init.io/) provisioning script (translation to cloud-init is performed by Lima), and cloud-init expects all scripts to complete with an exit code of 0, i.e. successfully completed. When an action/step in `hashibox.yaml` does not complete or complete successfully it will result in the VM(s) failing to start and the above message appearing in Shikari's CLI output.

**Q: How do I determine why my scenario/VM failed to start?**

**A:** First, identify the name of the VM which is experiencing the issue as depending on the steps you are executing the issue may be present on just one VM. Second, open a shell on the VM in question by running `shikari shell <vm-name>`. Last, check the output of `cloud-init status` and review `/var/log/cloud-init.log` and `/var/log/cloud-init-output.log` (requires root/sudo). The `/var/log/cloud-init-output.log` file will often be the most helpful as it details the output of the scripts run at startup.

**Q: How do I provide a license for each of the HashiCorp products when creating a scenario?**

**A:** When running `shikari create` you must supply the license for each product individually, including specifying the the `-e` flag for each product/variable. For example:

```
shikari create -n demo -s 3 -e VAULT_LICENSE=$VAULT_LICENSE -e CONSUL_LICENSE=$(cat ~/consul.license) -i ~/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2
```

You can either provide a reference to an existing environment variable present on your host machine (used in the Vault example) or by referencing the license file on disk (used in the Consul example).

**Q: How do I ensure a step/script is only executed at first boot?**

**A:** Existing scenarios use the pattern of creating a file as one of the very last steps (`touch /shikari-bootstrapped`) which is referenced in one of the very first steps to check for - if the file exists the step is skipped:

```
      # avoid running the script on restarts
      if [[ -f /shikari-bootstrapped ]] then
        exit 0
      fi
```

**Q: How can I ensure only one specific VM completes a step, i.e `vault operator init`?**

**A:** When creating a step you can use a similar pattern to the previous question to target a specific hostname, for example `if [[ "$HOSTNAME" == *"01"* ]]; then`. Consult existing scenarios for working examples. 

**Q: VM's suddenly fail to start with an error message like `error calling fd_connect: fd_connect: dial unix /private/var/run/lima/socket_vmnet.shared: connect: connection refused"` or they don't receive IP addresses on the lima0 interface**

**A:** Issues have been experienced along these lines and appear to be related to `socket_vmnet`. Though they are not yet fully understood / a consistent root cause is yet to be identified for each occurrence, we have observed that running `sudo ifconfig bridge100 destroy; sudo /bin/launchctl kickstart -kp system/com.apple.bootpd` can help resolve the issue.