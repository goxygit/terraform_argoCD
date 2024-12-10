provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-gnida"
}
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-gnida"
  }
}
