#!/bin/bash
#shellcheck disable=SC2154,SC2288,SC1083

set -x

wait_lb() {
while true
do
  if curl --output /dev/null --silent -k "https://${k3s_url}:6443"; then
    break
  fi
  sleep 5
  echo "Waiting for load balancer..."
done
}

render_ccm_config(){
cat << 'EOF' > /root/ccm-config.yaml
---
auth:
  useInstancePrincipals: true
compartment: ${compartment_ocid}
vcn: ${vcn_ocid}
loadBalancer:
  subnet1: ${subnet_ocid}
  securityListManagementMode: All
rateLimiter:
  rateLimitQPSRead: 20.0
  rateLimitBucketRead: 5
  rateLimitBucketWrite: 5
  rateLimitQPSWrite: 20.0
EOF

cat << 'EOF' > /root/oci-cloud-controller-manager.yaml
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: oci-cloud-controller-manager
  namespace: kube-system
  labels:
    k8s-app: oci-cloud-controller-manager
spec:
  selector:
    matchLabels:
      component: oci-cloud-controller-manager
      tier: control-plane
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        component: oci-cloud-controller-manager
        tier: control-plane
    spec:
      serviceAccountName: cloud-controller-manager
      hostNetwork: true
      nodeSelector:
        node-role.kubernetes.io/master: "true"
      tolerations:
      - key: node.cloudprovider.kubernetes.io/uninitialized
        value: "true"
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      volumes:
        - name: cfg
          secret:
            secretName: oci-cloud-controller-manager
        - name: kubernetes
          hostPath:
            path: /etc/kubernetes
      containers:
        - name: oci-cloud-controller-manager
          image: ghcr.io/oracle/cloud-provider-oci:v1.24.0
          command: ["/usr/local/bin/oci-cloud-controller-manager"]
          args:
            - --cloud-config=/etc/oci/cloud-provider.yaml
            - --cloud-provider=oci
            - --secure-port=10358
            - --v=2
          volumeMounts:
            - name: cfg
              mountPath: /etc/oci
              readOnly: true
            - name: kubernetes
              mountPath: /etc/kubernetes
              readOnly: true
EOF

cat << 'EOF' > /root/oci-cloud-controller-manager-rbac.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-controller-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:cloud-controller-manager
  labels:
    kubernetes.io/cluster-service: "true"
rules:
- apiGroups:
  - "coordination.k8s.io"
  resources:
  - leases
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - '*'
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - list
  - watch
  - patch
- apiGroups:
  - ""
  resources:
  - services/status
  verbs:
  - patch
  - get
  - update
- apiGroups:
    - ""
  resources:
    - configmaps
  resourceNames:
    - "extension-apiserver-authentication"
  verbs:
    - get
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - list
  - watch
  - create
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - endpoints
  resourceNames:
  - "cloud-controller-manager"
  verbs:
  - get
  - list
  - watch
  - update
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - configmaps
  resourceNames:
  - "cloud-controller-manager"
  verbs:
  - get
  - update
- apiGroups:
    - ""
  resources:
    - configmaps
  resourceNames:
    - "extension-apiserver-authentication"
  verbs:
    - get
    - list
    - watch

- apiGroups:
  - ""
  resources:
  - serviceaccounts
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - list
- apiGroups:
  - ""
  resources:
  - persistentvolumes
  verbs:
  - list
  - watch
  - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: oci-cloud-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:cloud-controller-manager
subjects:
- kind: ServiceAccount
  name: cloud-controller-manager
  namespace: kube-system
EOF
}



render_nginx_config(){
cat << 'EOF' > "$NGINX_RESOURCES_FILE"
---
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller-loadbalancer
  namespace: ingress-nginx
spec:
  selector:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: 80
      nodePort: ${nginx_ingress_controller_http_nodeport}
    - name: https
      port: 443
      protocol: TCP
      targetPort: 443
      nodePort: ${nginx_ingress_controller_https_nodeport}
  type: NodePort
---
apiVersion: v1
data:
  allow-snippet-annotations: "true"
  enable-real-ip: "true"
  proxy-real-ip-cidr: "0.0.0.0/0"
  proxy-body-size: "20m"
  use-proxy-protocol: "true"
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.1.1
    helm.sh/chart: ingress-nginx-4.0.16
  name: ingress-nginx-controller
  namespace: ingress-nginx
EOF
}

render_staging_issuer(){
STAGING_ISSUER_RESOURCE=$1
cat << 'EOF' > "$STAGING_ISSUER_RESOURCE"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
 name: letsencrypt-staging
 namespace: cert-manager
spec:
 acme:
   # The ACME server URL
   server: https://acme-staging-v02.api.letsencrypt.org/directory
   # Email address used for ACME registration
   email: ${certmanager_email_address}
   # Name of a secret used to store the ACME account private key
   privateKeySecretRef:
     name: letsencrypt-staging
   # Enable the HTTP-01 challenge provider
   solvers:
   - http01:
       ingress:
         class:  nginx
EOF
}

render_prod_issuer(){
PROD_ISSUER_RESOURCE=$1
cat << 'EOF' > "$PROD_ISSUER_RESOURCE"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: ${certmanager_email_address}
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
}

k3s_install_params=("--write-kubeconfig-mode 644")

%{ if operating_system == "ubuntu" }
# Disable firewall
/usr/sbin/netfilter-persistent stop
/usr/sbin/netfilter-persistent flush

systemctl stop netfilter-persistent.service
systemctl disable netfilter-persistent.service
# END Disable firewall

apt-get update
apt-get install -y software-properties-common jq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  python3 python3-pip
pip install oci-cli
%{ endif }

%{ if operating_system == "oraclelinux" }
# Disable firewall
systemctl disable --now firewalld
# END Disable firewall

# Fix iptables/SELinux bug
echo '(allow iptables_t cgroup_t (dir (ioctl)))' > /root/local_iptables.cil
semodule -i /root/local_iptables.cil

#dnf -y update
dnf -y install jq python36-oci-cli

k3s_install_params+=("--selinux")
%{ endif }


export OCI_CLI_AUTH=instance_principal
is_primary=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/metadata/is_primary)


%{ if install_nginx_ingress }
k3s_install_params+=("--disable traefik")
%{ endif }

%{ if install_oci_ccm == true }
instance_ocid=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/id)
k3s_install_params+=("--disable-cloud-controller")
k3s_install_params+=("--disable servicelb")
k3s_install_params+=("--kubelet-arg cloud-provider=external")
k3s_install_params+=("--kubelet-arg provider-id=oci://$instance_ocid")
%{ endif }

%{ if expose_kubeapi }
k3s_install_params+=("--tls-san ${k3s_tls_san_public}")
%{ endif }

%{ if k3s_version == "latest" }
K3S_VERSION=$(curl --silent https://api.github.com/repos/k3s-io/k3s/releases/latest | jq -r '.name')
%{ else }
K3S_VERSION="${k3s_version}"
%{ endif }

INSTALL_PARAMS="$${k3s_install_params[*]}"

if [[ "$is_primary" == "YES" ]]; then
  echo "I'm the first yeeee: Cluster init!"
  # shellcheck disable=SC2086
  until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=${k3s_token} sh -s - --cluster-init $INSTALL_PARAMS); do
    echo 'k3s did not install correctly'
    sleep 2
  done
%{ if install_oci_ccm }
  render_ccm_config
  kubectl create secret generic oci-cloud-controller-manager -n kube-system --from-file=cloud-provider.yaml=/root/ccm-config.yaml
  kubectl apply -f "/root/oci-cloud-controller-manager-rbac.yaml"
  kubectl apply -f "/root/oci-cloud-controller-manager.yaml"
%{ endif }
else
  echo ":( Cluster join"
  wait_lb
  # shellcheck disable=SC2086
  until (curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" K3S_TOKEN=${k3s_token} sh -s - --server https://${k3s_url}:6443 $INSTALL_PARAMS); do
    echo 'k3s did not install correctly'
    sleep 2
  done
fi

%{ if is_k3s_server }
until kubectl get pods -A | grep 'Running'; do
  echo 'Waiting for k3s startup'
  sleep 5
done

%{ if install_longhorn }
if [[ "$is_primary" == "YES" ]]; then
  %{ if operating_system == "ubuntu" }
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y  open-iscsi curl util-linux
  %{ endif }
  systemctl enable --now iscsid.service

  kubectl apply -f "https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/deploy/longhorn.yaml"
  kubectl create -f "https://raw.githubusercontent.com/longhorn/longhorn/${longhorn_release}/examples/storageclass.yaml"
fi
%{ endif }

%{ if install_nginx_ingress }
if [[ "$is_primary" == "YES" ]]; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/baremetal/deploy.yaml
  NGINX_RESOURCES_FILE=/root/nginx-ingress-resources.yaml
  render_nginx_config
  kubectl apply -f $NGINX_RESOURCES_FILE
fi
%{ endif }

%{ if install_certmanager }
if [[ "$is_primary" == "YES" ]]; then
  kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${certmanager_release}/cert-manager.yaml"
  render_staging_issuer /root/staging_issuer.yaml
  render_prod_issuer /root/prod_issuer.yaml

  # Wait cert-manager to be ready
  until kubectl get pods -n cert-manager | grep 'Running'; do
    echo 'Waiting for cert-manager to be ready'
    sleep 15
  done

  kubectl create -f /root/prod_issuer.yaml
  kubectl create -f /root/staging_issuer.yaml
fi
%{ endif }

%{ endif }
