variable "fqdn" {
default = ".westeurope.cloudapp.azure.com"
}

variable "vm_name" {
  default = "oraclevm2"
}

variable "vm_network" {
  default = "rg_cv_demo-vnet"
}

variable "vm_subnet" {
  default = "default"
}

variable "resource_group" {
  default = "rg_cv_demo"
}

variable "region" {
  default = "West Europe"
}

variable "vm_type" {
  default = "Standard_DS2_v2"
}

variable "username" {
  default = "adminuser"
}

provider "azurerm" {
    subscription_id = "xxxxxxxxxxxxxxxxxx"
    client_id       = "xxxxxxxxxxxxxxxxxx"
    client_secret   = "xxxxxxxxxxxxxxxxxx"
    tenant_id       = "xxxxxxxxxxxxxxxxxx"
}

resource "azurerm_public_ip" "terraformpublicip" {
    name                         = "PublicIP_${var.vm_name}"
    location                     = "${var.region}"
    resource_group_name          = "${var.resource_group}"
    public_ip_address_allocation = "dynamic"
    domain_name_label = "${var.vm_name}"
    tags {
        environment = "OracleTest"
    }
}

resource "azurerm_network_security_group" "terraformnsg" {
    name                = "linuxsg1"
    location            = "${var.region}"
    resource_group_name = "${var.resource_group}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "OracleTest"
    }
}


resource "azurerm_network_interface" "terraformnic" {
    name                      = "NIC_${var.vm_name}"
    location                  = "${var.region}"
    resource_group_name       = "${var.resource_group}"

    ip_configuration {
        name                          = "IPCONFIG_${var.vm_name}"
        subnet_id                     = "/subscriptions/XXXXXXXXXXXXXXX/resourceGroups/${var.resource_group}/providers/Microsoft.Network/virtualNetworks/${var.vm_network}/subnets/${var.vm_subnet}"
        private_ip_address_allocation = "dynamic"
	public_ip_address_id          = "${azurerm_public_ip.terraformpublicip.id}"
    }

    tags {
        environment = "OracleTest"
    }
}

resource "azurerm_virtual_machine" "terraformvm" {
    name                  = "${var.vm_name}"
    location              = "${var.region}"
    resource_group_name   = "${var.resource_group}"
    network_interface_ids = ["${azurerm_network_interface.terraformnic.id}"]
    vm_size               = "${var.vm_type}"
    delete_os_disk_on_termination  = "True"

    storage_os_disk {
        name              = "OsDisk_${var.vm_name}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Oracle"
        offer     = "Oracle-Database-Ee"
        sku       = "12.1.0.2"
        version   = "latest"
    }

    os_profile {
        computer_name  = "${var.vm_name}"
        admin_username = "adminuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/adminuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3Nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
    }

    tags {
        environment = "OracleTest"
    }

    provisioner "local-exec" {
    command = "echo -e \"[${var.vm_name}]\n${var.vm_name}${var.fqdn} ansible_connection=ssh ansible_ssh_user=adminuser\" > inventory &&  ansible-playbook -i inventory install_client.yml --extra-vars \"vmname=${var.vm_name} vmdns=${var.vm_name}${var.fqdn}\""
    }

}

output "vmdns" {
  value = "${var.vm_name}${var.fqdn}"
}
