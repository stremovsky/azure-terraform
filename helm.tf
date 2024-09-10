provider "kubernetes" {
  #config_path = "~/.kube/config"
  config_path = "${path.module}/kubeconfig"
}

provider "helm" {
  kubernetes {
    #config_path = "~/.kube/config"
    config_path = "${path.module}/kubeconfig"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  //version    = "v1.15.3"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [module.aks_cluster[0].kube_config]
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod-secret"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }
  depends_on = [helm_release.cert_manager]
}
