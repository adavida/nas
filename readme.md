
```bash
# active configuration
nixos-rebuild switch --flake /etc/nixos#homenas

# create secrets and push into k8s cluster
cd /etc/nixos/secrets/
make BASE_DOMAIN=nas.local
make BASE_DOMAIN=nas.local k8s

scp root@ssh.nas.local:/etc/nixos/secrets/rootCA.pem rootCA.pem
sudo cp rootCA.pem /etc/nixos/rootCA.pem

# connect to vpn
tailscale up

# install ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install my-ingress ingress-nginx/ingress-nginx

# configMap  of secret
ssh root@ssh.nas.local -C 'kubectl create configmap ca-pemstore --from-file=/etc/nixos/secrets/certs/homeCA.pem'

bash app/generate-secret.sh

#  Install/Update service 
helm upgrade --install app app --values ./app/values.yaml
```

```
# add ssh key
ssh-keygen -t ed25519 -C "david.adler@outlook.com"
cat ~/.ssh/id_ed25519.puby
```


occ maintenance 
```
kubectl exec -ti deployments/app-nextcloud -- su -s /bin/bash -c './occ maintenance:repair' www-data
kubectl exec -ti deployments/app-nextcloud -- su -s /bin/bash -c './occ security:bruteforce:reset' www-data

```