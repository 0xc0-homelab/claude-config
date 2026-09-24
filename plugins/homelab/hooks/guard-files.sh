#!/usr/bin/env bash
# Protects the state and prevents writing cleartext secrets.
set -uo pipefail

path="$(jq -r '.tool_input.file_path // ""')"
[ -z "$path" ] && exit 0

case "$path" in
  *.tfstate|*.tfstate.backup)
    echo "BLOCKED: the state is not edited by hand." >&2
    exit 2
    ;;
  *.auto.tfvars|*vault-pass*|*age.key*|*/id_ed25519|*/id_rsa)
    echo "BLOCKED: sensitive material. Secrets are encrypted with SOPS+age." >&2
    exit 2
    ;;
esac

# .env and secrets.yaml are only accepted in their encrypted form (.sops.*)
case "$path" in
  *secrets.yaml|*secrets.yml|*.env)
    case "$path" in
      *.sops.*|*.enc.*) ;;
      *)
        echo "BLOCKED: '$path' must be encrypted with SOPS. Use the .sops suffix (e.g. secrets.sops.yaml)." >&2
        exit 2
        ;;
    esac
    ;;
esac

exit 0
