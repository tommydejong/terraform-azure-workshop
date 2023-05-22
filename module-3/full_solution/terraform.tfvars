location      = "westeurope"
yourname      = "tdejong"
my_ip_address = "45.94.174.33/32"
additional_tags = {
  "MyTerraformSkillLevel" = "Uberhigh"
}
enable_vm_shutdown = true
vm_shutdown_time   = 2000
data_disks = {
    1 = {
      name = "smalldatadisk"
      size = 128
    },
    2 = {
      name = "bigdatadisk"
      size = 256
    }
}