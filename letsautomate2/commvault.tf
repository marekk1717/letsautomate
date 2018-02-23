variable "vm_name" {
  default = "commserve"
}

variable "vm_network" {
  default = "vnet_cv_demo"
}

variable "vm_subnet" {
  default = "vnet_cv_demo_subnet1"
}

variable "resource_group" {
  default = "rg_cv_demo"
}

variable "region" {
  default = "uksouth"
}

variable "vm_type" {
  default = "Standard_DS3_v2"
}

variable "osusername" {
  default = "adminuser"
}

variable "ospassword" {
  default = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "subscription" {
  default = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
variable "app_id" {
  default = "XXXX"
}
variable "app_pwd" {
  default = "XXXX"
}

variable "subscription_id" {
  default = "XXXX"
}
variable "tenant_id" {
  default = "XXXX"
}




provider "azurerm" {
    subscription_id = "xxxxxxxxxxxxxxxxxxx"
    client_id       = "xxxxxxxxxxxxxxxxxxx"
    client_secret   = "xxxxxxxxxxxxx"
    tenant_id       = "xxxxxxxxxxxxx"
}

resource "azurerm_network_security_group" "terraformnsg" {
    name                = "commserve"
    location            = "${var.region}"
    resource_group_name = "${var.resource_group}"

    security_rule {
        name                       = "RDP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "CVFIREWALL"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8403"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "WINRM"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5986"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Commvault"
    }
}


resource "azurerm_network_interface" "terraformnic" {
    name                      = "NIC_${var.vm_name}"
    location                  = "${var.region}"
    resource_group_name       = "${var.resource_group}"
    network_security_group_id = "${azurerm_network_security_group.terraformnsg.id}"

    ip_configuration {
        name                          = "IPCONFIG_${var.vm_name}"
        subnet_id                     = "/subscriptions/${var.subscription}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/virtualNetworks/${var.vm_network}/subnets/${var.vm_subnet}"
        private_ip_address_allocation = "dynamic"
    }

    tags {
        environment = "Commvault"
    }
}

resource "random_integer" "randomnumber" {
    min = 100000
    max = 999999
    keepers = {
        resource_group = "${var.resource_group}"
    }
}

resource "azurerm_storage_account" "cvstorageaccount" {
    name                = "commvault${random_integer.randomnumber.result}"
    resource_group_name = "${var.resource_group}"
    location            = "${var.region}"
    account_replication_type = "LRS"
    account_tier = "Standard"
    account_kind = "BlobStorage"
    access_tier = "Hot"

    tags {
        environment = "Commvault"
    }
}

resource "azurerm_storage_container" "backup" {
  name                  = "backup"
  resource_group_name   = "${var.resource_group}"
  storage_account_name  = "${azurerm_storage_account.cvstorageaccount.name}"
  container_access_type = "private"
}

resource "azurerm_storage_account" "cvstorageaccount2" {
    name                = "commvaultdr${random_integer.randomnumber.result}"
    resource_group_name = "${var.resource_group}"
    location            = "${var.region}"
    account_replication_type = "LRS"
    account_tier = "Standard"
    account_kind = "Storage"

    tags {
        environment = "Commvault"
    }
}


resource "azurerm_storage_share" "drbackup" {
  name = "drbackup"
  resource_group_name  = "${var.resource_group}"
  storage_account_name = "${azurerm_storage_account.cvstorageaccount2.name}"
}

resource "azurerm_virtual_machine" "terraformvm" {
    name                  = "${var.vm_name}"
    location              = "${var.region}"
    resource_group_name   = "${var.resource_group}"
    network_interface_ids = ["${azurerm_network_interface.terraformnic.id}"]
    vm_size               = "${var.vm_type}"
    delete_os_disk_on_termination  = "True"
    delete_data_disks_on_termination = "True"

    storage_os_disk {
        name              = "OsDisk_${var.vm_name}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_data_disk {
        name              = "cvinstall"
        managed_disk_type = "Premium_LRS"
        create_option     = "Empty"
        lun               = 0
        disk_size_gb      = "100"
    }


    storage_data_disk {
        name              = "ddb"
        managed_disk_type = "Premium_LRS"
        create_option     = "Empty"
        lun               = 1
        disk_size_gb      = "100"
    }
    

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.vm_name}"
        admin_username = "${var.osusername}"
        admin_password = "${var.ospassword}"
    }

    os_profile_windows_config {
        enable_automatic_upgrades = false
        provision_vm_agent = true
    }

    tags {
        environment = "Commvault"
    }

}

resource "azurerm_virtual_machine_extension" "vmext1cv" {
    name = "CommserveInstall"
    location = "${var.region}"
    resource_group_name = "${var.resource_group}"
    virtual_machine_name = "${azurerm_virtual_machine.terraformvm.name}"
    publisher = "Microsoft.Compute"
    type = "CustomScriptExtension"
    type_handler_version = "1.8"

    settings = <<SETTINGS
    {
        "fileUris": [ "https://raw.githubusercontent.com/marekk1717/letsautomate/master/letsautomate2/resources/csinstall.ps1" ],
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File csinstall.ps1 -saccount commvault${random_integer.randomnumber.result} -saccountkey ${azurerm_storage_account.cvstorageaccount.primary_access_key} -adminuser ${var.osusername} -region ${var.region} -app_id ${var.app_id} -app_pwd ${var.app_pwd} -subscription_id ${var.subscription_id} -tenant_id ${var.tenant_id}"
    }
SETTINGS


}


output "network_interface_private_ip" {
  value       = "${azurerm_network_interface.terraformnic.private_ip_address}"
}


output "DRBACKUP_Network_Share" {
  value       = "commvaultdr${random_integer.randomnumber.result}.file.core.windows.net\\drbackup"
}

output "DRBACKUP_Username" {
  value       = "AZURE\\commvaultdr${random_integer.randomnumber.result}"
}

output "DRBACKUP_Password" {
  value       = "${azurerm_storage_account.cvstorageaccount2.primary_access_key}"
}
