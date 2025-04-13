## Sign in

List of user directories (or tenants):
- https://portal.azure.com/#settings/directory

Use the following command to connect to specific tenant:
```
az login --tenant 1d89b2e7-8369-4e1a-a379-d0959581d94b
```
## Kubectl node shell

```
brew install krew
kubectl krew install node-shell
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

kubectl get nodes -A
NAME                              STATUS   ROLES    AGE   VERSION
aks-default-14134004-vmss000000   Ready    <none>   14m   v1.29.15

kubectl node-shell aks-default-14134004-vmss000000
```

## Helm
```
brew install helm
helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
helm repo update
helm install -n azure-workload-identity-system authhook azure-workload-identity/workload-identity-webhook  --set azureTenantID=<account-id>  --create-namespace --namespace kube-system
```

## Install ingres
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm install ingress-nginx ingress-nginx/ingress-nginx --namespace default

helm upgrade ingress-nginx ingress-nginx/ingress-nginx --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"

helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"
```

https://cloud-provider-azure.sigs.k8s.io/topics/loadbalancer/#loadbalancer-annotations

service.beta.kubernetes.io/azure-load-balancer-resource-group

## Install cert-manager
```
helm repo add jetstack https://charts.jetstack.io --force-update
helm install cert-manager jetstack/cert-manager  --namespace default --version v1.15.3 --set crds.enabled=true
```

View all resources
```
kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges
```

## Deploy ingress
```
kubectl apply -f ingres.yaml --validate=false
```

## Check if I can connect to service
```
kubectl port-forward svc/nginx-service 8080:8080
kubectl port-forward svc/ingress-nginx-controller 8080:80
```

## Autoscale
```
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

## Debug
```
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" | jq
kubectl get deployment php-apache -o yaml | grep -A 3 "resources"
kubectl get apiservices | grep metrics
kubectl describe hpa php-apache
```

## Add node labels
```
kubectl label node akswipool000000 download=true
kubectl get nodes --show-labels
```

## Fix ingress
```
kubectl patch configmap ingress-nginx-controller -n default --type merge -p '{"data":{"allow-snippet-annotations":"true"}}'
helm upgrade ingress-nginx ingress-nginx/ingress-nginx --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"  --set controller.service.externalTrafficPolicy=Local
```

## Ingress modification
```
helm install ingress-nginx-cdn ingress-nginx/ingress-nginx \
  --set controller.service.type=NodePort \
  --set controller.ingressClassResource.name=nginx-cdn \
  --set controller.ingressClassResource.controllerValue=k8s.io/ingress-nginx-cdn \
  --set controller.config.use-forwarded-headers="true" \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"
```

## Ingress change
```
    nginx.ingress.kubernetes.io/server-snippet: |
      if ($host != 'subdomain.domain.com') {
        proxy_set_header X-Forwarded-For '1.1.1.1'
        return 200 "http_x_forwarded_for: $http_x_forwarded_for";
      }
```

## kubectl edit cm ingress-nginx-controller
```
apiVersion: v1
data:
  allow-snippet-annotations: "true"
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: ingress-nginx
    meta.helm.sh/release-namespace: default
  creationTimestamp: "2024-08-28T13:15:39Z"
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.11.2
    helm.sh/chart: ingress-nginx-4.11.2
  name: ingress-nginx-controller
  namespace: default
  resourceVersion: "1021333"
  uid: 74237d20-35df-44f1-ae90-c68393cadebb
```

## kubectl edit cm nginx-dump-configmap
```
apiVersion: v1
data:
  nginx.conf: |
    user nginx;
    worker_processes auto;
    events {
      worker_connections  10240;
    }
    http {
      include       /etc/nginx/mime.types;
      default_type  application/octet-stream;
      log_format custom 'LOG: $remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          'agent $http_user_agent host: $http_host x_forwarded_for: $http_x_forwarded_for - $http_x_forwarded_host end';
      access_log /dev/stdout custom;
      server {
          #http2 on;
          listen       80;
          server_name  _;
          location / {
            return 200 'GOOD';
          }
      }
    }
kind: ConfigMap
metadata:
  annotations:
  name: nginx-dump-configmap
  namespace: default
```

## kubectl get ingress
```
kubectl edit ingress download
```

Output:
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: cert-issuer
    meta.helm.sh/release-name: download
    meta.helm.sh/release-namespace: default
    nginx.ingress.kubernetes.io/configuration-snippet: |
      set $inject_ips "";
      if ($host = 'subdomain.domain.com') {
        set $inject_ips "$http_x_forwarded_for";
      }
      proxy_set_header X-Forwarded-For $inject_ips;
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
```

we need adjust the ``externalTrafficPolicy: Local`` value for LoadBalancer to get original customer ip address for load balancer

## Fix terraform state
```
terraform state list
terraform state rm helm_release.cert_manager
terraform state rm helm_release.ingress_nginx\[0\]
terraform state rm kubernetes_manifest.cluster_issuer\[0\]
terraform state rm kubernetes_manifest.app_service_account\[0\]
terraform destroy -var-file=environments/playground-eus1/terraform.tfvars -refresh=false
```

## Debug
```
kubectl get crd -A
kubectl api-resources
kubectl api-resources | grep -i issuer
```

## helm - dump template
```
helm template infra infra-chart \
  --set serviceAccount.name=$WORKLOAD_IDENTITY_NAME \
  --set serviceAccount.workloadClientId=$WORKLOAD_CLIENT_ID > infra.yaml
```

## kuber system node
```
System node:
2 CPU, 8 GB RAM
```

## get credentials
```
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

## Prepare for delete
```
az aks get-credentials --resource-group k-dev-eus1 --name=k-dev-eus1
kubectl config set-context k-dev-eus1
helm delete infra --namespace infra
helm delete download
```

## Arm based nodes
```
Standard_D2ps_v5
Standard_D4ps_v5
Standard_D2pls_v5

Testing: Standard_D4pls_v5
Prod: Standard_D8pls_v5
```

## Free space
```
fsutil volume diskfree C:/data
```

More disk commands:
```
C:\hpc>wmic logicaldisk get name
Name
C:
D:
E:

C:\hpc>diskpart

Microsoft DiskPart version 10.0.20348.1

Copyright (C) Microsoft Corporation.
On computer: akswpool000000

DISKPART> list disk

  Disk ###  Status         Size     Free     Dyn  Gpt
  --------  -------------  -------  -------  ---  ---
  Disk 0    Online          256 GB      0 B
  Disk 1    Online         2048 GB      0 B


C:\hpc>diskpart

Microsoft DiskPart version 10.0.20348.1

Copyright (C) Microsoft Corporation.
On computer: akswpool000000

DISKPART> list volume

  Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  Volume 0     D                       DVD-ROM         0 B  No Media
  Volume 1         System Rese  NTFS   Partition    500 MB  Healthy    System
  Volume 2     C   Windows      NTFS   Partition    255 GB  Healthy    Boot
  Volume 3     E                NTFS   Partition   2047 GB  Healthy

DISKPART> list disk

  Disk ###  Status         Size     Free     Dyn  Gpt
  --------  -------------  -------  -------  ---  ---
  Disk 0    Online          256 GB      0 B
  Disk 1    Online          300 GB      0 B

DISKPART> list volume

  Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  Volume 0     E                       DVD-ROM         0 B  No Media
  Volume 1         System Rese  NTFS   Partition    500 MB  Healthy    System
  Volume 2     C   Windows      NTFS   Partition    255 GB  Healthy    Boot
  Volume 3     D   Temporary S  NTFS   Partition    299 GB  Healthy    Pagefile
```

## Check gpu
```
kubectl describe node
kubectl describe node akswingpu000000
kubectl describe node akswingpu000000 | grep gpu
```

In shell:
```
Get-WmiObject win32_VideoController
nvidia-smi
Get-WmiObject win32_VideoController | findstr /i nvidia
```

Win GPU
```
az extension update --name aks-preview
az feature register --namespace "Microsoft.ContainerService" --name "WindowsGPUPreview"
az feature show --namespace "Microsoft.ContainerService" --name "WindowsGPUPreview"
```

## Kubernetes ui
```
helm repo add headlamp https://headlamp-k8s.github.io/headlamp/
helm install headlamp headlamp/headlamp --namespace kube-system --set nodeSelector."kubernetes\\.io/os"=linux
```

More commands:
```
kubectl port-forward service/my-headlamp -n kube-system 8000:80
kubectl describe deployment headlamp -n kube-system
kubectl port-forward service/headlamp -n kube-system 8000:80
image: ghcr.io/headlamp-k8s/headlamp:latest
kubectl create token headlamp -n kube-system
```


## Windows
```
bcdedit /set hypervisorlaunchtype auto
Enable-WindowsOptionalFeature -Online -FeatureName $("Microsoft-Hyper-V", "Containers") -All
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon .
sfc /scannow
```

docker run -it mcr.microsoft.com/windows/servercore:ltsc2022 powershell


## Get image size
```
kubectl get pods -o wide
kubectl node-shell akswpool000005 -- cmd
crictl images
```

## memory requirements
```
kubectl top pod
```

## Install prometheus
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace \
  --set alertmanager.nodeSelector."kubernetes.io/os"="linux" \
  --set nodeExporter.nodeSelector."kubernetes.io/os"="linux" \
  --set pushgateway.nodeSelector."kubernetes.io/os"="linux" \
  --set server.nodeSelector."kubernetes.io/os"="linux"
```

## Windows nvidia
kubectl describe pod win-test
accelerator=nvidia

```
dir C:\Windows\System32\nvcuda.dll
Get-WmiObject win32_VideoController | findstr /i nvidia

tasklist
tasklist /m /fi "imagename eq nv*"
INFO: No tasks are running which match the specified criteria.

Get-WmiObject Win32_Process


Get-WmiObject win32_VideoController
```

NVIDIA Tesla T4

curl - O https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi
curl -O https://developer.download.nvidia.com/compute/cuda/11.6.0/local_installers/cuda_11.6.0_511.23_windows.exe

```
Invoke-WebRequest https://developer.download.nvidia.com/compute/cuda/12.6.2/local_installers/cuda_12.6.2_560.94_windows.exe -OutFile cuda.exe
Start-Process c:\cuda.exe -ArgumentList '-s -n' -Wait

Invoke-WebRequest https://us.download.nvidia.com/tesla/566.03/566.03-data-center-tesla-desktop-winserver-2022-dch-international.exe -OutFile tesla.exe
Start-Process c:\tesla.exe -ArgumentList '-s -n' -Wait

Start-Process c:\cuda.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait

cuda.exe -s -n

Start-Process c:\cuda.exe -ArgumentList '-s -n' -Wait

control /name Microsoft.DeviceManager

Start-Process c:\tesla.exe -ArgumentList '-s -n' -Wait

nvidia-smi
Get-ChildItem -Path . -Recurse -ErrorAction SilentlyContinue -Filter *.exe
Get-ChildItem -Path . -Recurse -ErrorAction SilentlyContinue -Filter nvidia-smi.exe

NVIDIA T4, T4G - architecture: NVIDIA Turing
```

https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-565-57-01/index.html


https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-550-54-14/index.html


nvcuda dlls are provided by the installation of the windows GPU driver on a windows system that has a CUDA-capable GPU installed.

OLD: C:\Program Files\NVIDIA Corporation\NVSMI
C:\Windows\System32\DriverStore\FileRepository\nvdm*\nvidia-smi.exe

nvidia-smi -q

https://www.googlecloudcommunity.com/gc/Infrastructure-Compute-Storage/Windows-Server-2022-VM-with-Tesla-T4-not-able-to-use-GPU/m-p/663346/highlight/true


https://www.nvidia.com/download/driverResults.aspx/228680/en-us/


## terminate process
```
taskkill /F /IM cuda.exe
SUCCESS: The process "cuda.exe" with P
```

## Linux cuda
```
nvidia/cuda:12.6.2-base

kubectl run -it gpu-test --image=nvidia/cuda:12.6.2-runtime-ubuntu24.04 --restart=Never --overrides='{"spec": {"nodeSelector": {"accelerator": "nvidia","kubernetes.io/os":"linux"}}}' --command -- bash

kubectl run -it gpu-test --image=nvidia/cuda:12.6.2-base-ubuntu24.04 --restart=Never --overrides='{"spec": {"nodeSelector": {"accelerator": "nvidia","kubernetes.io/os":"linux"}}}' --command -- bash

kubectl delete pod gpu-test

kubectl describe pod gpu-test

root@gpu-test:/# nvidia-smi
Sun Nov 17 13:29:59 2024
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.90.12              Driver Version: 550.90.12      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000001:00:00.0 Off |                  Off |
| N/A   34C    P8              8W /   70W |       1MiB /  16384MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

```
dpkg -l | grep cuda
ii  cuda-compat-12-6                560.35.03-1                             amd64        CUDA Compatibility Platform
ii  cuda-cudart-12-6                12.6.77-1                               amd64        CUDA Runtime native Libraries
ii  cuda-keyring                    1.1-1                                   all          GPG keyring for the CUDA repository
ii  cuda-libraries-12-6             12.6.2-1                                amd64        CUDA Libraries 12.6 meta-package
ii  cuda-nvrtc-12-6                 12.6.77-1                               amd64        NVRTC native runtime libraries
ii  cuda-nvtx-12-6                  12.6.77-1                               amd64        NVIDIA Tools Extension
ii  cuda-opencl-12-6                12.6.77-1                               amd64        CUDA OpenCL native Libraries
ii  cuda-toolkit-12-6-config-common 12.6.77-1                               all          Common config package for CUDA Toolkit 12.6.
ii  cuda-toolkit-12-config-common   12.6.77-1                               all          Common config package for CUDA Toolkit 12.
ii  cuda-toolkit-config-common      12.6.77-1                               all          Common config package for CUDA Toolkit.
hi  libnccl2                        2.23.4-1+cuda12.6                       amd64        NVIDIA Collective Communication Library (NCCL) Runtime
```


apt update
apt install libnvidia-encode-510

apt install -y libnvidia-encode-560 libnvidia-compute-560

```
apt install -y cuda-compat-12-6 cuda-cudart-12-6 cuda-libraries-12-6 cuda-nvrtc-12-6 cuda-nvtx-12-6 cuda-opencl-12-6 cuda-toolkit-12-6-config-common cuda-toolkit-12-config-common cuda-toolkit-config-common libnccl2 libcublas-12-6 libnvidia-encode-560 libnvidia-compute-560

nvidia-smi
nvcc --version

nvidia-utils-560
```

```
ls -al /usr/lib/x86_64-linux-gnu/libcuda*

ls -l /usr/lib/x86_64-linux-gnu/libcudadebugger.so.1
lrwxrwxrwx 1 root root 28 Nov 18 10:52 /usr/lib/x86_64-linux-gnu/libcudadebugger.so.1 -> libcudadebugger.so.560.35.03


rm /usr/lib/x86_64-linux-gnu/libcudadebugger.so.550.90.12
rm /usr/lib/x86_64-linux-gnu/libcuda.so.550.90.12
lsof | grep libcudadebugger.so.550.90.12
lsof | grep libcuda.so.550.90.12

apt install software-properties-common
```

```

kubectl run -it gpu-test --image=ubuntu:22.04 --restart=Never --overrides='{"spec": {"nodeSelector": {"accelerator": "nvidia","kubernetes.io/os":"linux"}}}' --command -- bash

apt install cuda-compat-12-6 libnvidia-encode-560 libnvidia-compute-560 cuda-libraries-12-6 nvidia-utils-560 nvidia-driver-560

apt install kmod

cuda-nvtx-12-6

apt install ubuntu-drivers-common
ubuntu-drivers devices

ls -al /usr/lib/x86_64-linux-gnu/libcudadebugger.so*
```

```
kubectl run -it gpu-test --image=nvidia/cuda:12.4.1-base-ubuntu22.04 --restart=Never --overrides='{"spec": {"nodeSelector": {"accelerator": "nvidia","kubernetes.io/os":"linux"}}}' --command -- bash

root@gpu-test:/# ls -al /usr/lib/x86_64-linux-gnu/libcudadebugger.so*
lrwxrwxrwx 1 root root       28 Nov 18 13:40 /usr/lib/x86_64-linux-gnu/libcudadebugger.so.1 -> libcudadebugger.so.550.90.12
-rwxr-xr-x 1 root root 10524136 Nov 18 08:09 /usr/lib/x86_64-linux-gnu/libcudadebugger.so.550.90.12

apt install -y libnvidia-encode-550 libnvidia-compute-550

nvidia-smi
Failed to initialize NVML: Driver/library version mismatch
NVML library version: 550.127
```

```
kubectl run -it gpu-test --image=nvidia/cuda:12.6.2-base-ubuntu22.04 --restart=Never --overrides='{"spec": {"nodeSelector": {"accelerator": "nvidia","kubernetes.io/os":"linux"}}}' --command -- bash

lrwxrwxrwx 1 root root       28 Nov 18 13:48 /usr/lib/x86_64-linux-gnu/libcudadebugger.so.1 -> libcudadebugger.so.560.35.03
-rwxr-xr-x 1 root root 10524136 Nov 18 08:09 /usr/lib/x86_64-linux-gnu/libcudadebugger.so.550.90.12
-rw-r--r-- 1 root root 10182600 Aug 16 21:08 /usr/lib/x86_64-linux-gnu/libcudadebugger.so.560.35.03

apt install -y libnvidia-encode-550 libnvidia-compute-550
apt remove --purge libnvidia-encode-550 libnvidia-compute-550


Get:1 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64  libnvidia-compute-550 550.127.05-0ubuntu1 [49.5 MB]
Get:2 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64  libnvidia-decode-550 550.127.05-0ubuntu1 [1787 kB]
Get:3 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64  libnvidia-encode-550 550.127.05-0ubuntu1 [98.9 kB]

+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.90.12              Driver Version: 550.90.12      CUDA Version: 12.6     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000001:00:00.0 Off |                    0 |
| N/A   30C    P8             13W /   70W |       1MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

```
ubuntu-drivers install --gpgpu
```

https://launchpad.net/ubuntu/oracular/amd64/libnvidia-common-550-server/550.90.12-0ubuntu2

```
apt update
apt install -y wget
wget https://launchpad.net/ubuntu/+archive/primary/+files/libnvidia-encode-550-server_550.90.12-0ubuntu2_amd64.deb
wget https://launchpad.net/ubuntu/+archive/primary/+files/libnvidia-decode-550-server_550.90.12-0ubuntu2_amd64.deb
wget https://launchpad.net/ubuntu/+archive/primary/+files/libnvidia-compute-550-server_550.90.12-0ubuntu2_amd64.deb

apt install -y libx11-6 libxext6 libx11-data

cd /usr/lib/x86_64-linux-gnu
rm libcuda.so.1

ln -s /usr/lib/x86_64-linux-gnu/libcuda.so.550.90.12 libcuda.so.1
ln -s /usr/lib/x86_64-linux-gnu/libcuda.so.550.90.12 libcuda.so.1
```

## Remove nodes
```
kubectl cordon akswingpu000001
kubectl drain akswingpu000001  --ignore-daemonsets
kubectl delete node akswingpu000001


## Az dns commands
---
```
az network dns record-set a show --resource-group dns --zone-name domain.com --name subdomain

az network dns record-set a delete --resource-group dns --zone-name domain.com --name subdomain

az network dns record-set a add-record --resource-group dns --zone-name domain.com --record-set-name subdomain --ipv4-address 1.2.3.4

az network dns record-set cname show --resource-group dns --zone-name domain.com --name subdomain

az network dns record-set list --resource-group dns  --zone-name domain.com  > dns-records.txt

az network dns record-set cname set-record --resource-group dns --zone-name domain.com --record-set-name subdomain --cname cname-domain.coom

```

## Working with crictl
```
crictl images
crictl inspect
crictl ps
```

## Create vm
```
az vm image list --publisher Canonical --sku gen2 --output table --all
az aks nodepool add --cluster-name kuber1 --resource-group test --name test --node-osdisk-type Ephemeral --node-vm-size Standard_D8ads_v6 --node-count 1 --os-type Windows --ssh-access disabled

https://github.com/hashicorp/terraform-provider-azurerm/issues/7947


## Lock / unlock
az lock list --resource-group  kuber1
az lock delete --ids "<recource-id>"

## Nodepool

az aks nodepool add --cluster-name k-playground-eus1 --resource-group k-playground-eus1 --name test --node-vm-size Standard_D8ads_v6 --node-count 1 --os-type Windows

az aks nodepool add --cluster-name k-playground-eus1 --resource-group k-playground-eus1 --name test --node-osdisk-size 100 --node-osdisk-type Managed --node-vm-size Standard_D8ads_v6 --node-count 1 --os-type Windows

az aks nodepool add --cluster-name k-playground-eus1 --resource-group k-playground-eus1 --name test --node-osdisk-type Ephemeral --node-vm-size Standard_D8ads_v6 --node-count 1 --os-type Windows --os-sku Windows2022 --aks-custom-headers UseWindowsGen2VM=true

curl https://aka.ms/installazurecliwindowsx64 -o install

az acr login --name domain --expose-token

curl https://aka.ms/installazurecliwindowsx64
crictl pull <image-name>

vi auth.json
{"auths":{"domain.azurecr.io":{"auth":"MDAwMDAwM...."}}}

echo -n '00000000-0000-0000-0000-000000000000:eyJhbGc,,' |  base64

%ProgramData%\containerd\config
%ProgramData%\containers\


echo {"auth":"MDAwMDAwMDAtMDAwMC0wMDAw....."}}} > %ProgramData%\containerd\auth.json

more %ProgramData%\containerd\auth.json

crictl pull --creds '00000000-0000-0000-0000-000000000000:eyJhbG...' <image-name>:<tag>


fsutil volume diskfree C:

echo %TIME%

10:08:43.20

crictl rmi --prune

crictl pull --creds 00000000-0000-0000-0000-000000000000:eyJhbGciOiJSUzI1NiIsInR5... <image-name>:<tag>

type %USERPROFILE%\.crictl\crictl.yaml

az aks nodepool add --cluster-name k-playground-eus1 --resource-group k-playground-eus1 --name test --node-osdisk-type Ephemeral --node-vm-size Standard_D8ads_v6 --node-count 1 --os-type Windows --os-sku Windows2022 --node-osdisk-size 400 --aks-custom-headers UseWindowsGen2VM=true

az aks nodepool add --cluster-name k-playground-eus1 --resource-group k-playground-eus1 --name test --node-osdisk-type Managed --node-vm-size Standard_D4s_v5 --node-count 2 --os-type Windows --os-sku Windows2022 --node-osdisk-size 128

## diskspd tool
```
curl -OL https://github.com/microsoft/diskspd/releases/download/v2.2/DiskSpd.ZIP
Invoke-WebRequest https://github.com/microsoft/diskspd/releases/download/v2.2/DiskSpd.ZIP  -OutFile DiskSpd.ZIP

.\diskspd -c100G -w100 -b8K -F4 -r -o128 -W30 -d30 -Sh testfile.dat
C:\hpc\DiskSpd\amd64\diskspd -c100G -w100 -b8K -F4 -r -o128 -W30 -d30 -Sh testfile.dat
```

###

kubectl apply -f image-pod.yaml

kubectl get pods -o wide | grep image
image-pod                   0/1     ContainerCreating   0          65s     <none>         aksm0d0000002                     <none>           <none>

crictl

crictl pull
crictl pull nginx:latest
crictl --log-level debug pull nginx:latest

5.10 seconds
crictl pull <image-name>:<tag>

crictl pull --creds 00000000-0000-0000-0000-000000000000:eyJhb...Q <image-name>:<tag>

crictl rmi <image-name>:<tag>


az vm stop --resource-group yuli-test --name yuli-test-vm
az vm update --resource-group yuli-test --name yuli-test-vm --set "additionalCapabilities.enableNestedVirtualization=true"
az vm start --resource-group yuli-test --name yuli-test-vm

az vm show --resource-group yuli-test --name yuli-test-vm --query hardwareProfile.vmSize -o tsv

https://azuremarketplace.microsoft.com/en-us/marketplace/apps/cloud-infrastructure-services.hyper-v-windows-2022?tab=PlansAndPrice

Get-WindowsFeature -Name Hyper-V

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --set-default-version 2
wsl.exe --install --no-distribution

appwiz.cpl
Install: Hyper-V


https://2bcloud.synerioncloud.com/SynerionWeb/Account/Login


Enable-WindowsOptionalFeature -Online -FeatureName $("Microsoft-Hyper-V", "Containers") -All
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

docker pull mcr.microsoft.com/windows/nanoserver:ltsc2022
docker run -it mcr.microsoft.com/windows/nanoserver:ltsc2022 cmd.exe

echo %TIME%
docker pull mcr.microsoft.com/windows/server:10.0.20348.2700
echo %TIME%

C:\Users\yuli>echo %TIME%
 7:48:10.30

C:\Users\yuli>docker pull mcr.microsoft.com/windows/server:10.0.20348.2700
10.0.20348.2700: Pulling from windows/server
01c4baad83ab: Pull complete
Digest: sha256:e55b41a14290c413852bee2d9f0d11d376c33d6b1eb242c6c9cf52c55302eb88
Status: Downloaded newer image for mcr.microsoft.com/windows/server:10.0.20348.2700
mcr.microsoft.com/windows/server:10.0.20348.2700

C:\Users\yuli>echo %TIME%
 7:53:08.37

az acr show --name domain --query loginServer --output tsv
az acr credential show --name domain --query "{username:username, password:passwords[0].value}" --output json

{
  "password": "5yq...",
  "username": "domain"
}

## multipass
```
brew install --cask multipass
multipass launch --name ubuntu
multipass launch --cpus <number> --mem <size> --disk <size> --name <instance-name>
multipass launch --name my-instance --cpus 2 --mem 2G --disk 20G
multipass list
multipass restart <instance-name>
multipass start <instance-name>
multipass stop <instance-name>
multipass delete <instance-name>
multipass logs <instance-name>
multipass restart
multipass purge
multipass shell ubuntu
multipass exec <instance-name> -- <command>
multipass mount <local-path> <instance-name>:<remote-path>
multipass unmount <instance-name>:<remote-path>
multipass transfer <local-file> <instance-name>:<remote-path>
multipass transfer <instance-name>:<remote-path> <local-file>
multipass find

multipass transfer -r ./code ubuntu:/home/ubuntu/code

```

```
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

curl "https://releases.hashicorp.com/terraform/1.10.3/terraform_1.10.3_linux_arm64.zip" -o terraform.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
terraform --version
```

```
sudo apt install ntpdate
sudo ntpdate -u pool.ntp.org
sudo timedatectl set-ntp true
```
