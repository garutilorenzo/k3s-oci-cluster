resource "helm_release" "kubevela" {
  count      = var.install_kubevela ? 1 : 0
  chart      = "vela-core"
  repository = "https://charts.kubevela.net/core"
  version    = var.kubevela_release

  name             = "kubevela"
  namespace        = "vela-system"
  create_namespace = true

  depends_on = [
    data.cloudinit_config.k3s_server_tpl
  ]
}

resource "helm_release" "crossplane" {
  count      = var.install_crossplane ? 1 : 0
  chart      = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  version    = var.crossplane_release

  name             = "crossplane"
  namespace        = "crossplane-system"
  create_namespace = true

  depends_on = [
    data.cloudinit_config.k3s_server_tpl
  ]
}
