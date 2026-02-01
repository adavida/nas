
```bash
# active configuration
nixos-rebuild switch --flake /etc/nixos#homenastest

# connect to vpn
tailscale up

kubectl create configmap ca-pemstore --from-file=rootCA.pem

# install ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install my-ingress ingress-nginx/ingress-nginx

# configMap  of secret
ssh root@ssh.nas.local -C 'kubectl create configmap ca-pemstore --from-file=/etc/nixos/secrets/certs/homeCA.pem'

#  Install/Update service 
helm upgrade --install app app --values ./app/values-test.yaml
```

```
cp secrets/olcRootPW app/secrets/authelia/ldap_password


# add ssh key
ssh-keygen -t ed25519 -C "david.adler@outlook.com"
cat ~/.ssh/id_ed25519.puby
```


occ maintenance 
```
kubectl exec -ti deployments/app-nextcloud -- su -s /bin/bash -c './occ maintenance:repair' www-data
kubectl exec -ti deployments/app-nextcloud -- su -s /bin/bash -c './occ security:bruteforce:reset' www-data

```