---
title: "This Site"
date: 2026-10-22
draft: false
summary: "How this site is built and deployed: Markdown in Git, a container image from GitHub Actions, a Proxmox LXC and a Cloudflare Tunnel."
tags: ["hugo", "docker", "github-actions", "proxmox", "cloudflare", "ci-cd"]
weight: 1
---

{{< alert icon="circle-info" >}}
**Status:** Running · **Stack:** Hugo, Blowfish, GitHub Actions, GHCR, Docker Compose, Proxmox LXC, Cloudflare Tunnel · **Repo:** [github.com/Delajeng/personal-site](https://github.com/Delajeng/personal-site)
{{< /alert >}}

## Goal

A personal site for projects, my resume and a blog, where publishing a page is just a Git push. It had to be simple, fully open source and self-hosted in my homelab, with nothing built or stored on my laptop except the Markdown and Git history.

## Architecture

{{< mermaid >}}
flowchart LR
  laptop["Laptop<br/>VS Code, Markdown"] -- "git push" --> gh["GitHub repo"]
  gh --> actions["GitHub Actions<br/>Hugo build + Docker image"]
  actions --> ghcr["GHCR<br/>personal-site:latest"]
  ghcr -- "cron pull every 5 min" --> lxc["Proxmox LXC<br/>Docker Compose"]
  lxc --- site["site<br/>nginx :8080"]
  lxc --- cf["cloudflared"]
  cf -- "outbound tunnel" --> edge["Cloudflare edge"]
  edge --> visitor["Visitor"]
{{< /mermaid >}}

I write and commit in VS Code. Every push to `main` triggers a GitHub Actions workflow that builds the site with Hugo inside a two-stage Docker build and publishes an nginx image to the GitHub Container Registry. On the LXC, a cron job checks every five minutes for a newer image and swaps it in. Visitors reach the `site` container through a Cloudflare Tunnel that dials out from the LXC, so no ports are open on my router or the container.

## Stack

| Layer | Tool | Why this one |
| ----- | ---- | ------------ |
| Content | Markdown + Hugo | Fast static builds, content stays as plain files in Git |
| Theme | Blowfish | Clean, documented, FOSS; projects, resume and blog fit without custom layouts |
| CI | GitHub Actions | Builds on every push; the laptop never needs Hugo or Docker |
| Registry | GHCR | Lives next to the repo; a public package needs no pull credentials |
| Runtime | Docker Compose in a Proxmox LXC | Two containers, lightweight, easy to rebuild |
| Updates | Cron + `update.sh` | Pulls the new image and recreates the container, nothing more |
| Ingress | Cloudflare Tunnel | Outbound-only, TLS at the edge, no port forwarding |

## Key decisions

- **Blowfish over Hextra.** I started with Hextra, but its docs-first layout didn't suit a mix of projects, a resume and a blog.
- **The image is built in CI, not on the server.** The LXC never checks out the repo or runs Hugo. It only pulls a finished image, so the server stays simple and replaceable.
- **A cron script instead of Watchtower.** One short script does the only job I need. It's one less container to run and trust.
- **Kubernetes and ArgoCD dropped for now.** A K3s and GitOps setup would work, but it's a lot of machinery for one static site. The container image keeps that move open for later.
- **Its own domain and a Cloudflare Tunnel, not my existing reverse proxy.** The site is public and separate from the rest of the homelab, and the tunnel means nothing at home is reachable from the internet.
- **The only secret lives on the LXC.** The Cloudflare tunnel token sits in a `chmod 600` `.env` file. The repo is public and holds nothing sensitive.

## What's next

- Move the site to a K3s cluster with GitOps when the homelab has one.
- Add a staging preview for pages before they go live.

## Code

{{< github repo="Delajeng/personal-site" >}}
