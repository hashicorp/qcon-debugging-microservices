k8s_cluster "k3s" {
  driver  = "k3s" // default
  version = "v1.0.0"

  nodes = 1 // default

  network {
    name = "network.cloud"
  }

  # push the squash debugger image to the cluster to speed up start time
  image {
    name = "quay.io/solo-io/plank-dlv:0.5.18"
  }
}

k8s_config "app" {
  depends_on = ["helm.consul"]
  cluster = "k8s_cluster.k3s"

  paths = ["./files/kube_config/app"]
  
  wait_until_ready = true
}

k8s_config "gloo_crds" {
  cluster = "k8s_cluster.k3s"

  paths = [
    "./files/kube_config/gloo-loop/00-crds.yaml",
  ]
  
  wait_until_ready = true
}

k8s_config "gloo" {
  depends_on = ["k8s_config.gloo_crds"]
  cluster = "k8s_cluster.k3s"

  paths = [
    "./files/kube_config/gloo-loop/10-gloo.yaml",
    "./files/kube_config/gloo-loop/20-gloo-crs.yaml",
  ]
  
  wait_until_ready = false
}