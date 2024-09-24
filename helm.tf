
provider "kubernetes" {
  #config_path = "~/.kube/config"
  host                   = module.aks_cluster[0].aks_host
  client_certificate     = base64decode(module.aks_cluster[0].client_certificate)
  client_key             = base64decode(module.aks_cluster[0].client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    #config_path = "~/.kube/config"
    host                   = module.aks_cluster[0].aks_host
    client_certificate     = base64decode(module.aks_cluster[0].client_certificate)
    client_key             = base64decode(module.aks_cluster[0].client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster[0].cluster_ca_certificate)
  }
}

#data "azurerm_kubernetes_cluster" "akscluster" {
#  name                = module.aks_cluster[0].cluster_name
#  resource_group_name = data.azurerm_resource_group.aks_rg.name
#}

resource "helm_release" "cert_manager" {
  count      = 0
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
  count = 0
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cert-issuer"
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
}

resource "kubernetes_manifest" "app_service_account" {
  count = 0
  manifest = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = local.workload_identity_name
      namespace = "default"
      annotations = {
        "azure.workload.identity/client-id" = module.identity.workload_webapp_identity_client_id
      }
    }
  }
}


#helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz" --set controller.service.externalTrafficPolicy=Local
#kubectl patch configmap ingress-nginx-controller -n default --type merge -p '{"data":{"allow-snippet-annotations":"true"}}'
#{{- if .Values.controller.allowSnippetAnnotations }}
#  allow-snippet-annotations: "true"
#{{- end }}

resource "helm_release" "ingress_nginx" {
  count      = 0
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  #version    = "4.11.2"

  values = [
    <<-EOF
    controller:
      allowSnippetAnnotations: true
      service:
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
        externalTrafficPolicy: Local
    EOF
  ]

  # Optionally, create the namespace if it doesn't exist
  create_namespace = true
  depends_on       = [module.aks_cluster[0].kube_config]
}
