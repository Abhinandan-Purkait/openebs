#!/usr/bin/env bash

# Pull kubectl plugin bundle from GHCR OCI artifact.
# Downloads a single tarball containing all platform binaries.
# Usage: ./pull-kubectl-from-ghcr.sh --tag <tag> --namespace <ghcr-path> --username <user> --password <token>

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]:-"$0"}")")"
ROOT_DIR="$SCRIPT_DIR/../.."

source "$ROOT_DIR/mayastor/scripts/utils/log.sh"

TAG=""
NAMESPACE=""
USERNAME=""
PASSWORD=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --tag)
      TAG="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    *)
      log_fatal "Unknown option: $1"
      ;;
  esac
done

# Validate required arguments
if [[ -z "$TAG" ]] || [[ -z "$NAMESPACE" ]] || [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
  log_fatal "Usage: $0 --tag <tag> --namespace <namespace> --username <username> --password <password>"
fi

echo "Pulling kubectl binaries bundle from ${NAMESPACE} for release ${TAG}"

NAMESPACE="${NAMESPACE%/}"

REGISTRY_HOST=$(echo "$NAMESPACE" | cut -d'/' -f1)

echo "Logging in to ${REGISTRY_HOST}..."
echo "${PASSWORD}" | oras login "${REGISTRY_HOST}" --username "${USERNAME}" --password-stdin

echo "Pulling kubectl bundle..."

oras pull "${NAMESPACE}:${TAG}"

bundle_tar=$(find . -name "kubectl-openebs-all-platforms-*.tar.gz" -type f | head -1)

if [[ -z "$bundle_tar" ]]; then
  log_fatal "Error: Could not find kubectl bundle tarball"
fi

echo "Extracting bundle to artifacts directory"

mkdir -p artifacts/
tar -xzf "$bundle_tar" -C artifacts/
rm -f "$bundle_tar"

echo "Contents of artifacts directory after extraction:"
ls -la artifacts/

echo "All kubectl binaries pulled successfully!"
