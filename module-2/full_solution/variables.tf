variable "yourname" {
  type = string
}

variable "location" {
  type = string
}

variable "my_ip_address" {
  type = string
}

variable "vm_size" {
  description = "The size of the VM used for the VRE. To get a list of available VM sizes use az vm list-sizes --location \"westeurope\" -otable. Example values: Standard_NC6_promo, Standard_B4ms"

  type    = string
  default = "Standard_B2ms"

  validation {
    condition     = can(regex("^(Standard_)", var.vm_size))
    error_message = "The VM SKU must start with 'Standard_'. To get a list of available VM sizes use az vm list-sizes --location \"westeurope\" -otable."
  }
}

variable "os_disk_sku" {
  description = "The SKU used for the OS Disk. Possible values: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS"

  type    = string
  default = "Standard_LRS"

  validation {
    condition     = can(regex("^(Standard_LRS|Premium_LRS|StandardSSD_LRS|UltraSSD_LRS)$", var.os_disk_sku))
    error_message = "The disk SKU must be one of: Standard_LRS, Premium_LRS, StandardSSD_LRS or UltraSSD_LRS."
  }
}

variable "os_disk_size" {
  description = "The size in GB of the OS Disk."

  type    = number
  default = 128

  validation {
    condition     = var.os_disk_size >= 100 && can(regex("[0-9]+", var.os_disk_size))
    error_message = "Must be a whole number and larger than 100."
  }
}