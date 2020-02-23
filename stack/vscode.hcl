container "vscode" {
  image   {
    name = "shipyardrun/code:solo"
  }

  # Add the working files
  volume {
    source      = "./files"
    destination = "/work"
  }
  
  # Add the Docker sock so Docker CLI in the container
  # can use Docker on the host
  volume {
    source      = "/var/run/docker.sock"
    destination = "/var/run/docker.sock"
  }
  
  # Shipyard home folder
  volume {
    source      = "${env("HOME")}/.shipyard"
    destination = "/root/.shipyard"
  }

  network {
    name = "network.cloud"
  }

  port {
      local  = 8080
      remote = 8080
      host   = 8080
  }
  
  env {
    key = "KUBECONFIG"
    value = "/root/.shipyard/config/k3s/kubeconfig-docker.yaml"
  }
  
  env {
    key = "CONSUL_HTTP_ADDR"
    value = "http://consul-http.ingress.shipyard:8500"
  }
}