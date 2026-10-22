# Personal site: setup from start to finish

## How it works

```
 LAPTOP (VS Code)          GITHUB                               PROXMOX LXC (Docker)              CLOUDFLARE
 edit Markdown   ──push──▶ repo  ──▶ Actions builds a     ◀──── cron pulls the new image          yourdomain.com
 nothing is built          Docker image of the site             every 5 min                            │
 here                      → ghcr.io/<you>/personal-site        ┌─────────────────────────┐            │
                                                                │ site        (the image) │◀── tunnel ─┘
                                                                │ cloudflared (tunnel)    │
                                                                └─────────────────────────┘
```

- **Laptop:** only edits files and pushes them. Nothing is built or stored there apart from the project files and Git's history.
- **GitHub:** stores the files. On every push, **GitHub Actions** turns them into a website and packs it into a Docker image (the site plus a small nginx web server). The image is stored in GitHub's container registry (GHCR).
- **LXC:** runs two containers: `site` (that image) and `cloudflared` (the Cloudflare Tunnel). A cron job checks every 5 minutes for a newer image and swaps it in.
- **Cloudflare:** sends visitors of your domain through the tunnel to the `site` container. You don't open any ports on your router or the LXC.

**You need:** a GitHub account, a Cloudflare account with your domain, and Proxmox.
**Placeholders below:** `<github-user>` is your GitHub username, `yourdomain.com` is your domain, and the repo is called `personal-site`.

---

## Step 1 — Prepare the laptop (once)

In VS Code open a terminal (**Terminal → New Terminal**) and check Git is installed:

```
git --version
```

If it isn't, run `winget install --id Git.Git -e`, then close and reopen VS Code.

Tell Git who you are. For the email, use your private GitHub address so your real email never appears in the public history. Find it on GitHub → **Settings → Emails**: it looks like `12345678+<github-user>@users.noreply.github.com`.

```
git config --global user.name "George"
git config --global user.email "12345678+<github-user>@users.noreply.github.com"
```

Open the project: **File → Open Folder… → `C:\personal-site`** and click **Yes, I trust the authors**.

## Step 2 — Personalise

1. **`hugo.toml`**: change every line marked `TODO`: site title, your GitHub username, your LinkedIn, and `editURL` (use `https://github.com/<github-user>/personal-site/edit/main/content/`). Leave `baseURL` alone; step 4 sets it.
2. **`content\resume.md`**: fill in the `TODO`s.
3. **Photo (optional):** put a square photo in `assets\img\` as `avatar.jpg`, then change `image = "img/avatar.jpg"` in `hugo.toml`.

You can also do this later. Every change you push goes live automatically.

## Step 3 — Put the project on GitHub

**You don't create the repo on github.com first.** VS Code creates it and uploads everything in one go.

1. Click the **Source Control** icon in the left bar (or `Ctrl+Shift+G`).
2. Click **Publish to GitHub**. If VS Code asks to sign in to GitHub, allow it; a browser window opens, you approve, and you come back.
3. Choose **Publish to GitHub public repository** and name it `personal-site`.
4. If it shows a list of files to include, leave them all ticked and press **OK**.

VS Code makes the first commit and pushes it. Open `https://github.com/<github-user>/personal-site` in your browser and you'll see the files.

The push also starts the pipeline. Open the repo's **Actions** tab, where **Build and publish site** is running. Wait for the green ✓ (about 2–3 minutes).

> The repo must be **public**: the LXC downloads the deployment files from it in step 6. Nothing secret is in it; the Cloudflare token only ever lives on the LXC.

## Step 4 — Two settings on GitHub

**4.1 Make the image downloadable without a password.**
On GitHub click your profile picture → **Your profile** → **Packages** tab → **personal-site** → **Package settings** (right side) → at the bottom, **Change visibility** → **Public** → confirm.

**4.2 Tell the pipeline your domain.**
Repo → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**:

- Name: `SITE_URL`
- Value: `https://yourdomain.com/` (keep the trailing `/`)

**4.3 Rebuild with that setting.**
Repo → **Actions** → **Build and publish site** (left) → **Run workflow** → **Run workflow**. Wait for the green ✓.

Your image now exists as **`ghcr.io/<github-user>/personal-site:latest`**. Write it down in **lowercase**, even if your username has capitals.

## Step 5 — Create the Cloudflare Tunnel

1. Go to [dash.cloudflare.com](https://dash.cloudflare.com) → **Zero Trust** in the left menu. The first time, it asks for a team name and a plan; pick **Free**.
2. **Networks → Tunnels** → **Create a tunnel** → **Cloudflared**. Some accounts show this as **Networks → Connectors → Cloudflare Tunnels**.
3. Name it `personal-site` → **Save tunnel**.
4. The next screen shows install commands. Click **Docker** and copy the command. You only need the long text after `--token`. Keep it in Notepad for step 6; **don't run the command**.
5. **Next** → add a **public hostname** (newer dashboards call it a **published application route**):
   - Subdomain: leave empty for `yourdomain.com`, or type `www`
   - Domain: `yourdomain.com`
   - Service type: **HTTP**
   - URL: **`site:8080`**
6. **Save**. Cloudflare creates the DNS record itself. If it complains that a record already exists, delete that record under **DNS → Records** for your domain, then save again.

Optional: Cloudflare dashboard → your domain → **SSL/TLS → Edge Certificates** → **Always Use HTTPS: On**.

## Step 6 — The LXC

**What the LXC needs:**

| Requirement | Why / how to check |
| ----------- | ------------------ |
| Docker Engine + Docker Compose plugin | `docker compose version` prints a version |
| If it's an unprivileged LXC: **Options → Features → nesting=1, keyctl=1** | Docker needs these inside an LXC |
| Outbound internet | Pulls the image from `ghcr.io` and connects to Cloudflare |
| `curl` and `cron` | `apt install -y curl cron` |
| Size | 1 CPU, 512 MB–1 GB RAM and 4–8 GB disk is plenty |

**What it doesn't need:** open ports, port forwarding, a static IP, a reverse proxy or a Git checkout.

Open the LXC console (Proxmox → the LXC → **Console**) or SSH in as root, then run this. Change `REPO=` to your username first:

```bash
REPO=<github-user>/personal-site

mkdir -p /opt/personal-site && cd /opt/personal-site
curl -fsSLO https://raw.githubusercontent.com/$REPO/main/deploy/docker-compose.yml
curl -fsSLO https://raw.githubusercontent.com/$REPO/main/deploy/update.sh
curl -fsSL  https://raw.githubusercontent.com/$REPO/main/deploy/.env.example -o .env
chmod +x update.sh
nano .env
```

In `nano` set the two values, then save with `Ctrl+O`, `Enter` and exit with `Ctrl+X`:

```
SITE_IMAGE=ghcr.io/<github-user-in-lowercase>/personal-site:latest
TUNNEL_TOKEN=<the token from step 5.4>
```

Start it:

```bash
chmod 600 .env
docker compose up -d
docker compose ps
docker compose logs cloudflared | tail -5
```

`docker compose ps` should list `site` and `cloudflared` as running. The cloudflared log should show `Registered tunnel connection`. In Cloudflare the tunnel turns **Healthy**.

**Open `https://yourdomain.com`. Your site is live.**

## Step 7 — Automatic updates on the LXC

```bash
(crontab -l 2>/dev/null; echo '*/5 * * * * /opt/personal-site/update.sh 2>&1 | logger -t site-update') | crontab -
crontab -l
```

From now on the LXC checks GitHub every 5 minutes and switches to a newer image when there is one.

## Step 8 — Test the whole loop

1. In VS Code open `content\blog\hello-world\index.md` and change a sentence.
2. **Source Control**: type a message (e.g. `test update`) → **Commit** → **Sync Changes**.
3. GitHub → **Actions**: wait for the green ✓ (about 2 minutes).
4. On the LXC, after up to 5 minutes, `journalctl -t site-update` shows `site updated`.
5. Reload your site with `Ctrl+F5`. The change is there.

---

## Everyday use

1. Edit or add a page in `content\`.
2. **Source Control** → message → **Commit** → **Sync Changes**.
3. Live within about 5–7 minutes.

**Adding a page:** each page is a folder with an `index.md` inside. The easiest way is to copy an existing folder, e.g. `content\blog\hello-world` → `content\blog\my-new-post`, and edit the top part:

```yaml
title: "My new post"
date: 2026-10-20
draft: false              # true = not published
summary: "One line shown on the card."
tags: ["cooking"]
weight: 10                # docs/projects only: order in the list
```

Put a `feature.jpg` in the folder to get a card image. Delete the copied `feature.png` if you don't want one.
Extras you can use in a page: `{{< alert >}}…{{< /alert >}}`, `{{< youtube VIDEO_ID >}}`, `{{< mermaid >}}…{{< /mermaid >}}`. More in the [Blowfish shortcodes](https://blowfish.page/docs/shortcodes/) docs.

**Optional, preview before publishing:** install Hugo (`winget install --id Hugo.Hugo.Extended -e`, v0.162 or newer) and press **`Ctrl+Shift+B`**. It opens the site at `http://localhost:1313`, renders in memory and writes nothing into the project folder. The **New page** task (`Ctrl+Shift+P` → *Tasks: Run Task*) also needs Hugo. Without Hugo, just copy a folder as above.

## What's in the folder

| Path | What it is |
| ---- | ---------- |
| `content\` | Your pages: `docs\`, `projects\`, `blog\`, `resume.md`, `_index.md` (homepage text) |
| `hugo.toml` | All settings |
| `assets\img\` | Your photo |
| `deploy\` | The 3 files the LXC downloads in step 6 |
| `Dockerfile`, `nginx.conf`, `.github\` | How GitHub builds the image. No need to touch |
| `archetypes\`, `.vscode\` | Page templates and VS Code tasks |
| `themes\` | The Blowfish theme (hidden in VS Code). Don't edit |

## If something's wrong

| Problem | Fix |
| ------- | --- |
| No **Publish to GitHub** button | The folder is already a Git repo. Use **⋯ → Remote → Add Remote**, or sign in via the account icon (bottom left) |
| Commit fails: "Please tell me who you are" | Do the `git config` lines in step 1 |
| Red ❌ in Actions | Click the run and read the red line. Usually a typo in a page's top block (`---` … `---`) |
| `docker compose pull` → `denied` | Package not public (step 4.1), or `SITE_IMAGE` has capitals |
| `curl` → 404 on the LXC | Repo is private or `REPO=` is wrong |
| Cloudflare error **1033** | Tunnel not connected: `docker compose logs cloudflared`. Usually a mis-pasted token |
| Cloudflare **502** | Route URL must be `site:8080` with type HTTP |
| Site links point to `localhost` | `SITE_URL` missing (step 4.2), then re-run the workflow |
| Pushed but site not updated | Check Actions is green, then `journalctl -t site-update` and `crontab -l` on the LXC |
| A page is missing | It still has `draft: true`, or its `date` is in the future |
