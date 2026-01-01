# Opsify Control Plane Repository

This repository contains ArgoCD ApplicationSet configurations for applications managed by Opsify.

## Structure

```
applicationsets/
  ├── {app-name}-applicationset.yaml    # ApplicationSet definitions (auto-generated)
```

## Quick Start: Connecting to ArgoCD

### Step 1: Add Repository to ArgoCD

**Via ArgoCD UI:**

1. Go to **Settings** → **Repositories**
2. Click **Connect Repo**
3. Enter your repository URL and credentials

**Via CLI:**

```bash
argocd repo add https://github.com/your-org/opsify-control-plane \
  --name control-repo \
  --username your-username \
  --password your-token
```

### Step 2: Create Parent ApplicationSet

The parent ApplicationSet watches this repository and automatically discovers ApplicationSets.

**Option A: Use the setup script**

```bash
chmod +x setup-argocd.sh
./setup-argocd.sh
```

**Option B: Manual setup**

1. Edit `parent-applicationset.yaml` and replace `REPLACE_WITH_YOUR_CONTROL_REPO_URL` with your repository URL
2. Apply it:

```bash
kubectl apply -f parent-applicationset.yaml -n argocd
```

### Step 3: Verify

```bash
# Check ApplicationSet
kubectl get applicationset -n argocd

# Check generated Applications
kubectl get applications -n argocd
```

## How It Works

1. **Opsify generates ApplicationSets**: When you onboard an app in Opsify, it automatically creates an ApplicationSet YAML file in `applicationsets/` and commits it to this repository.

2. **ArgoCD watches the repository**: The parent ApplicationSet uses a Git generator to scan the `applicationsets/` directory.

3. **Applications are generated**: For each ApplicationSet found, ArgoCD creates an ApplicationSet resource in the cluster.

4. **Applications are deployed**: Each ApplicationSet generates ArgoCD Applications for each environment, which ArgoCD then syncs and deploys.

## Troubleshooting

### ArgoCD not detecting changes

- Ensure the repository is properly configured in ArgoCD Settings → Repositories
- Check that the parent ApplicationSet is in `Synced` status
- Verify the repository URL and branch are correct

### ApplicationSets not being created

- Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller`
- Verify the ApplicationSet YAML syntax is valid
- Ensure the target clusters are registered in ArgoCD

### Authentication issues

- For HTTPS: Use a Personal Access Token or App Password
- For SSH: Ensure SSH keys are configured in ArgoCD
- Check repository permissions in your Git provider

## Manual ApplicationSet Template

If you need to manually create an ApplicationSet, use this template:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: your-app-applicationset
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - cluster: cluster-name
            namespace: default
            server: https://kubernetes.default.svc
            environment: prod
  template:
    metadata:
      name: "your-app-{{environment}}"
    spec:
      project: default
      source:
        repoURL: https://github.com/your-org/your-app
        targetRevision: main
        path: charts/your-app
        helm:
          releaseName: "your-app-{{environment}}"
      destination:
        server: "{{server}}"
        namespace: "{{namespace}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

## Support

For more detailed setup instructions, see `backend/src/utils/argocdSetup.md` in the Opsify backend repository.
