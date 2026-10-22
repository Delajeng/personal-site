---
title: "Lab overview"
date: 2026-09-28
summary: "What runs where, and how traffic gets in."
tags: ["proxmox", "truenas", "networking"]
weight: 10
---

## Overview

{{< alert icon="circle-info" >}}
Example page - replace it with your own layout. It's here to show how docs pages look.
{{< /alert >}}

| Host | Role | Runs |
| ---- | ---- | ---- |
| Proxmox | Hypervisor | LXCs / VMs: Docker host, Vaultwarden, Crafty, monitoring |
| TrueNAS SCALE | Storage (bare metal) | Jellyfin, Kavita, Immich |
| Hetzner VPS | Edge | Pangolin tunnel endpoint, uptime monitoring |

## How traffic gets in

{{< mermaid >}}
flowchart LR
  V[Visitor] -->|HTTPS| CF[Cloudflare]
  CF -->|Tunnel| D[Docker LXC]
  D --> S[site container :8080]
  A[Admin] -->|Tailscale| PX[Proxmox UI]
{{< /mermaid >}}

## Rebuild checklist

1. Restore the Proxmox host config from backup.
2. Recreate LXCs from the Terraform / community scripts.
3. `docker compose up -d` on the Docker host.
