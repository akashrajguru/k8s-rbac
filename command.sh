# Command to check kubernets API secured port 
kubectl config view -o jsonpath='{.clusters[?(@.name=="minikube")].cluster.server}'

kubectl config view -o jsonpath='{.clusters[?(@.name=="minikube")].cluster.certificate-authority}'