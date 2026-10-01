#!/usr/bin/env bash
# Protects the state and keeps secrets out of the repos: they live in Vault.
set -uo pipefail

path="$(jq -r '.tool_input.file_path // ""')"
[ -z "$path" ] && exit 0

case "$path" in
  *.tfstate|*.tfstate.backup)
    echo "BLOCKED: the state is not edited by hand." >&2
    exit 2
    ;;
  *.auto.tfvars|*vault-pass*|*age.key*|*/id_ed25519|*/id_rsa)
    echo "BLOCKED: sensitive material. Secrets live in Vault, never in a repo." >&2
    exit 2
    ;;
esac

# A secrets file, encrypted or not: no repo holds one any more (.github#6).
# gitops' vault-secrets.yaml is the exception: Vault Secrets Operator's
# manifests, which name Vault paths and hold no value.
case "$path" in
  */vault-secrets.yaml) ;;
  *secrets.yaml|*secrets.yml|*.env|*.sops.*|*.enc.*)
    echo "BLOCKED: '$path' would hold secrets in a repo. They live in Vault: see the vault-secret skill." >&2
    exit 2
    ;;
esac

exit 0
