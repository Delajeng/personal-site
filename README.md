# personal-site

Source for my personal website: projects, resume and a blog.

Live at https://delajeng.dev

## How it works

    push to main -> GitHub Actions -> image on GHCR -> LXC pulls it -> Cloudflare Tunnel

The site is built with [Hugo](https://gohugo.io) and the
[Blowfish](https://blowfish.page) theme. Nothing is built locally: GitHub
Actions runs Hugo inside a Docker build and publishes an nginx image to GHCR.
A Docker LXC on my Proxmox host checks for a new image every five minutes and
restarts the container when there is one. Traffic comes in through a Cloudflare
Tunnel, so no ports are open at home.

## Layout

    content/       pages: projects, blog posts, resume
    hugo.toml      site config, menu, theme settings
    assets/img/    profile picture
    static/        favicons
    deploy/        docker-compose.yml, update.sh and .env example for the LXC
    themes/        Blowfish (vendored, not edited)
    Dockerfile     two-stage build: Hugo, then nginx-unprivileged on :8080

## Adding content

Each post is a folder with an `index.md` and an optional `feature.jpg`:

    content/blog/my-post/index.md

Set `draft: false` in the front matter, commit and push. To preview locally:

    hugo server -D

## Deployment

The LXC keeps three files in `/opt/personal-site`: the compose file,
`update.sh`, and a `.env` with `SITE_IMAGE` and `TUNNEL_TOKEN`. A cron job
runs `update.sh` every five minutes; its output goes to `journalctl -t site-update`.

To update Blowfish, replace `themes/blowfish` with a newer release and check
the build still passes.
