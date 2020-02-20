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