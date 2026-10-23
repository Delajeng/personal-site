---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
date: {{ .Date }}
draft: true               # set to false to publish
summary: "One line shown on the card: what it is and why it exists."
tags: []                  # tech used, e.g. ["proxmox", "docker", "ci-cd"]
weight: 50                # order in the Projects list (lower = higher up)
---

<!-- Optional: put feature.png or feature.jpg next to this file (a diagram or screenshot). -->

{{"{{<"}} alert icon="circle-info" {{">}}"}}
**Status:** Running · **Stack:** TODO · **Repo:** [github.com/Delajeng/TODO](https://github.com/Delajeng/TODO)
{{"{{<"}} /alert {{">}}"}}

## Goal

What problem this solves and what "done" looks like. Two or three sentences.

## Architecture

{{"{{<"}} mermaid {{">}}"}}
flowchart LR
  a["Source"] --> b["Build"]
  b --> c["Run"]
  c --> d["Users"]
{{"{{<"}} /mermaid {{">}}"}}

One paragraph walking through the diagram from left to right.

## Stack

| Layer | Tool | Why this one |
| ----- | ---- | ------------ |
| TODO  | TODO | TODO         |

## Key decisions

- **Decision:** what I chose, what I didn't, and why.

## What broke and what I learned

<!-- Delete this section if nothing broke. -->

- **Symptom:** what I saw. **Cause:** what it really was. **Fix:** what I changed.

## What's next

- Planned improvement.

## Code

{{"{{<"}} github repo="Delajeng/TODO" showThumbnail=false {{">}}"}}
