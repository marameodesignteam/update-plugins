# update-facetwp

Deploys a local FacetWP plugin build to one or more remote Cloudways servers via rsync over SSH.

## Directory structure

```
update-facetwp/
├── facetwp/            # plugin source files that get deployed
├── deploy-facetwp.sh   # deploy script
├── ssh_key.txt         # SSH private key (never commit this)
├── .env                # local config (never commit this)
└── .env.example        # template — commit this
```

## Setup

### 1. SSH key

`ssh_key.txt` must contain the private key for the Cloudways server. It is already present in this directory. Permissions should be restricted:

```bash
chmod 600 ssh_key.txt
```

### 2. Configure `.env`

Copy `.env.example` to `.env` and set `SYNC_FROM` to the local FacetWP plugin directory you want to pull from before deploying. Leave it unset to skip this step and deploy whatever is already in `./facetwp/`.

```bash
cp .env.example .env
```

```dotenv
# .env
SYNC_FROM=/Volumes/na2024/Passion/rda-nowicket/wp-content/plugins/facetwp
```

### 3. Add/update targets

Open `deploy-facetwp.sh` and edit the `TARGETS` array near the top. Each entry follows the format:

```
"label|ssh-user|host|port|remote-path"
```

Example:

```bash
TARGETS=(
  "rda-dev|master_bhxfntusar|139.59.151.100|22|/home/master/applications/dev/public_html/wp-content/plugins/facetwp/"
  "rda-prod|master_bhxfntusar|139.59.151.100|22|/home/master/applications/prod/public_html/wp-content/plugins/facetwp/"
)
```

The SSH user and host for a Cloudways server can be found in the Cloudways panel under **Servers → Master Credentials**.

## Usage

```bash
./deploy-facetwp.sh <target>        # deploy to a single target
./deploy-facetwp.sh <t1> <t2>       # deploy to multiple targets
./deploy-facetwp.sh all             # deploy to all targets
./deploy-facetwp.sh                 # print usage and available targets
```

## Deploy flow

1. **Local sync** (if `SYNC_FROM` is set in `.env`) — rsyncs the source plugin directory into `./facetwp/`
2. **Remote deploy** — rsyncs `./facetwp/` to each selected target over SSH

The `--delete` flag is used in both steps, so files removed from the source will be removed at the destination.
