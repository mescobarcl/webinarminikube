#Habilitar Hyper-v
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
#Agregar Usuario Grupo Hyper-V
Add-LocalGroupMember -Group "Hyper-V Administrators" -Member "$env:username"
#Instalacion Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#Reinicio PC
Restart-Computer -Confirm:$true

#Instalacion Dependencias
choco install -y kubernetes-helm Kubernetes-cli base64 minikube
#Configurar VM
minikube config set memory 8192 
minikube config set cpus 4
minikube start --kubernetes-version=v1.22.6 --vm-driver=hyperv --force 
#Configurar CSI
minikube addons enable csi-hostpath-driver
minikube addons enable volumesnapshots
#Configurar StorageClass
kubectl patch storageclass csi-hostpath-sc -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'
kubectl patch storageclass standard -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"false\"}}}'
#Instalacion Kasten K10
kubectl create ns kasten-io
helm repo add kasten https://charts.kasten.io/
kubectl annotate volumesnapshotclass csi-hostpath-snapclass k10.kasten.io/is-snapshot-class=true
helm install k10 kasten/k10 --namespace=kasten-io --set global.persistence.storageClass=csi-hostpath-sc --set prometheus.server.persistentVolume.enabled=false --set externalGateway.create=true --set auth.tokenAuth.enabled=true
kubectl get pods -n kasten-io

#Credenciales - Dejar en 1 Linea
$env:sa_secret = kubectl get serviceaccount k10-k10 -o jsonpath="{.secrets[0].name}" --namespace kasten-io
kubectl get secret $env:sa_secret --namespace kasten-io -o jsonpath="{.data.token}{'\n'}" | base64 -d

#Ejecutar en otra Ventana
Start-Process PowerShell -ArgumentList "minikube tunnel" -WindowStyle Minimized

#Ver Direccion IP para Acceder a K10
kubectl get svc gateway-ext -n kasten-io
#http://ipsvc/k10/

#Instalación Minio
helm repo add minio https://operator.min.io/
helm install --namespace minio-operator --create-namespace --generate-name minio/minio-operator
kubectl get pods -n minio-operator
kubectl get secret -n minio-operator
kubectl describe secret minio-operator-token-prq95 -n minio-operator #el nombre del secret varia, por tanto en el comando anteior copair nombre
kubectl get svc -n minio-operator

#Pacman
helm repo add veducate https://saintdle.github.io/helm-charts/
kubectl create ns pacman
helm install pacman veducate/pacman -n pacman

#Conseguir Direccion IP Pacman
kubectl get svc pacman -n pacman
kubectl get pods -n pacman
