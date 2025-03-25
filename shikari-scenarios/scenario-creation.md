# Creating Scenarios

While some common scenarios are included in this repo the power of Shikari lies in the ability to create custom scenarios, either for your own use case or to be added to this repo and shared with the team. By creating and sharing custom scenarios we can all benefit from quicker and easier reproductions and more efficiently provide training.

In order to create scenarios you must have a working Shikari setup, i.e. the prerequisites at the beginning of this document must be met. Once you have confirmed the ability to run existing scenarios you can begin to create new scenarios.

To get started we recommend considering the following:

1. Do you plan to use the enterprise or community edition of the HashiCorp products? This decision must be made when building the image using Packer and affects all HashiCorp products within the image being built. If required you can consider creating two images, one with enterprise binaries and one with community edition binaries.
2. Can you make use of an existing scenario to form the baseline for your scenario? For example, [scenarios/vault-integrated-storage](scenarios/vault-integrated-storage) creates a three node Vault cluster which you can add your own custom steps to. This means the work involved in creating a scenario is often just adding the last custom steps.

The process generally has three steps:

1. Create a base image using packer.
2. Create the scenario file (`hashibox.yaml`).
3. Test and verify the scenario.

---

## 1. Base Image Build Process

**1.1:** Review [packer/hashibox.pkr.hcl](packer/hashibox.pkr.hcl) and make any desired changes. You likely won't need to make any changes, but it is good to understand the content of this file as it is the basis for the image.

**1.2:** Review [packer/variables.pkrvars.hcl](packer/variables.pkrvars.hcl) and make any desired changes. You can define the HashiCorp product versions, enterprise/CE and FIPS either in this file or pass them as variables when building the image.

**1.3:** Open a shell in the `packer` directory and run `packer init hashibox.pkr.hcl`, followed by `packer build -var-file variables.pkrvars.hcl hashibox.pkr.hcl`. If you're opting to pass variables to the build process the `build` command should be appended accordingly, i.e. `packer build -var-file variables.pkrvars.hcl hashibox.pkr.hcl -var enterprise=true -var fips=true -var vault_version=1.17.3`.

**1.4:** Providing the packer build process completes without issue the final line of output will detail the image's location on disk: `--> qemu.hashibox: VM files in directory: /Users/rowan/.shikari/c-1.19-n-1.8-v-1.17.3-b-0.16-fedora`. Builds containing the enterprise binaries have the directory name prefixed with `enterprise`.

Unless you plan to switch between enterprise/CE, fips/non fips etc, you typically only need to complete the image build process once as the image is immutable and can be reused across many scenarios. If you created an image with CE binaries and wish to use enterprise functionality you will need to create an additional image.

## 2. Create the scenario file

**2.1:** Determine if you can make use of an existing scenario's `hashibox.yaml` as the baseline for your scenario. Examples for Vault, Consul, Nomad, Boundary and Kubernetes are available in the [scenarios](scenarios) directory, often using one of these as a starting point will help.

**2.2:** Add a new step below the current last script entry in `hashibox.yaml`. Using [scenarios/vault-integrated-storage/hashibox.yaml#L162-L164](scenarios/vault-integrated-storage/hashibox.yaml#L162-L164) as an example it would look as follows after making the change:

```
162      touch /shikari-bootstrapped
163
164  - mode: system # a follow up step which configures Vault 
165    script: |
166      #!/usr/bin/env bash
167      
168      vault secrets enable kv
169 
170 copyToHost:
```

As we can see each entry in the example `hashibox.yaml` is executed using the script function in the bash shell, however many options/functions exist within the Lima templating system and can be used here. Consulting [https://github.com/lima-vm/lima/blob/master/examples/default.yaml](https://github.com/lima-vm/lima/blob/master/examples/default.yaml) can help with finding examples to learn from.

**2.3:** Populate your script step with the actions you would like to be performed. It is good to consider the following:

* Does the step require authentication (Vault / Consul token)?
* Scripts/steps are executed sequentially, however if you target actions to specific nodes you should remember the other nodes will continue on with their own steps at the same time. This can affect timing of operations and dependencies, for example if you initialise Vault on one node it will take time to complete that step, mean while the other Vault nodes in the cluster will have skipped the initialisation step and will be attempting to join a leader node which may not yet be ready.
* For the scenario to start successfully all operations within the script must complete and complete successfully. For example, if you ran the `ping` command as a last step it will continue to run forever and the scenario will not complete the boot process.

**2.4:** Add any other additional steps and save the file.

**2.5:** Test the scenario by starting it up. Open a local shell inside the directory where your custom `hashibox.yaml` has been created and run the relevant `create` command, for example `shikari create -n demo -s 3 -e VAULT_LICENSE=$VAULT_LICENSE -e CONSUL_LICENSE=$CONSUL_LICENSE -i ~/.shikari/enterprise-c-1.19-n-1.8-v-1.17-b-0.16/hashibox.qcow2`

**2.6:** Observe the output printed on screen. A successul boot should result in the `Lima VM demo-srv-01 spawned successfully.` message appearing for each of your VM's. Assuming your VM's boot successfully you can then use the `shikari shell` command to open a shell on VM's in order to inspect your creation.

**2.7:** If your scenario failed to start you will either see output directly in your shell or you may need to open a shell and take a closer look. Per the FAQ in the [README](README.md) you can consult `/var/log/cloud-init.log` and `/var/log/cloud-init-output.log` to view the output from each of the steps you asked the VM to run and work through any issues.

**2.8:** Consider the reusability of your scenario - does it decrease the time to create a reproduction, and would it be of benefit to others? If so, you should create a pull request in this repo so that others can use your scenario as well.