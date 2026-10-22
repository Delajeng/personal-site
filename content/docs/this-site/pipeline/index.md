---
title: "Build and deploy pipeline"
date: 2026-09-28
summary: "Git push to live site in about three minutes."
tags: ["hugo", "github-actions", "docker", "ci-cd"]
weight: 10
---

## Overview

The site is Markdown in a Git repo, built by [Hugo](https://gohugo.io/) with the
[Blowfish](https://blowfish.page/) theme, packaged as an nginx container and pulled by the homelab.

{{< mermaid >}}
flowchart LR
  A[git push main] --> B[GitHub Actions]
  B -->|hugo build + docker build| C[(GHCR image)]
  C -->|cron pulls every 5 min| D[Docker host]
  V[Visitors] -->|HTTPS| CF[Cloudflare] -->|Tunnel| D
{{< /mermaid >}}

## Stack

- **Content:** Markdown page bundles in `content/`
- **Build:** Hugo extended, pinned in the `Dockerfile`
- **Image:** `nginx-unprivileged` (non-root, port 8080)
- **Registry:** GitHub Container Registry
- **Deploy:** Docker Compose + a 5-minute cron pull
- **Public access:** Cloudflare Tunnel - no open ports at home

## Adding a page

In VS Code: **Run Task → New page**, write, **Run Task → Preview site**, then commit and **Sync Changes**.
