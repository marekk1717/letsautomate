# letsautomate1
1. Terraform will spin up new VM in Azure based on the Oracle Enterprise 12 OS image provided by Oracle. VM will be configured in selected Resource Group and added to Azure Virtual Network. 
2. Once VM is created, Terraform will execute Ansible playbook with the following steps:<br>
a) upload new .bash_profile for "oracle" user on target VM<br>
b) create new sample Oracle Database by using dbca tool<br>
c) enable Archivelog mode on Oracle database by using sqlplus and sql script<br>
d) copy rpm with Commvault silent installer package (File System + Oracle Agent) to target VM<br>
e) execute Commvault silent installer on Oracle VM<br>
f) create new Oracle Instance on the Commserve by using qcommands<br>
g) create new "Online" subclient for the purposes of Full/Inc backups<br>
h) create new "Logonly" subclient for the purposes of Archivelog backups<br>
i) associate both subclients with existing schedule policies<br>
j) start first full backup of Oracle database<br>
