

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
resource "helm_release" "prometheus_grafana" {
  name       = "prometheus-grafana"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "./environments/prometheus-grafana"
  values     = [
    file("./environments/prometheus-grafana/values.yaml")
  ]
  
  create_namespace = true
}
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.4.4"  # Укажите актуальную версию
values =[templatefile("/files/argocd-values.tmpl", {})]
  set {
    name  = "installCRDs"
    value = "true"
  }

  create_namespace = true
}
resource "kubernetes_manifest" "argocd_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "argocd-parent-application"
      namespace = "argocd"
    }
    spec = {
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "gnida-dev"
      }
      source = {
        repoURL        = "https://github.com/goxigit/terraform_argoCD.git"
        path           = "./environments"
        targetRevision = "application"
      }
      project = "gnida"
      syncPolicy = {
        automated = {
          prune   = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}