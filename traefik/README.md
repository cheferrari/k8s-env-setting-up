# Install Traefik
refers to https://docs.traefik.io/user-guide/kubernetes/
## 1. Deployments add affinity settings
Deployments add affinity settings to ensure that two pods don't end up on the same node.  
spec.template.spec.affinity
```
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: k8s-app
                operator: In
                values:
                - traefik-ingress-lb
            topologyKey: kubernetes.io/hostname
```

## 2. Install Traefik
### Deploy Traefik using a Deployment
```
kubectl apply -f traefik-rbac.yaml
kubectl apply -f traefik-deployment.yaml
```
### Deploy Traefik using a DaemonSet
```
kubectl apply -f traefik-rbac.yaml
kubectl apply -f traefik-ds.yaml
```

## 3. Traefik on k8s demo
[Traefik on k8s demo](https://github.com/cheferrari/k8s-ingress-controller-demo/tree/master/Traefik)
