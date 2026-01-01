#!/bin/bash

# Setup script to connect Opsify control repository to ArgoCD
# This script creates the parent ApplicationSet that watches the control repo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Opsify ArgoCD Setup Script${NC}"
echo "================================"
echo ""

# Get control repo URL
read -p "Enter your control repository URL (e.g., https://github.com/your-org/opsify-control-plane): " REPO_URL
if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Error: Repository URL is required${NC}"
    exit 1
fi

# Get branch (default: main)
read -p "Enter branch name [main]: " BRANCH
BRANCH=${BRANCH:-main}

# Get ArgoCD namespace (default: argocd)
read -p "Enter ArgoCD namespace [argocd]: " ARGOCD_NAMESPACE
ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}

echo ""
echo -e "${YELLOW}Creating parent ApplicationSet...${NC}"

# Create the parent ApplicationSet YAML
cat > parent-applicationset.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: opsify-applicationsets
  namespace: ${ARGOCD_NAMESPACE}
spec:
  generators:
    - git:
        repoURL: ${REPO_URL}
        revision: ${BRANCH}
        directories:
          - path: applicationsets/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: ${REPO_URL}
        targetRevision: ${BRANCH}
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: ${ARGOCD_NAMESPACE}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF

echo -e "${GREEN}✓ Created parent-applicationset.yaml${NC}"
echo ""
echo -e "${YELLOW}Applying ApplicationSet to ArgoCD...${NC}"

# Apply the ApplicationSet
kubectl apply -f parent-applicationset.yaml -n ${ARGOCD_NAMESPACE}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully created parent ApplicationSet in ArgoCD${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Add the control repository to ArgoCD:"
    echo "   - Go to ArgoCD UI → Settings → Repositories"
    echo "   - Click 'Connect Repo'"
    echo "   - Enter: ${REPO_URL}"
    echo "   - Add your Git credentials"
    echo ""
    echo "2. Verify the ApplicationSet:"
    echo "   kubectl get applicationset -n ${ARGOCD_NAMESPACE}"
    echo ""
    echo "3. Check generated Applications:"
    echo "   kubectl get applications -n ${ARGOCD_NAMESPACE}"
    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
else
    echo -e "${RED}✗ Failed to apply ApplicationSet${NC}"
    echo "Make sure:"
    echo "1. kubectl is configured and can access your cluster"
    echo "2. ArgoCD is installed in namespace: ${ARGOCD_NAMESPACE}"
    exit 1
fi

