# SQLR
Short Term Memory Q-Learning for VM provisioning

The scripts are grouped according to the node they should run on.

1. Source - These generate requests to be served by the provisioned VMs on the Host. The cron jobs start the server tasks which listen to the responses on different ports
2. Host - These scripts run on the physical server that spawns the virtual machines. The hypervisor is KVM and the VM manager is libvirt
3. VM - These scripts run on the provisioned virtual machines. The startHash.sh script should be triggered as part of the boot process of a VM, it launches the requisite scripts that run the requested service on the VM

NB: Source/cronScripts schedule when the traffic generator scripts should run
NB: Host/HostCron schedule when the host listens to the ports to allow/restrict more requests coming in from the Source PC
