k8s_cluster "k3s" {
  driver  = "k3s" // default
  version = "v1.0.0"

  nodes = 1 // default

  network {
    name = "network.cloud"
  }
}

k8s_config "app" {
  depends_on = ["helm.consul"]
  cluster = "k8s_cluster.k3s"

  paths = ["./files/kube_config/app", "./files/kube_config/gloo-loop"]
  
  wait_until_ready = true
}