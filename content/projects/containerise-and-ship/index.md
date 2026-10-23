---
title: "Containerise and Ship a Web App"
date: 2026-07-02
draft: false               # set to false to publish
summary: "A small Flask app packaged as a hardened multi-stage Docker image, built, smoke-tested and then pushed to Docker Hub by GitHub Actions."
tags: ["docker", "github-actions", "python", "flask", "ci-cd"]
weight: 10
---

{{< alert icon="circle-info" >}}
**Status:** Done · **Stack:** Python, Flask, Gunicorn, Docker, GitHub Actions, Docker Hub · **Repo:** [github.com/Delajeng/devops-project-01](https://github.com/Delajeng/devops-project-01)
{{< /alert >}}

## Goal

The first project in my cloud DevOps series: take a simple web app from code to a container image that anyone can pull and run, with no manual build steps. Done means every push to `main` produces a tested, tagged image in a registry, and nothing untested ever gets there.

## Architecture

{{< mermaid >}}
flowchart LR
  dev["Laptop<br/>git push"] --> repo["GitHub repo"]
  repo --> build["GitHub Actions<br/>build + load image"]
  build --> test["Smoke test<br/>GET /health"]
  test -- "main only" --> hub["Docker Hub<br/>:latest + :commit-sha"]
  hub --> anywhere["Pull and run anywhere<br/>VM, Kubernetes, laptop"]
{{< /mermaid >}}

Every push and pull request starts a GitHub Actions workflow on a hosted runner. It builds the image with Docker Buildx, using the GitHub Actions cache, and loads it into the runner's Docker. The workflow then starts the container and calls `/health`. The test passes only if the app answers `ok` and reports the commit SHA it was built from. On `main`, the tested image is pushed to Docker Hub as `latest` and as the commit SHA. Pull requests stop after the test and never log in to the registry.

## Stack

| Layer | Tool | Why this one |
| ----- | ---- | ------------ |
| App | Python + Flask | Small enough to keep the focus on packaging, with a `/health` endpoint to test against |
| App server | Gunicorn (2 workers) | Production WSGI server instead of Flask's development server |
| Image | Multi-stage Dockerfile on `python:3.12-slim` | Build dependencies stay in the first stage; the final image is smaller |
| CI | GitHub Actions | Free hosted runners, triggered straight from the repo |
| Build | Docker Buildx + GHA cache | Reuses layers between runs, so the push step doesn't rebuild anything |
| Registry | Docker Hub | Public image anyone can pull; credentials kept in GitHub secrets |

## Key decisions

- **Multi-stage build.** Dependencies are installed into `/install` in a builder stage and only that folder is copied into the final image, so pip's build leftovers never ship.
- **Runs as a non-root user.** The container runs as `appuser`, not root, which limits the damage if the app is ever compromised.
- **Gunicorn, not `flask run`.** The Flask dev server isn't meant for production; Gunicorn is the standard choice.
- **Test, then push.** The image is built and loaded into the runner first, tested, and only then pushed. A broken image fails the run before it reaches Docker Hub.
- **The version is baked into the image.** CI passes the commit SHA as `APP_VERSION`, and `/health` reports it, so it's always clear which commit is running. Local builds report `dev`.
- **Two tags per build.** `latest` for convenience, the commit SHA so any image can be traced back to the exact code and rolled back to.
- **Push only from `main`.** Pull requests build and test the image but never log in to Docker Hub, so branches can't overwrite `latest`.
- **Secrets in GitHub, not the repo.** The Docker Hub username and access token live in repository secrets.

## What I learned

- Writing a Dockerfile from scratch and what each instruction does
- Building, tagging and pushing images to a registry
- Why multi-stage builds give smaller, safer images
- GitHub Actions basics: triggers, jobs, steps and secrets
- Docker Hub compared with GitHub Container Registry
- Pipeline order matters. My first version pushed the image and tested it afterwards, and on pull requests the smoke test had no image to run because Buildx doesn't load images into Docker by default. Splitting the build, test and push steps fixed both.

## Code

{{< github repo="Delajeng/devops-project-01" showThumbnail=false >}}
