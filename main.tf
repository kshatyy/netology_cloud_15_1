# Creating a network
resource "yandex_vpc_network" "netology" {
  name        = var.vpc_name
}

# Creating a subnets
resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.netology.id
  v4_cidr_blocks = var.public_cidr
}

resource "yandex_vpc_subnet" "private-subnet" {
  name           = "private"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.netology.id
  v4_cidr_blocks = var.private_cidr
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}

# Creating a NAT VM
resource "yandex_compute_instance" "nat-vm" {
  name        = "nat-vm"
  platform_id = var.yandex_compute_instance_platform_id

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 1
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    ip_address         = "192.168.10.254"
    nat                = true
  }

  metadata = {
    serial-port-enable = var.metadata_map.metadata["serial-port-enable"]
    ssh-keys           = "${local.ssh_key}"
  }
}

# Creating a Public VM
resource "yandex_compute_instance" "vm-public"{
  name        = "vm-public"
  platform_id = var.yandex_compute_instance_platform_id
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 1
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public-subnet.id
    nat       = true
  }

  metadata = {
    serial-port-enable = var.metadata_map.metadata["serial-port-enable"]
    ssh-keys           = "${local.ssh_key}"
  }
}

data "yandex_compute_image" "ubuntu" {
  family = var.yandex_compute_image
}

# Creating a route table and static route
resource "yandex_vpc_route_table" "nat-instance-route" {
  name       = "private-into-nat"
  network_id = yandex_vpc_network.netology.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

# Creating a Private VM
resource "yandex_compute_instance" "vm-private"{
  name        = "vm-private"
  platform_id = var.yandex_compute_instance_platform_id
  resources {
    core_fraction = 20
    cores         = 2
    memory        = 1
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
    }
  }
  scheduling_policy {
    preemptible = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private-subnet.id
  }

  metadata = {
    serial-port-enable = var.metadata_map.metadata["serial-port-enable"]
    ssh-keys           = "${local.ssh_key}"
  }
}