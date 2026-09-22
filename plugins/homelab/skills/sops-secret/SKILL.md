---
name: sops-secret
description: Creates, edits and rotates SOPS+age encrypted secrets in any homelab repo — file naming, .sops.yaml creation rules, key handling and rotation. Use whenever a secret is added, changed, or a recipient is added or removed.
---

# SOPS+age secrets

Every secret in this org is encrypted with SOPS using age keys. An unencrypted
file holding sensitive material is a bug, not a TODO.

The `guard-files.sh` hook blocks writing a secret in the wrong shape. This
skill is the other half: the right shape.

## Naming — what the hook enforces

Blocked outright, always: `*.auto.tfvars`, `*vault-pass*`, `*age.key*`,
`id_ed25519`, `id_rsa`.

Allowed only in encrypted form: anything matching `*secrets.yaml`,
`*secrets.yml` or `*.env` must carry `.sops.` or `.enc.` in its name.

So the shape is `secrets.sops.yaml`, never `secrets.yaml`. Same for
`something.sops.env`.

## The `.sops.yaml` rules file

One per repo, at its root, committed. It maps paths to recipients so nobody has
to remember which key encrypts what:

```yaml
creation_rules:
  - path_regex: \.sops\.(yaml|yml)$
    encrypted_regex: '^(data|stringData|password|token|key|secret)$'
    age: age1...
```

- `path_regex` decides which files the rule covers.
- `age:` lists the **public** recipients, comma-separated for several.
- `encrypted_regex` keeps structural keys readable so diffs stay reviewable.
  Encrypting the whole file makes every change an opaque blob.

## Keys

The private age key never enters a repo. Not encrypted, not in a subdirectory,
not temporarily. `guard-files.sh` blocks `*age.key*` for this reason.

Public recipients belong in `.sops.yaml`, and they are not secret.

From phase 3 the secret backend migrates progressively to Vault over OIDC. Until
then, SOPS+age is the only mechanism.

## Procedure

**Create**

1. Confirm the repo has a `.sops.yaml` with a rule covering the path. If it has
   none, write it first.
2. Name the file with the `.sops.` infix.
3. Create it encrypted from the start: `sops <file>` opens an editor and writes
   ciphertext. Never write plaintext to disk "for a moment".
4. Confirm the result is ciphertext before staging it.

**Edit**

`sops <file>` in place. Never `sops -d > file`, edit, re-encrypt: that leaves
plaintext on disk and in the shell history, and it is how secrets leak into a
commit.

**Rotate a data key**

`sops rotate -i <file>` generates a new data key and re-encrypts.

**Add or remove a recipient**

Change the `age:` list in `.sops.yaml`, then `sops updatekeys <file>` for every
affected file. Adding a recipient to the rules file alone does nothing to files
already encrypted — this is the most common mistake.

Removing a recipient re-encrypts, but whoever held that key has already seen
the old ciphertext. If the secret itself is compromised, rotate the secret at
its source too, not just the file.

## Check before calling it done

- The filename carries `.sops.` and the content is ciphertext.
- A `creation_rules` entry actually matches the path.
- No plaintext copy left anywhere, including editor swap files.
- After a recipient change, `sops updatekeys` was run on every covered file.
- No private key anywhere in the tree.
