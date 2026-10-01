---
name: vault-secret
description: Adds, reads, rotates and grants secrets in the homelab's Vault — engine and path, keys, metadata, the policy that grants it, and how a pipeline or a cluster component reads it. Use whenever a secret is added, changed, shared or a new consumer needs one.
---

# Secrets in Vault

Every secret in this org lives in the cluster's Vault, and in no repo, not
even encrypted (operator decision, 2026-10-01, `.github#6`). The `vault` repo
configures engines, roles and policies, never values. The full standard is in
its `README.md`, "Secrets: the standard".

The `guard-files.sh` hook blocks writing a secrets file in a repo: `.env`,
`*secrets.yaml`, `*.sops.*`, private keys. This skill is the other half: where
the secret goes instead.

## Where it goes

`<engine>/<owner>/<name>`, lowercase and kebab-case. Keys inside are
`snake_case`.

| Engine | Holds | Read by |
|---|---|---|
| `ci/` | what the pipelines use, `ci/<repo>/<name>` | that repo's CI jobs, over JWT (GitHub's OIDC token) |
| `platform/` | the cluster's shared services, `platform/<namespace>/<name>` | Vault Secrets Operator, one Kubernetes auth role per namespace |
| `apps/` | the applications, `apps/<namespace>/<name>` | Vault Secrets Operator, per namespace |

A credential more than one consumer uses lives **once**, at
`<engine>/shared/<name>`, and each consumer's policy grants it **by name**.
Never `shared/*` whole. Never a second copy under another owner. The one
exception is a credential that crosses engines, such as the Cloudflare token in
`ci/shared/cloudflare` and `platform/shared/cloudflare`: two copies, rotated
together, and that fact is recorded next to both.

## Who writes it

The operator, from the laptop over WARP. You never write a secret value:
neither into a file, nor a command line, nor Vault. You write the policy and
the consumer's wiring, and hand the operator the commands for the value.

The commands follow the `vault` README, "Writing or rotating a secret":

- `vault login -no-print`;
- the value on stdin (`key=-`), from a downloaded file or `read -rs`, never
  typed into the command;
- `kv put` for a new secret, `kv patch` to change one key;
- then the metadata: `owner` and `rotated_at`.

## Granting it

- **A repo's CI:** in `vault`, its policy `policies/ci-<repo>.hcl` names the
  path (`ci/data/<repo>/*` covers its own; a shared one by its exact path).
  The repo's JWT role is in `environments/prod/terraform.tfvars`, `jwt_roles`.
  The caller passes it in `vault-secrets`:
  `ci/data/<path> <key> | <ENV_VAR> ;`, one per line, under the variable the
  code already reads.
- **A cluster component:** in `vault`, a policy named after the namespace and
  a `kubernetes_roles` entry, bound to its `vault-secrets` service account. In
  `gitops`, `<component>/vault-secrets.yaml` holds that ServiceAccount, a
  `VaultAuth` and a `VaultStaticSecret` per secret, writing a `*-vault` Secret.
  Use `transformation` when the consumer needs only some keys.

## Rotating

1. The operator issues the new value at its provider.
2. The operator writes it with `kv patch`, then updates `rotated_at`.
3. Check that a consumer used it: a pipeline run, or the `VaultStaticSecret` refreshed.
4. Revoke the old value at the provider.

A shared secret is one write: every consumer follows.

## Check before calling it done

- No value anywhere in the tree, the diff, a commit message or a PR body.
- The path follows `<engine>/<owner>/<name>`, and a shared one sits under
  `shared/` and is granted by name.
- The policy and the role exist in `vault`, and the consumer's `vault-secrets`
  or `VaultStaticSecret` reads exactly that path.
- The operator has the commands to write the value. Do not record a secret as
  rotated until the operator says so.
