provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-gnidas"
}
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-gnidas"
  }
}
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.0"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine" # Для Windows
}