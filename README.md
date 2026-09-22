# claude-config

Claude Code marketplace and plugin for the `0xc0-homelab` organization.

```
.claude-plugin/marketplace.json   the marketplace
plugins/homelab/                  the plugin
  agents/                         5 agents
  skills/                         1 skill
  hooks/                          guardrails (apply, secrets, firewall.tf)
```

## Consuming it from another repo

In the repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "0xc0-homelab": {
      "source": { "source": "github", "repo": "0xc0-homelab/claude-config" }
    }
  },
  "enabledPlugins": { "homelab@0xc0-homelab": true }
}
```

Once the project folder is trusted, the marketplace is added and the plugin
enables itself.

## Agents

| Agent                  | Type      | What for                                   |
|------------------------|-----------|--------------------------------------------|
| `network-reviewer`     | read-only | validates network and firewall vs `zones.md` |
| `iac-reviewer`         | read-only | OpenTofu, Packer, Ansible                  |
| `drift-hunter`         | read-only | drift between real state and code          |
| `infra-builder`        | builder   | implements in `infrastructure/`            |
| `deployments-builder`  | builder   | implements in `deployments/`               |

The read-only ones cannot edit (`disallowedTools: Edit, Write`). The builders
get closed specifications and stop if anything is ambiguous.

## Skills

| Skill          | What for                                                  |
|----------------|-----------------------------------------------------------|
| `sops-secret`  | create, edit and rotate SOPS+age secrets; recipient changes |

It lives in the plugin, not in a single repo, because secrets show up in all
of them. Skills tied to one repo live in that repo's `.claude/skills/`
instead — see `infrastructure/`.

## Hooks

- `no-apply.sh` — blocks `tofu/terraform apply|destroy` and `ansible-playbook`
  without `--check`.
- `guard-files.sh` — blocks hand-editing `firewall.tf` (it is generated from
  the matrix), touching the state, and writing secrets that are not encrypted
  with SOPS.
- `commit-msg.sh` — rejects a `git commit -m` whose subject is not a
  Conventional Commit, is over 72 characters, ends in a period, starts with a
  capital, or carries a `Co-Authored-By` / generated-by trailer.

They require `jq` on the PATH.

## Validate

```bash
claude plugin validate .
```
