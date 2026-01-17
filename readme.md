
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
kubectl create configmap ca-pemstore --from-file=secret/rootCA.pem


#  Install/Update service 
helm upgrade --install app app --values ./app/values-test.yaml
```

```
# add ssh key
ssh-keygen -t ed25519 -C "david.adler@outlook.com"
cat ~/.ssh/id_ed25519.puby
```