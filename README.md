[![Wordpress CI](https://github.com/garutilorenzo/k3s-oci-cluster/actions/workflows/ci.yml/badge.svg)](https://github.com/garutilorenzo/k3s-oci-cluster/actions/workflows/ci.yml)
[![GitHub issues](https://img.shields.io/github/issues/garutilorenzo/k3s-oci-cluster)](https://github.com/garutilorenzo/k3s-oci-cluster/issues)
![GitHub](https://img.shields.io/github/license/garutilorenzo/k3s-oci-cluster)
[![GitHub forks](https://img.shields.io/github/forks/garutilorenzo/k3s-oci-cluster)](https://github.com/garutilorenzo/k3s-oci-cluster/network)
[![GitHub stars](https://img.shields.io/github/stars/garutilorenzo/k3s-oci-cluster)](https://github.com/garutilorenzo/k3s-oci-cluster/stargazers)

<p align="center">
  <img src="https://garutilorenzo.github.io/images/k3s-logo-large.png?" alt="k3s Logo"/>
</p>

# OCI K3s cluster

Deploy a Kubernetes cluster for free, using K3s and Oracle [always free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) resources.

# Table of Contents

- [OCI K3s cluster](#oci-k3s-cluster)
- [Table of Contents](#table-of-contents)
    - [Important notes](#important-notes)
    - [Requirements](#requirements)
    - [Supported OS](#supported-os)
    - [Terraform OCI user creation (Optional)](#terraform-oci-user-creation-optional)
      - [Example RSA key generation](#example-rsa-key-generation)
    - [Project setup](#project-setup)
    - [Oracle provider setup](#oracle-provider-setup)
    - [Pre flight checklist](#pre-flight-checklist)
      - [How to find the availability doamin name](#how-to-find-the-availability-doamin-name)
      - [How to list all the OS images](#how-to-list-all-the-os-images)
  - [Notes about OCI always free resources](#notes-about-oci-always-free-resources)
  - [Notes about K3s](#notes-about-k3s)
  - [Infrastructure overview](#infrastructure-overview)
  - [Cluster resource deployed](#cluster-resource-deployed)
    - [Nginx ingress controller](#nginx-ingress-controller)
    - [Cert-manager](#cert-manager)
  - [Deploy](#deploy)
      - [Public LB check](#public-lb-check)
      - [Longhorn check](#longhorn-check)
      - [Argocd check](#argocd-check)
  - [Deploy a sample stack](#deploy-a-sample-stack)
  - [Clean up](#clean-up)
  - [Known Bugs](#known-bugs)
    - [409-Conflict](#409-conflict)
    - [kubectl exec failure](#kubectl-exec-failure)

**Note** choose a region with enough ARM capacity

### Important notes

* This is repo shows only how to use terraform with the Oracle Cloud infrastructure and use only the **always free** resources. This examples are **not** for a production environment.
* At the end of your trial period (30 days). All the paid resources deployed will be stopped/terminated
* At the end of your trial period (30 days), if you have a running compute instance it will be stopped/hibernated

### Requirements

To use this repo you will need:

* an Oracle Cloud account. You can register [here](https://cloud.oracle.com)

Once you get the account, follow the *Before you begin* and *1. Prepare* step in [this](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm) document.

### Supported OS

This module was tested with:

* Ubuntu 20.04, 22.04 (ubuntu remote user)
* Ubuntu 20.04, 22.04 Minimal (ubuntu remote user)
* Oracle Linux 8, 9 (opc remote user)

### Terraform OCI user creation (Optional)

Is always recommended to create a separate user and group in your preferred [domain](https://cloud.oracle.com/identity/domains) to use with Terraform.
This user must have less privileges possible (Zero trust policy). Below is an example policy that you can [create](https://cloud.oracle.com/identity/policies) allow `terraform-group` to manage all the resources needed by this module:

```
Allow group terraform-group to manage virtual-network-family  in compartment id <compartment_ocid>
Allow group terraform-group to manage instance-family  in compartment id <compartment_ocid>
Allow group terraform-group to manage compute-management-family  in compartment id <compartment_ocid>
Allow group terraform-group to manage volume-family  in compartment id <compartment_ocid>
Allow group terraform-group to manage load-balancers  in compartment id <compartment_ocid>
Allow group terraform-group to manage network-load-balancers  in compartment id <compartment_ocid>
Allow group terraform-group to manage dynamic-groups in compartment id <compartment_ocid>
Allow group terraform-group to manage policies in compartment id <compartment_ocid>
Allow group terraform-group to read network-load-balancers  in compartment id <compartment_ocid>
Allow group terraform-group to manage dynamic-groups in tenancy
```

See [how](#oracle-provider-setup) to find the compartment ocid. The user and the group have to be manually created before using this module.
To create the user go to **Identity & Security -> Users**, then create the group in **Identity & Security -> Groups** and associate the newly created user to the group. The last step is to create the policy in **Identity & Security -> Policies**.

#### Example RSA key generation

To use terraform with the Oracle Cloud infrastructure you need to generate an RSA key. Generate the rsa key with:

```
openssl genrsa -out ~/.oci/<your_name>-oracle-cloud.pem 4096
chmod 600 ~/.oci/<your_name>-oracle-cloud.pem
openssl rsa -pubout -in ~/.oci/<your_name>-oracle-cloud.pem -out ~/.oci/<your_name>-oracle-cloud_public.pem
```

replace `<your_name>` with your name or a string you prefer.

**NOTE**: `~/.oci/<your_name>-oracle-cloud_public.pem` will be used in  `terraform.tfvars` by the Oracle provider plugin, so please take note of this string.

### Project setup

Clone this repo and go in the `example/` directory:

```
git clone https://github.com/garutilorenzo/k3s-oci-cluster.git
cd k3s-oci-cluster/example/
```

Now you have to edit the `main.tf` file and you have to create the `terraform.tfvars` file. For more detail see [Oracle provider setup](#oracle-provider-setup) and [Pre flight checklist](#pre-flight-checklist).

Or if you prefer you can create an new empty directory in your workspace and create this three files:

* `terraform.tfvars` - More details in [Oracle provider setup](#oracle-provider-setup)
* `main.tf`
* `provider.tf`

The `main.tf` file will look like:


```
variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "public_key_path" {}
variable "availability_domain" {}
variable "my_public_ip_cidr" {}
variable "cluster_name" {}
variable "os_image_id" {}
variable "certmanager_email_address" {}
variable "k3s_server_pool_size" {
  default = 1
}
variable "k3s_worker_pool_size" {
  default = 2
}
variable "region" {}

module "k3s_cluster" {
  # k3s_version               = "v1.23.8+k3s2" # Fix kubectl exec failure
  # k3s_version               = "v1.24.4+k3s1" # Kubernetes version compatible with longhorn
  region                    = var.region
  availability_domain       = var.availability_domain
  tenancy_ocid              = var.tenancy_ocid
  compartment_ocid          = var.compartment_ocid
  my_public_ip_cidr         = var.my_public_ip_cidr
  cluster_name              = var.cluster_name
  public_key_path           = var.public_key_path
  environment               = "staging"
  os_image_id               = var.os_image_id
  certmanager_email_address = var.certmanager_email_address
  k3s_server_pool_size      = var.k3s_server_pool_size
  k3s_worker_pool_size      = var.k3s_worker_pool_size
  ingress_controller        = "nginx"
  source                    = "../"
}

output "k3s_servers_ips" {
  value = module.k3s_cluster.k3s_servers_ips
}

output "k3s_workers_ips" {
  value = module.k3s_cluster.k3s_workers_ips
}

output "public_lb_ip" {
  value = module.k3s_cluster.public_lb_ip
}
```

For all the possible variables see [Pre flight checklist](#pre-flight-checklist)

The `provider.tf` will look like:

```
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
  fingerprint      = var.fingerprint
  region           = var.region
}
```

Now we can init terraform with:

```
terraform init

terraform init
Initializing modules...
Downloading git::https://github.com/garutilorenzo/k3s-oci-cluster.git for k3s_cluster...
- k3s_cluster in .terraform/modules/k3s_cluster

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/oci from the dependency lock file
- Reusing previous version of hashicorp/template from the dependency lock file
- Using previously-installed hashicorp/template v2.2.0
- Using previously-installed hashicorp/oci v4.64.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Oracle provider setup

In the `example/` directory of this repo you need to create a `terraform.tfvars` file, the file will look like:

```
fingerprint      = "<rsa_key_fingerprint>"
private_key_path = "~/.oci/<your_name>-oracle-cloud.pem"
user_ocid        = "<user_ocid>"
tenancy_ocid     = "<tenency_ocid>"
compartment_ocid = "<compartment_ocid>"
```

To find your `tenency_ocid` in the Ocacle Cloud console go to: **Governance and Administration > Tenency details**, then copy the OCID.

To find you `user_ocid` in the Ocacle Cloud console go to **User setting** (click on the icon in the top right corner, then click on User settings), click your username and then copy the OCID.

The `compartment_ocid` is the same as `tenency_ocid`.

The fingerprint is the fingerprint of your RSA key, you can find this vale under **User setting > API Keys**.

### Pre flight checklist

Once you have created the terraform.tfvars file edit the `main.tf` file (always in the `example/` directory) and set the following variables:

| Var   | Required | Desc |
| ------- | ------- | ----------- |
| `region`       | `yes`       | set the correct OCI region based on your needs  |
| `availability_domain` | `yes`        | Set the correct availability domain. See [how](#how-to-find-the-availability-doamin-name) to find the availability domain|
| `compartment_ocid` | `yes`        | Set the correct compartment ocid. See [how](#oracle-provider-setup) to find the compartment ocid |
| `cluster_name` | `yes`        | the name of your K3s cluster. Default: k3s-cluster |
| `my_public_ip_cidr` | `yes`        |  your public ip in cidr format (Example: 195.102.xxx.xxx/32) |
| `private_key_path`     | `yes`       | Path to your private **OCI RSA key** |
| `environment`  | `yes`  | Current work environment (Example: staging/dev/prod). This value is used for tag all the deployed resources |
| `os_image_id`  | `yes`  | Image id to use. See [how](#how-to-list-all-the-os-images) to list all available OS images |
| `public_key_path`     | `no`       | Path to your public **workstation SSH key** |
| `k3s_version`  | `no`  | K3s version. Default: latest |
| `k3s_subnet`  | `no`  | Subnet where K3s will be exposed. Rquired if the subnet is different from the default gw subnet (Eg. 192.168.1.0/24). Default: default_route_table |
| `compute_shape`  | `no`  | Compute shape to use. Default VM.Standard.A1.Flex. **NOTE** Is mandatory to use this compute shape for provision 4 always free VMs |
| `oci_core_vcn_dns_label`  | `no`  | VCN DNS label. Default: defaultvcn |
| `oci_core_subnet_dns_label10`  | `no`  | First subnet DNS label. Default: defaultsubnet10 |
| `oci_core_subnet_dns_label11`  | `no`  | Second subnet DNS label. Default: defaultsubnet11 |
| `oci_core_vcn_cidr`  | `no`  | VCN CIDR. Default: oci_core_vcn_cidr |
| `oci_core_subnet_cidr10`  | `no`  | First subnet CIDR. Default: 10.0.0.0/24 |
| `oci_core_subnet_cidr11`  | `no`  | Second subnet CIDR. Default: 10.0.1.0/24 |
| `oci_identity_dynamic_group_name`  | `no`  | Dynamic group name. This dynamic group will contains all the instances of this specific compartment. Default: Compute_Dynamic_Group |
| `oci_identity_policy_name`  | `no`  | Policy name. This policy will allow dynamic group 'oci_identity_dynamic_group_name' to read OCI api without auth. Default: Compute_To_Oci_Api_Policy |
| `k3s_load_balancer_name`  | `no`  | Internal LB name. Default: k3s internal load balancer  |
| `public_load_balancer_name`  | `no`  | Public LB name. Default: K3s public LB  |
| `kube_api_port`  | `no`  | Kube api default port Default: 6443  |
| `public_lb_shape`  | `no`  | LB shape for the public LB. Default: flexible. **NOTE** is mandatory to use this kind of shape to provision two always free LB (public and private)  |
| `http_lb_port`  | `no`  | http port used by the public LB. Default: 80  |
| `https_lb_port`  | `no`  | http port used by the public LB. Default: 443  |
| `k3s_server_pool_size`  | `no`  | Number of k3s servers deployed. Default 1  |
| `k3s_worker_pool_size`  | `no`  | Number of k3s workers deployed. Default 2  |
| `k3s_extra_worker_node`  | `no`  | Boolean value, default true. Deploy the third worker nodes. The node will be deployed outside the worker instance pools. Using OCI always free account you can't create instance pools with more than two servers. This workaround solve this problem. |
| `ingress_controller`  | `no`  | Define the ingress controller to use. Valid values are: [default](https://docs.k3s.io/networking#traefik-ingress-controller), [nginx](#nginx-ingress-controller), [traefik2](https://traefik.io/) or [istio](https://istio.io/latest/docs/tasks/traffic-management/ingress/kubernetes-ingress/) |
| `disable_ingress`  | `no`  | Boolean value, disable all ingress controllers. Default: false |
| `ingress_controller_http_nodeport`  | `no`  | NodePort where nginx ingress will listen for http traffic. Default 30080  |
| `ingress_controller_https_nodeport`  | `no`  | NodePort where nginx ingress will listen for https traffic.  Default 30443 |
| `install_longhorn`  | `no`  | Boolean value, install longhorn "Cloud native distributed block storage for Kubernetes". Default: true. To use longhorn set the *k3s_version* < v1.25.x [Ref.](https://github.com/longhorn/longhorn/issues/4003)  |
| `longhorn_release`  | `no`  | Longhorn release. Default: v1.4.0  |
| `install_certmanager`  | `no`  | Boolean value, install [cert manager](https://cert-manager.io/) "Cloud native certificate management". Default: true  |
| `nginx_ingress_release`  | `no`  | Longhorn release. Default: v1.5.1  |
| `certmanager_release`  | `no`  | Cert manager release. Default: v1.11.0  |
| `certmanager_email_address`  | `no`  | Email address used for signing https certificates. Defaul: changeme@example.com  |
| `install_argocd`  | `no`  | Boolean value, install [Argo CD](https://argo-cd.readthedocs.io/en/stable/) "a declarative, GitOps continuous delivery tool for Kubernetes.". Default: true  |
| `argocd_release`  | `no`  | Argo CD release. Default: v2.4.11  |
| `install_argocd_image_updater`  | `no`  | Boolean value, install [Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/en/stable/) "A tool to automatically update the container images of Kubernetes workloads that are managed by Argo CD.". Default: true  |
| `argocd_image_updater_release`  | `no`  | Argo CD release Image Updater. Default: v0.12.0  |
| `unique_tag_key`  | `no`  | Unique tag name used for tagging all the deployed resources. Default: k3s-provisioner |
| `unique_tag_value`  | `no`  | Unique value used with  unique_tag_key. Default: https://github.com/garutilorenzo/k3s-oci-cluster |
| `expose_kubeapi`  | `no`  | Boolean value, default false. Expose or not the kubeapi server to the internet. Access is granted only from *my_public_ip_cidr* for security reasons. |


#### How to find the availability doamin name

To find the list of the availability domains run this command on che Cloud Shell:

```
oci iam availability-domain list
{
  "data": [
    {
      "compartment-id": "<compartment_ocid>",
      "id": "ocid1.availabilitydomain.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "name": "iAdc:EU-ZURICH-1-AD-1"
    }
  ]
}
```

#### How to list all the OS images

To filter the OS images by shape and OS run this command on che Cloud Shell. You can filter by OS: Canonical Ubuntu or Oracle Linux:

```
oci compute image list --compartment-id <compartment_ocid> --operating-system "Canonical Ubuntu" --shape "VM.Standard.A1.Flex"
{
  "data": [
    {
      "agent-features": null,
      "base-image-id": null,
      "billable-size-in-gbs": 2,
      "compartment-id": null,
      "create-image-allowed": true,
      "defined-tags": {},
      "display-name": "Canonical-Ubuntu-20.04-aarch64-2022.01.18-0",
      "freeform-tags": {},
      "id": "ocid1.image.oc1.eu-zurich-1.aaaaaaaag2uyozo7266bmg26j5ixvi42jhaujso2pddpsigtib6vfnqy5f6q",
      "launch-mode": "NATIVE",
      "launch-options": {
        "boot-volume-type": "PARAVIRTUALIZED",
        "firmware": "UEFI_64",
        "is-consistent-volume-naming-enabled": true,
        "is-pv-encryption-in-transit-enabled": true,
        "network-type": "PARAVIRTUALIZED",
        "remote-data-volume-type": "PARAVIRTUALIZED"
      },
      "lifecycle-state": "AVAILABLE",
      "listing-type": null,
      "operating-system": "Canonical Ubuntu",
      "operating-system-version": "20.04",
      "size-in-mbs": 47694,
      "time-created": "2022-01-27T22:53:34.270000+00:00"
    },
```

## Notes about OCI always free resources

In order to get the maximum resources available within the oracle always free tier, the max amount of the k3s servers and k3s workers must be 2. So the **max value** for `k3s_server_pool_size` and `k3s_worker_pool_size` is `2`.

In this setup we use two LB, one internal LB and one public LB (Layer 7). In order to use two LB using the always free resources, one lb must be a [network load balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/introducton.htm#Overview) an the other must be a [load balancer](https://docs.oracle.com/en-us/iaas/Content/Balance/Concepts/balanceoverview.htm). The public LB **must** use the `flexible` shape (`public_lb_shape` variable).

## Notes about K3s

In this environment the High Availability of the K3s cluster is provided using the Embedded DB. More details [here](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/)

The default installation of K3s install [Traefik](https://docs.k3s.io/networking#traefik-ingress-controller) as ingress the controller. In this environment Traefik is replaced by [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/). To install Traefik as the ingress controller set the variable `ingress_controller` to `default`.
For more details on Nginx ingress controller see the [Nginx ingress controller](#nginxingress-controller) section.

## Infrastructure overview

The final infrastructure will be made by:

* two instance pool:
  * one instance pool for the server nodes named `k3s-servers`
  * one instance pool for the worker nodes named `k3s-workers`
* one internal load balancer that will route traffic to K3s servers
* one external load balancer that will route traffic to K3s workers

The other resources created by terraform are:

* two instance configurations (one for the servers and one for the workers) used by the instance pools
* one vcn
* two public subnets
* two security list
* one dynamic group
* one identity policy

![k3s infra](https://garutilorenzo.github.io/images/k3s-oci-always-free.drawio.png?)

## Cluster resource deployed

This setup will automatically install [longhorn](https://longhorn.io/). Longhorn is a *Cloud native distributed block storage for Kubernetes*. To disable the longhorn deployment set `install_longhorn` variable to `false`.

**NOTE** to use longhorn set the `k3s_version` < `v1.25.x` [Ref.](https://github.com/longhorn/longhorn/issues/4003)

### Nginx ingress controller

In this environment [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/) is used instead of the standard [Traefik](https://docs.k3s.io/networking#traefik-ingress-controller) ingress controller.

The installation is the [bare metal](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters) installation, the ingress controller then is exposed via a NodePort Service.

```yaml
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
      nodePort: ${ingress_controller_http_nodeport} # default to 30080
    - name: https
      port: 443
      protocol: TCP
      targetPort: 443
      nodePort: ${ingress_controller_https_nodeport} # default to 30443
  type: NodePort
```

To get the real ip address of the clients using a public L4 load balancer we need to use the proxy protocol feature of nginx ingress controller:

```yaml
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
```

**NOTE** to use nginx ingress controller with the proxy protocol enabled, an external nginx instance is used as proxy (since OCI LB doesn't support proxy protocol at the moment). Nginx will be installed on each worker node and the configuation of nginx will:

* listen in proxy protocol mode
* forward the traffic from port `80` to `ingress_controller_http_nodeport` (default to `30080`) on any server of the cluster
* forward the traffic from port `443` to `ingress_controller_https_nodeport` (default to `30443`) on any server of the cluster

This is the final result:

Client -> Public L4 LB -> nginx proxy (with proxy protocol enabled) -> nginx ingress (with proxy protocol enabled) -> k3s service -> pod(s)

### Cert-manager

[cert-manager](https://cert-manager.io/docs/) is used to issue certificates from a variety of supported source. To use cert-manager take a look at [nginx-ingress-cert-manager.yml](deployments/nginx/nginx-ingress-cert-manager.yml) and [nginx-configmap-cert-manager.yml](deployments/nginx/nginx-configmap-cert-manager.yml) example. To use cert-manager and get the certificate you **need** set on your DNS configuration the public ip address of the load balancer.

## Deploy

We are now ready to deploy our infrastructure. First we ask terraform to plan the execution with:

```
terraform plan

...
...
      + id                             = (known after apply)
      + ip_addresses                   = (known after apply)
      + is_preserve_source_destination = false
      + is_private                     = true
      + lifecycle_details              = (known after apply)
      + nlb_ip_version                 = (known after apply)
      + state                          = (known after apply)
      + subnet_id                      = (known after apply)
      + system_tags                    = (known after apply)
      + time_created                   = (known after apply)
      + time_updated                   = (known after apply)

      + reserved_ips {
          + id = (known after apply)
        }
    }

Plan: 27 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + k3s_servers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + k3s_workers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + public_lb_ip    = (known after apply)

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

now we can deploy our resources with:

```
terraform apply

...
...
      + is_preserve_source_destination = false
      + is_private                     = true
      + lifecycle_details              = (known after apply)
      + nlb_ip_version                 = (known after apply)
      + state                          = (known after apply)
      + subnet_id                      = (known after apply)
      + system_tags                    = (known after apply)
      + time_created                   = (known after apply)
      + time_updated                   = (known after apply)

      + reserved_ips {
          + id = (known after apply)
        }
    }

Plan: 27 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + k3s_servers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + k3s_workers_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + public_lb_ip    = (known after apply)

  Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
  Enter a value: yes

...
...

module.k3s_cluster.oci_network_load_balancer_backend.k3s_kube_api_backend[0]: Still creating... [50s elapsed]
module.k3s_cluster.oci_network_load_balancer_backend.k3s_kube_api_backend[0]: Still creating... [1m0s elapsed]
module.k3s_cluster.oci_network_load_balancer_backend.k3s_kube_api_backend[0]: Creation complete after 1m1s [...]

Apply complete! Resources: 27 added, 0 changed, 0 destroyed.

Outputs:

k3s_servers_ips = [
  "X.X.X.X",
  "X.X.X.X",
]
k3s_workers_ips = [
  "X.X.X.X",
  "X.X.X.X",
]
public_lb_ip = tolist([
  "X.X.X.X",
])
```

Now on one master node you can check the status of the cluster with:

```
ssh X.X.X.X -lubuntu

ubuntu@inst-iwlqz-k3s-servers:~$ sudo su -
root@inst-iwlqz-k3s-servers:~# kubectl get nodes

NAME                     STATUS   ROLES                       AGE     VERSION
inst-axdzf-k3s-workers   Ready    <none>                      4m34s   v1.22.6+k3s1
inst-hmgnl-k3s-servers   Ready    control-plane,etcd,master   4m14s   v1.22.6+k3s1
inst-iwlqz-k3s-servers   Ready    control-plane,etcd,master   6m4s    v1.22.6+k3s1
inst-lkvem-k3s-workers   Ready    <none>                      5m35s   v1.22.6+k3s1
```

#### Public LB check

We can now test the public load balancer, nginx ingress controller and the security list ingress rules. On your local PC run:

```
curl -v http://<PUBLIC_LB_IP>

*   Trying PUBLIC_LB_IP:80...
* TCP_NODELAY set
* Connected to PUBLIC_LB_IP (PUBLIC_LB_IP) port 80 (#0)
> GET / HTTP/1.1
> Host: PUBLIC_LB_IP
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Fri, 25 Feb 2022 14:03:09 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host PUBLIC_LB_IP left intact
```

`404` is a correct response since the cluster is empty. We can test also the https listener/backends:

```
curl -k -v https://<PUBLIC_LB_IP>

* Trying PUBLIC_LB_IP:443...
* TCP_NODELAY set
* Connected to PUBLIC_LB_IP (PUBLIC_LB_IP) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: C=IT; ST=Italy; L=Brescia; O=GL Ltd; OU=IT; CN=testlb.domainexample.com; emailAddress=email@you.com
*  start date: Feb 25 10:28:29 2022 GMT
*  expire date: Feb 25 10:28:29 2023 GMT
*  issuer: C=IT; ST=Italy; L=Brescia; O=GL Ltd; OU=IT; CN=testlb.domainexample.com; emailAddress=email@you.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
> GET / HTTP/1.1
> Host: PUBLIC_LB_IP
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Date: Fri, 25 Feb 2022 13:48:19 GMT
< Content-Type: text/html
< Content-Length: 146
< Connection: keep-alive
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host PUBLIC_LB_IP left intact
```

#### Longhorn check

To check if longhorn was successfully installed run on one master nodes:

```
kubectl get ns
NAME              STATUS   AGE
default           Active   9m40s
kube-node-lease   Active   9m39s
kube-public       Active   9m39s
kube-system       Active   9m40s
longhorn-system   Active   8m52s   <- longhorn namespace 


root@inst-hmgnl-k3s-servers:~# kubectl get pods -n longhorn-system
NAME                                        READY   STATUS    RESTARTS        AGE
csi-attacher-5f46994f7-8w9sg                1/1     Running   0               7m52s
csi-attacher-5f46994f7-qz7d4                1/1     Running   0               7m52s
csi-attacher-5f46994f7-rjqlx                1/1     Running   0               7m52s
csi-provisioner-6ccbfbf86f-fw7q4            1/1     Running   0               7m52s
csi-provisioner-6ccbfbf86f-gwmrg            1/1     Running   0               7m52s
csi-provisioner-6ccbfbf86f-nsf84            1/1     Running   0               7m52s
csi-resizer-6dd8bd4c97-7l67f                1/1     Running   0               7m51s
csi-resizer-6dd8bd4c97-g66wj                1/1     Running   0               7m51s
csi-resizer-6dd8bd4c97-nksmd                1/1     Running   0               7m51s
csi-snapshotter-86f65d8bc-2gcwt             1/1     Running   0               7m50s
csi-snapshotter-86f65d8bc-kczrw             1/1     Running   0               7m50s
csi-snapshotter-86f65d8bc-sjmnv             1/1     Running   0               7m50s
engine-image-ei-fa2dfbf0-6rpz2              1/1     Running   0               8m30s
engine-image-ei-fa2dfbf0-7l5k8              1/1     Running   0               8m30s
engine-image-ei-fa2dfbf0-7nph9              1/1     Running   0               8m30s
engine-image-ei-fa2dfbf0-ndkck              1/1     Running   0               8m30s
instance-manager-e-31a0b3f5                 1/1     Running   0               8m26s
instance-manager-e-37aa4663                 1/1     Running   0               8m27s
instance-manager-e-9cc7cc9d                 1/1     Running   0               8m20s
instance-manager-e-f39d9f2c                 1/1     Running   0               8m29s
instance-manager-r-1364d994                 1/1     Running   0               8m26s
instance-manager-r-c1670269                 1/1     Running   0               8m20s
instance-manager-r-c20ebeb3                 1/1     Running   0               8m28s
instance-manager-r-c54bf9a5                 1/1     Running   0               8m27s
longhorn-csi-plugin-2qj94                   2/2     Running   0               7m50s
longhorn-csi-plugin-4t8jm                   2/2     Running   0               7m50s
longhorn-csi-plugin-ws82l                   2/2     Running   0               7m50s
longhorn-csi-plugin-zmc9q                   2/2     Running   0               7m50s
longhorn-driver-deployer-784546d78d-s6cd2   1/1     Running   0               8m58s
longhorn-manager-l8sd8                      1/1     Running   0               9m1s
longhorn-manager-r2q5c                      1/1     Running   1 (8m30s ago)   9m1s
longhorn-manager-s6wql                      1/1     Running   0               9m1s
longhorn-manager-zrrf2                      1/1     Running   0               9m
longhorn-ui-9fdb94f9-6shsr                  1/1     Running   0               8m59s
```

#### Argocd check

You can verify that all pods are running:
```
root@inst-hmgnl-k3s-servers:~# kubectl get pods -n argocd
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          8m51s
argocd-applicationset-controller-7b74965f8c-mjl97   1/1     Running   0          8m53s
argocd-dex-server-7f75d56bc6-j62hb                  1/1     Running   0          8m53s
argocd-notifications-controller-54dd686846-lggrz    1/1     Running   0          8m53s
argocd-redis-5dff748d9c-s5q2l                       1/1     Running   0          8m52s
argocd-repo-server-5576f8d84b-sgbbt                 1/1     Running   0          8m52s
argocd-server-76cf7d4c7b-jq9qx                      1/1     Running   0          8m52s
```

To fetch the initial admin password, to be able to do this you need to expose your kubeapi-server (set *expose_kubeapi* variable to ture) and fetch the
kubeconfig from one of the server nodes, it will be in (/var/lib/rancher/k3s/server/cred/admin.kubeconfig): 

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

To connect to the UI (make sure to copy the kubeconfig to your local machine first):

```
kubectl -n argocd port-forward service/argocd-server -n argocd 8080:443
```

After that you should be able to visit the ArgoCD UI: https://localhost:8080


## Deploy a sample stack

Finally to test all the components of the cluster we can deploy a sample stack. The stack is composed by the following components:

* MariaDB
* Nginx
* Wordpress

Each component is made by: one deployment and one service.
Wordpress and nginx share the same persistent volume (ReadWriteMany with longhorn storage class). The nginx configuration is stored in four ConfigMaps and  the nginx service is exposed by the nginx ingress controller.

Deploy the resources with:

```
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

**NOTE** The Wordpress installation is **secured**. To allow external traffic to `/wp-admin`, `/xmlrpc.php` and `wp-login.php` you have to edit the  [deployments/nginx/all-resources.yml](https://github.com/garutilorenzo/k3s-oci-cluster/blob/master/deployments/nginx/all-resources.yml) and change this line:

```yaml
- name: SECURE_SUBNET
  value: 8.8.8.8/32 # change-me
```

with your public ip address CIDR.

```
curl -o nginx-all-resources.yml https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/nginx/all-resources.yml

vi nginx-all-resources.yml

change SECURE_SUBNET and save the file

kubectl apply -f nginx-all-resources.yml
```

now check the status:

```
kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
mariadb       1/1     1            1           92m
nginx         1/1     1            1           79m
wordpress     1/1     1            1           91m

kubectl get svc
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes        ClusterIP   10.43.0.1       <none>        443/TCP    5h8m
mariadb-svc       ClusterIP   10.43.184.188   <none>        3306/TCP   92m
nginx-svc         ClusterIP   10.43.9.202     <none>        80/TCP     80m
wordpress-svc     ClusterIP   10.43.242.26    <none>        9000/TCP   91m
```

Now you are ready to setup WP, open the LB public ip and follow the wizard. **NOTE** nginx and the Kubernetes Ingress rule are configured without virthual host/server name.

![k3s wp install](https://garutilorenzo.github.io/images/k3s-wp.png?)

To clean the deployed resources:

```
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/nginx/all-resources.yml
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

## Clean up

```
terraform destroy
```

## Known Bugs

### 409-Conflict

If you see this error during the infrastructure destruction:

```
Error: 409-Conflict, Invalid State Transition of NLB lifeCycle state from Updating to Updating
│ Suggestion: The resource is in a conflicted state. Please retry again or contact support for help with service: Network Load Balancer Listener
│ Documentation: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/network_load_balancer_listener 
│ API Reference: https://docs.oracle.com/iaas/api/#/en/networkloadbalancer/20200501/Listener/DeleteListener 
```

re-run `terraform destroy`

### kubectl exec failure

The runc version in k3s containerd version 1.6.6 contains a regression that prevents anyone from executing a command and attaching to the container's TTY (exec -it) whenever someone runs systemctl daemon-reload. Alternatively, the user may run into this issue on SELinux-enforced systems. [Ref](https://github.com/k3s-io/k3s/issues/6064).

```
kubectl exec -it -n kube-system cilium-6lqp9 -- cilium status
Defaulted container "cilium-agent" out of: cilium-agent, mount-cgroup (init), apply-sysctl-overwrites (init), mount-bpf-fs (init), wait-for-node-init (init), clean-cilium-state (init)
error: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "b67e6e00172071996430dac5c97352e4d0c9fa3b3888e8daece5197c4649b4d1": OCI runtime exec failed: exec failed: unable to start container process: open /dev/pts/0: operation not permitted: unknown
```

To solve this issue downgrade to k3s v1.23
