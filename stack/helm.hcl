helm "consul" {
  cluster = "k8s_cluster.k3s"
  chart = "./helm/consul-helm-0.16.2"
  values = "./helm/consul-values.yaml"

  health_check {
    timeout = "240s"
    pods = ["release=consul"]
  }
}