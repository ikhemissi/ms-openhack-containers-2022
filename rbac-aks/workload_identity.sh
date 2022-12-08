export SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
export USER_ASSIGNED_IDENTITY_NAME="id-trip-sql"
export RG_NAME="teamResources"
export LOCATION="westus"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SERVICE_ACCOUNT_NAMESPACE="api"

# az identity create --name "$USER_ASSIGNED_IDENTITY_NAME" --resource-group "$RG_NAME" --location "$LOCATION" --subscription "$SUBSCRIPTION_ID"
export USER_ASSIGNED_IDENTITY_CLIENT_ID="$(az identity show --name id-trip-sql --resource-group teamResources --query clientId --output tsv)"

az aks update -g teamResources -n AKS-OPTeam5 --enable-oidc-issuer --enable-workload-identity

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: "${USER_ASSIGNED_CLIENT_ID}"
  labels:
    azure.workload.identity/use: "true"
  name: "${SERVICE_ACCOUNT_NAME}"
  namespace: "${SERVICE_ACCOUNT_NAMESPACE}"
EOF


export AKS_OIDC_ISSUER="$(az aks show -n AKS-OPTeam5 -g teamResources --query "oidcIssuerProfile.issuerUrl" -otsv)"


# CREATE USER [id-trip-sql] FROM EXTERNAL PROVIDER
# ALTER ROLE db_owner ADD MEMBER [id-trip-sql]

az identity federated-credential create --name "id-fed-wi" --identity-name "$USER_ASSIGNED_IDENTITY_NAME" --resource-group "$RG_NAME" --issuer "$AKS_OIDC_ISSUER" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}"


