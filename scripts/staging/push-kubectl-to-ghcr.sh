#!/usr/bin/env bash
# Push kubectl plugin binaries to GHCR as OCI artifacts.
# Handles both direct tar.gz files and GitHub Actions artifact structure.
# Usage: ./push-kubectl-to-ghcr.sh --tag <tag> --namespace <ghcr-path> --username <user> --password <token>

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

if [[ -z "$TAG" ]] || [[ -z "$NAMESPACE" ]] || [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]]; then
  log_fatal "Usage: $0 --tag <tag> --namespace <namespace> --username <username> --password <password>"
fi

NAMESPACE="${NAMESPACE%/}"

# Extract registry host from full registry path
REGISTRY_HOST=$(echo "$NAMESPACE" | cut -d'/' -f1)

echo "Logging in to ${REGISTRY_HOST}..."
echo "${PASSWORD}" | oras login "${REGISTRY_HOST}" --username "${USERNAME}" --password-stdin

echo "Pushing kubectl binaries to ${NAMESPACE} with tag ${TAG}"

# Create a combined tarball of all kubectl binaries
echo "Creating combined tarball of all kubectl binaries..."
combined_tar="kubectl-openebs-all-platforms-${TAG}.tar.gz"

tar -czf "${combined_tar}" -C artifacts .

echo "Pushing combined tarball to ${NAMESPACE}:${TAG}"

oras push "${NAMESPACE}:${TAG}" \
  --artifact-type application/vnd.openebs.kubectl.bundle.v1+tar+gzip \
  "${combined_tar}:application/gzip"

rm -f "${combined_tar}"

echo "✓ All kubectl binaries pushed successfully as a single bundle!"
echo "Bundle available at: ${NAMESPACE}:${TAG}"
