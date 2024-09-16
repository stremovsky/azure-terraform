
provider "kubernetes" {
  #config_path = "~/.kube/config"
  #config_path = "${path.module}/kubeconfig"
  host                   = module.aks_cluster[0].aks_host
  client_certificate     = base64decode(module.aks_cluster[0].client_certificate)
  client_key             = base64decode(module.aks_cluster[0].client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    #config_path = "~/.kube/config"
    #config_path = "${path.module}/kubeconfig"
    host                   = module.aks_cluster[0].aks_host
    client_certificate     = base64decode(module.aks_cluster[0].client_certificate)
    client_key             = base64decode(module.aks_cluster[0].client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster[0].cluster_ca_certificate)
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

  depends_on = [module.aks_cluster[0].kube_config, local_file.kubeconfig]
}

resource "kubernetes_manifest" "cluster_issuer" {
  count = 1
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
  //depends_on = [module.aks_cluster[0].kube_config, local_file.kubeconfig, helm_release.cert_manager]
}

resource "kubernetes_manifest" "app_service_account" {
  count = 1
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
  count      = 1
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
}
