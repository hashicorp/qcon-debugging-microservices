ingress "consul-http" {
  network {
    name = "network.cloud"
  }

  target = "k8s_cluster.k3s"
  service  = "svc/consul-consul-server"

  port {
    local  = 8500
    remote = 8500
    host   = 18500
  }
}

ingress "web" {
  target = "k8s_cluster.k3s"
  service  = "svc/web"
  
  network {
    name = "network.cloud"
  }

  port {
    local  = 9090
    remote = 9090
    host   = 19090
  }
}

ingress "jaeger" {
  target = "k8s_cluster.k3s"
  service  = "svc/jaeger"
  
  network {
    name = "network.cloud"
  }

  port {
    local  = 16686
    remote = 16686
    host   = 16686
  }
}