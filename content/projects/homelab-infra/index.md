---
title: "Homelab infrastructure as code"
date: 2026-09-28
summary: "A 3-node K3s cluster on Proxmox, provisioned with Terraform and Ansible, deployed with ArgoCD."
tags: ["proxmox", "terraform", "ansible", "k3s", "argocd"]
weight: 10
---

{{< alert icon="circle-info" >}}
Example project page - swap in your own write-up and a `feature.png` (diagram or screenshot).
{{< /alert >}}

**Repo:** <https://github.com/YOUR-GITHUB-USER/homelab-infra>

## Problem

Clicking VMs together in the Proxmox UI isn't reproducible. I wanted the whole lab rebuildable from Git.

## What I built

- **Terraform** (`bpg/proxmox` provider) creates the VMs
- **Ansible** configures the OS and installs K3s (1 control plane, 2 workers)
- **ArgoCD** syncs workloads from Git
- **GitHub Actions** builds and publishes images

## What I learned

Write this part honestly - the things that broke are the most useful part for readers (and interviewers).
