docs "docs" {
  path  = "./_docs"
  port  = 8081
}

container "tools" {
  image   {
    name = "shipyardrun/tools:solo"
  }
  
  network {
    name = "network.cloud"
  }

  command = ["tail", "-f", "/dev/null"]

  # Working files
  volume {
    source      = "./files"
    destination = "/work"
  }

  # Shipyard home folder
  volume {
    source      = "${env("HOME")}/.shipyard"
    destination = "/root/.shipyard"
  }

  volume {
    source      = "/var/run/docker.sock"
    destination = "/var/run/docker.sock"
  }
  
  env {
    key = "KUBECONFIG"
    value = "/root/.shipyard/config/k3s/kubeconfig-docker.yaml"
  }
}