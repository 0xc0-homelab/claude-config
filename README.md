# claude-config

Claude Code marketplace and plugin for the `0xc0-homelab` organization.

```
.claude-plugin/marketplace.json   the marketplace
plugins/homelab/                  the plugin
  agents/                         5 agents
  skills/                         1 skill
  hooks/                          guardrails, commit and branch conventions, board loader
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

That declares and enables the plugin; each machine still installs it once, as
described in **Installing** under Hooks.

## Agents

| Agent                  | Type      | What for                                   |
|------------------------|-----------|--------------------------------------------|
| `network-reviewer`     | read-only | validates network and firewall vs the transit matrix |
| `iac-reviewer`         | read-only | OpenTofu, Packer, Ansible                  |
| `drift-hunter`         | read-only | drift between real state and code          |
| `infra-builder`        | builder   | implements in `infrastructure/`            |
| `gitops-builder`       | builder   | implements in `gitops/`                    |

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

- `board.sh` — `SessionStart`: loads the open items of the org project board
  into every session, with the rule that no work starts without an issue.
- `no-apply.sh` — blocks `tofu/terraform apply|destroy`, and `ansible-playbook`
  or `scripts/ansible` without `--check`.
- `guard-files.sh` — blocks touching the state, and writing secrets that are
  not encrypted with SOPS. It only sees Edit and Write: a file written from a
  shell command is not checked.
- `commit-msg.sh` — rejects a commit whose message, from `-m` (grouped flags
  such as `-qam` included) or from a heredoc through `-F -`, has a subject that
  is not a Conventional Commit, is over 72 characters, ends in a period,
  starts with a capital, or carries a `Co-Authored-By` / generated-by trailer.
- `branch-name.sh` — rejects creating a branch (`git switch -c`, `git checkout
  -b`, with or without `-C <dir>`) whose name is not `<type>/<slug>`: a commit
  type, then lowercase letters, digits, `.` and `-`.

They require `jq` and `perl` on the PATH. `hooks/tests/run.sh` runs every case
in `hooks/tests/cases.jsonl` through its hook; the `hooks` workflow runs it on
every PR that touches them.

**Installing.** Declaring the plugin in a project's `.claude/settings.json`
enables it but does not install it. Once per machine, from the workspace:

```bash
claude plugin marketplace add 0xc0-homelab/claude-config
claude plugin install homelab@0xc0-homelab --scope project
```

Then start a new session: plugins load at startup.

## Validate

```bash
claude plugin validate .
```
