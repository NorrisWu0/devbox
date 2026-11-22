---
title: Out-of-memory freeze on 22 Nov 2026
description: Why devbox froze and was powered off on 22 Nov 2026, how to confirm it from the logs, and what to change.
---

## What am I looking at?

On 22 Nov 2026 devbox ran out of memory and froze for about 28 minutes. It was then powered off with the power button and booted again. It was not a kernel panic or a disk fault.

The VM has 8 GB of RAM (`tofu/main.tf`, `dedicated = 8192`) and **no swap**. When RAM filled up, the kernel had nowhere to push memory and stalled while it tried to free some.

## What happened?

All times are UTC.

| Time | Event |
| --- | --- |
| 11:35 | The OOM killer (the kernel's out-of-memory process killer) kills a process in `user@1000.service`. |
| 11:39 | `systemd` triggers another OOM kill. The box stops responding. SSH sessions time out. |
| 12:04 | `systemd-logind`: "Power key pressed short". |
| 12:06 | `systemd-logind`: "Powering off...". |
| 12:07 | Two more OOM kills: `systemd` (user) and a `node` process. |
| 12:08 | Clean shutdown. The next boot starts at 12:16. |

## What was using the memory?

Totals from the process table the kernel logged at the first OOM kill:

| Process | Count | Memory |
| --- | --- | --- |
| `node` | 15 | about 2.4 GB |
| `opencode` | 4 | about 1.0 GB |
| `pnpm` | 19 | about 0.5 GB |
| `nvim` | 10 | about 0.5 GB |
| Others (`python`, `terraform`, `k9s`, and so on) | — | about 1 GB |

Many dev tools were running at once on a VM with no swap. No single process was running away.

## How do I check this again?

Run these after a reboot. Use `-b -1` for the previous boot.

```sh
journalctl --list-boots
sudo journalctl -b -1 -k | grep -E "oom-killer|Out of memory: Killed"
sudo journalctl -b -1 | grep -E "Power key|Powering off"
free -h
```

## What should we change?

These are recommendations. None are applied yet.

1. Add swap or zram so the VM slows down instead of freezing.
2. Run `earlyoom` or `systemd-oomd` so the largest process is killed early.
3. Raise `memory.dedicated` in `tofu/main.tf`, or close idle `nvim`, `opencode`, and `node` sessions.

## Is there any external references to this documentation?

- [Getting started](../getting-started.md) — how to connect to devbox.
- [Markdown documentation skill](https://github.com/nori-cloud/agents/blob/main/skills/markdown-documentation/SKILL.md) — the layout this page follows.
