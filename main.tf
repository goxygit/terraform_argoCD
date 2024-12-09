resource "docker_container" "gnidas_control_plane" {
  name  = "gnidas-control-plane"
  image = "kindest/node:v1.30.0"
  ports {
    internal = 6443
    external = 6443
  }
  resources {
    memory = "1500Mi"
    cpu    = "1"
  }
  environment = {
    K8S_VERSION = "v1.30.0"
  }
  volumes {
    host_path      = "/var/lib/docker/volumes/gnidas-control-plane"
    container_path = "/etc/kubernetes"
  }
}

resource "docker_container" "gnidas_worker" {
  name  = "gnidas-worker"
  image = "kindest/node:v1.30.0"
  resources {
    memory = "1500Mi"
    cpu    = "1"
  }
}

resource "docker_container" "gnidas_worker2" {
  name  = "gnidas-worker2"
  image = "kindest/node:v1.30.0"
  resources {
    memory = "1500Mi"
    cpu    = "1"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.16.1"  

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "gha-runner-scale-set-controller" {
  name             = "gha-runner-scale-set-controller"
  namespace        = "actions-runner-system"
  create_namespace = true
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = "0.9.3"
} 

resource "helm_release" "gha-runner-scale-set-dind" {
  name             = "gha-runner-scale-set-dind"
  namespace        = "actions-runner-system"
  create_namespace = true
  force_update     = false
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = "0.9.3"
  values = [
    templatefile("/files/gha-runner-scale-set-dind.tmpl", {
      github_config_secret = "github-secret"
      runner_name          = "local-runner"
    })
  ]
}

  resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd" # Используем отдельный namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "2.9" # Проверьте актуальную версию

  values = [
    templatefile("/files/argocd-values.tmpl", {})
  ]
}
