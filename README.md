[![GitHub issues](https://img.shields.io/github/issues/garutilorenzo/k3s-oci-cluster)](https://github.com/garutilorenzo/k3s-oci-cluster/issues)
![GitHub](https://img.shields.io/github/license/garutilorenzo/k3s-oci-cluster)
[![GitHub forks](https://img.shields.io/github/forks/garutilorenzo/k3s-oci-cluster)](https://github.com/garutilorenzo/k3s-oci-cluster/network)
[![GitHub stars](https://img.shields.io/github/stars/garutilorenzo/k3s-oci-cluster)](https://github.com/garutilorenzo/k3s-oci-cluster/stargazers)

# OCI K3s cluster

Deploy a Kubernetes cluster for free, using K3s and Oracle [always free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) resources.

# Table of Contents

* [Important notes](#important-notes)
* [Requirements](#requirements)
* [Example RSA key generation](#example-rsa-key-generation)
* [Oracle provider setup](#oracle-provider-setup)
* [Pre flight checklist](#pre-flight-checklist)
* [Notes about OCI always free resources](#notes-about-oci-always-free-resources)
* [Notes about K3s](#notes-about-k3s)
* [Cluster resource deployed](#cluster-resource-deployed)
* [Deploy](#deploy)
* [Deploy a sample stack](#deploy-a-sample-stack)
* [Clean up](#clean-up)

**Note** choose a region with enough ARM capacity

### Important notes

* This is repo shows only how to use terraform with the Oracle Cloud infrastructure and use only the **always free** resources. This examples are **not** for a production environment.
* At the end of your trial period (30 days). All the paid resources deployed will be stopped/terminated
* At the end of your trial period (30 days), if you have a running compute instance it will be stopped/hibernated

### Requirements

To use this repo you will need:

* an Oracle Cloud account. You can register [here](https://cloud.oracle.com)

Once you get the account, follow the *Before you begin* and *1. Prepare* step in [this](https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-provider/01-summary.htm) document.

#### Example RSA key generation

To use terraform with the Oracle Cloud infrastructure you need to generate an RSA key. Generate the rsa key with:

```
openssl genrsa -out ~/.oci/<your_name>-oracle-cloud.pem 4096
chmod 600 ~/.oci/<your_name>-oracle-cloud.pem
openssl rsa -pubout -in ~/.oci/<your_name>-oracle-cloud.pem -out ~/.oci/<your_name>-oracle-cloud_public.pem
```

replace *<your_name>* with your name or a string you prefer.

**NOTE** ~/.oci/<your_name>-oracle-cloud_public.pem this string will be used on the *terraform.tfvars* used by the Oracle provider plugin, so please take note of this string.

### Oracle provider setup

In the *example/* directory of this repo you need to create a terraform.tfvars file, the file will look like:

```
fingerprint      = "<rsa_key_fingerprint>"
private_key_path = "~/.oci/<your_name>-oracle-cloud_public.pem"
user_ocid        = "<user_ocid>"
tenancy_ocid     = "<tenency_ocid>"
compartment_ocid = "<compartment_ocid>"
```

To find your tenency_ocid in the Ocacle Cloud console go to: Governance and Administration > Tenency details, then copy the OCID.

To find you user_ocid in the Ocacle Cloud console go to User setting (click on the icon in the top right corner, then click on User settings), click your username and then copy the OCID

The compartment_ocid is the same as tenency_ocid.

The fingerprint is the fingerprint of your RSA key, you can find this vale under User setting > API Keys

### Pre flight checklist

Once you have created the terraform.tfvars file edit the main.tf file (always in the *example/* directory) and set the following variables:

| Var   | Required | Desc |
| ------- | ------- | ----------- |
| `region`       | `yes`       | set the correct OCI region based on your needs  |
| `availability_domain` | `yes`        | Set the correct availability domain. See [how](#how-to-find-the-availability-doamin-name) to find the availability domain|
| `compartment_ocid` | `yes`        | Set the correct compartment ocid. See [how](#oracle-provider-setup) to find the compartment ocid |
| `cluster_name` | `yes`        | the name of your K3s cluster. Default: k3s-cluster |
| `k3s_token` | `yes`        | The token of your K3s cluster. [How to](#generate-random-token) generate a random token |
| `my_public_ip_cidr` | `yes`        |  your public ip in cidr format (Example: 195.102.xxx.xxx/32) |
| `environment`  | `yes`  | Current work environment (Example: staging/dev/prod). This value is used for tag all the deployed resources |
| `compute_shape`  | `no`  | Compute shape to use. Default VM.Standard.A1.Flex. **NOTE** Is mandatory to use this compute shape for provision 4 always free VMs |
| `os_image_id`  | `no`  | Image id to use. Default image: Canonical-Ubuntu-20.04-aarch64-2022.01.18-0. See [how](#how-to-list-all-the-os-images) to list all available OS images |
| `oci_core_vcn_cidr`  | `no`  | VCN CIDR. Default: oci_core_vcn_cidr |
| `oci_core_subnet_cidr10`  | `no`  | First subnet CIDR. Default: 10.0.0.0/24 |
| `oci_core_subnet_cidr11`  | `no`  | Second subnet CIDR. Default: 10.0.1.0/24 |
| `oci_identity_dynamic_group_name`  | `no`  | Dynamic group name. This dynamic group will contains all the instances of this specific compartment. Default: Compute_Dynamic_Group |
| `oci_identity_policy_name`  | `no`  | Policy name. This policy will allow dynamic group 'oci_identity_dynamic_group_name' to read OCI api without auth. Default: Compute_To_Oci_Api_Policy |
| `kube_api_port`  | `no`  | Kube api default port Default: 6443  |
| `public_lb_shape`  | `no`  | LB shape for the public LB. Default: flexible. **NOTE** is mandatory to use this kind of shape to provision two always free LB (public and private)  |
| `http_lb_port`  | `no`  | http port used by the public LB. Default: 80  |
| `https_lb_port`  | `no`  | http port used by the public LB. Default: 443  |
| `k3s_server_pool_size`  | `no`  | Number of k3s servers deployed. Default 2  |
| `k3s_worker_pool_size`  | `no`  | Number of k3s workers deployed. Default 2  |
| `install_longhorn`  | `no`  | Boolean value, install longhorn "Cloud native distributed block storage for Kubernetes". Default: true  |
| `longhorn_release`  | `no`  | Longhorn release. Default: v1.2.3  |
| `unique_tag_key`  | `no`  | Unique tag name used for tagging all the deployed resources. Default: k3s-provisioner |
| `unique_tag_value`  | `no`  | Unique value used with  unique_tag_key. Default: https://github.com/garutilorenzo/k3s-oci-cluster |
| `PATH_TO_PUBLIC_KEY`     | `no`       | Path to your public ssh key (Default: "~/.ssh/id_rsa.pub) |
| `PATH_TO_PRIVATE_KEY` | `no`        | Path to your private ssh key (Default: "~/.ssh/id_rsa) |

#### Generate random token

Generate random k3s token with:

```
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 55 | head -n 1
```

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

To filter the OS images by shape and OS run this command on che Cloud Shell:

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

**Note:** this setup was only tested with Ubuntu 20.04

## Notes about OCI always free resources

In order to get the maximum resources available within the oracle always free tier, the max amount of the k3s servers and k3s workers must be 2. So the max value for *k3s_server_pool_size* and *k3s_worker_pool_size* **is** 2.

In this setup we use two LB, one internal LB and one public LB. In order to use two LB using the always free resources, one lb must be a [network load balancer](https://docs.oracle.com/en-us/iaas/Content/NetworkLoadBalancer/introducton.htm#Overview) an the other must be a [load balancer](https://docs.oracle.com/en-us/iaas/Content/Balance/Concepts/balanceoverview.htm). The public LB **must** use the *flexible* shape (*public_lb_shape* variable).

## Notes about K3s

In this environment the High Availability of the K3s cluster is provided using the Embedded DB. More details [here](https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/)

K3s will automatically install [Traefik](https://traefik.io/). Traefik is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease. It simplifies networking complexity while designing, deploying, and running applications. More details [here](https://rancher.com/docs/k3s/latest/en/networking/#traefik-ingress-controller)

## Cluster resource deployed

This setup will automatically install [longhorn](https://longhorn.io/). Longhorn is a *Cloud native distributed block storage for Kubernetes*. To disable the longhorn deployment set *install_longhorn* variable to *false*

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

We can now test the public load balancer, traefik and the security list ingress rules. On your local PC run:

```
curl -v http://<PUBLIC_LB_IP>

*   Trying <PUBLIC_LB_IP>:80...
* TCP_NODELAY set
* Connected to <PUBLIC_LB_IP> (<PUBLIC_LB_IP>) port 80 (#0)
> GET / HTTP/1.1
> Host: <PUBLIC_LB_IP>
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< Content-Type: text/plain; charset=utf-8
< X-Content-Type-Options: nosniff
< Date: Mon, 21 Feb 2022 11:36:17 GMT
< Content-Length: 19
< 
404 page not found
* Connection #0 to host <PUBLIC_LB_IP> left intact
```

*404* is a correct response since the cluster is empty. We can test also the https listener/backends:

```
curl -k -v https://<PUBLIC_LB_IP>

*   Trying <PUBLIC_LB_IP>:443...
* TCP_NODELAY set
* Connected to <PUBLIC_LB_IP> (<PUBLIC_LB_IP>) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=TRAEFIK DEFAULT CERT
*  start date: Feb 21 11:30:28 2022 GMT
*  expire date: Feb 21 11:30:28 2023 GMT
*  issuer: CN=TRAEFIK DEFAULT CERT
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x55cac9ccde10)
> GET / HTTP/2
> Host: <PUBLIC_LB_IP>
> user-agent: curl/7.68.0
> accept: */*
> 
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* Connection state changed (MAX_CONCURRENT_STREAMS == 250)!
< HTTP/2 404 
< content-type: text/plain; charset=utf-8
< x-content-type-options: nosniff
< content-length: 19
< date: Mon, 21 Feb 2022 11:37:54 GMT
< 
404 page not found
* Connection #0 to host <PUBLIC_LB_IP> left intact
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

## Deploy a sample stack

Finally to test all the components of the cluster we can deploy a sample stack. The stack is composed by the following components:

* MariaDB
* Nginx
* Wordpress

Each component is made by: one deployment and one service.
Wordpress and nginx share the same persistent volume (ReadWriteMany with longhorn storage class). The nginx configuration is stored in two ConfigMaps and  the nginx service is exposed by Traefik ingress controller.

Deploy the resources with:

```
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/nginx/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

and check the status:

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

Now you are ready to setup WP, open the LB public ip and follow the wizard. **NOTE** nginx and Traefik are configured without virthual host/server name.

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