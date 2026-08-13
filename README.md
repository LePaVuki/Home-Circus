# Home Circus

Home-Circus is a Docker Compose-based home deployment for self-hosting local LLM UIs and companion services. The repository composes a set of services (reverse proxy, authentication, local LLM runtime, web UI, terminal UI, optional monitoring) so a single host can run a private LLM stack behind TLS and authentication.

This README documents the repository layout, prerequisites, installation and configuration steps, running and troubleshooting tips, and how to enable optional services.

Table of contents
- About
- Quick Start
- Services & Ports
- Configuration & Secrets
- Data and Persistence
- Enabling GPU (OLLAMA)
- Optional Monitoring (Prometheus / Grafana)
- Development & Building
- Troubleshooting
- Contributing
- License

## About

Home-Circus provides an opinionated compose-driven environment to run:
- A reverse proxy (Caddy) for TLS and routing
- An authentication gateway (Authelia) for protected services
- A local LLM runtime (Ollama) with GPU / CPU variants
- Web UIs (Open-WebUI, Open-Terminal) to interact with models
- Optional monitoring stack (Prometheus, Grafana, cAdvisor)

The goal is a private, reproducible, single-host setup for hobbyist/self-host LLM experiments with sensible defaults and automated secrets scaffolding.

## Quick Start (fast path)

Prerequisites
- Docker Engine and Docker Compose plugin (docker compose) installed on the host
- For GPU acceleration: NVIDIA drivers and the NVIDIA Container Toolkit (nvidia-container-toolkit)
- A shell (bash) to run the provided init script (WSL, Git Bash, or native Linux/macOS shell recommended on Windows)

1. Clone the repo
   git clone https://github.com/LePaVuki/Home-Circus.git
   cd Home-Circus

2. Copy and customize environment variables
   cp .env.example .env
   # Edit .env and set ROOT_DOMAIN, ADMIN_PASSWORD, ADMIN_EMAIL as appropriate

   Files:
   - [.env.example](H:/Programming/Projects/Home-Circus/.env.example)
   - [.env](/H:/Programming/Projects/Home-Circus/.env) (created during setup)

3. Run the helper script to create secrets, users and start containers
   ./init.sh

   The script will:
   - Check Docker and Docker Compose availability
   - Create a .env file if missing
   - Generate Authelia secrets (jwt_secret, session_secret, storage_encryption_key)
   - Create a default Authelia admin user (credentials come from .env)
   - Start the compose stack (docker compose up -d)

## Services & ports

Top-level compose manifest: [compose.yaml](H:/Programming/Projects/Home-Circus/compose.yaml)

Included service manifests live under services/ and are included by the top-level compose file. Key services and their default ports:
- caddy (reverse proxy / TLS)
  - Ports: 80, 443
  - Files: [services/caddy/compose.yaml](H:/Programming/Projects/Home-Circus/services/caddy/compose.yaml) and [services/caddy/Caddyfile](H:/Programming/Projects/Home-Circus/services/caddy/conf/Caddyfile)
- authelia (authentication)
  - Protects proxied endpoints, provides 2FA & session management
  - Files: [services/authelia/compose.yaml](H:/Programming/Projects/Home-Circus/services/authelia/compose.yaml)
- ollama (local LLM runtime)
  - Default port: 11434
  - Data stored at: data/.ollama
  - Files: [services/ollama-gpu/compose.yaml](H:/Programming/Projects/Home-Circus/services/ollama-gpu/compose.yaml)
- open-webui (LLM web UI)
  - Exposed on host port 3000 by default (maps to container 8080)
  - Files: [services/open-webui/compose.yaml](H:/Programming/Projects/Home-Circus/services/open-webui/compose.yaml)
- open-terminal (web terminal UI)
  - Default host port 4000 (maps to container 8000)
  - Files: [services/open-terminal/compose.yaml](H:/Programming/Projects/Home-Circus/services/open-terminal/compose.yaml)

Optional/disabled monitoring services (commented out in compose.yaml):
- prometheus, grafana, cAdvisor
  - Enable by uncommenting the include entries in [compose.yaml](H:/Programming/Projects/Home-Circus/compose.yaml) and starting the stack

## Configuration & Secrets

Environment variables
- [.env.example](H:/Programming/Projects/Home-Circus/.env.example) contains the minimum variables: ADMIN_USERNAME, ADMIN_PASSWORD, ADMIN_EMAIL, ROOT_DOMAIN
- Copy to .env and set appropriately. Do NOT commit .env to source control.

Secrets
- Authelia secrets are kept under services/authelia/secrets (jwt_secret, session_secret, storage_encryption_key). The provided init.sh will generate them if missing.
- data/ holds service data (databases, model files). Keep regular backups where appropriate.

Data and persistence
- Persistent volumes and bind mounts are used to keep data outside containers. Check each service compose file for specific volumes (e.g., data/.ollama, data/authelia, caddy-data, open-webui volumes).

## Enabling GPU (OLLAMA)

OLLAMA in this repo can be run with GPU support via the ollama-gpu service. Requirements and notes:
- Host must have NVIDIA drivers installed
- Install NVIDIA Container Toolkit (nvidia-docker) and ensure docker can start containers with --gpus or the device reservation used in the compose file
- When using Windows, prefer WSL2 with GPU passthrough (if available) or run on a Linux host
- If GPU is unavailable, use a CPU variant (there may be an ollama-cpu service or change the image used)

Optional Monitoring (Prometheus / Grafana)
- Prometheus and Grafana compose manifests exist under services/prom and services/grafana but are commented out by default in compose.yaml
- To enable: uncomment the include entries in [compose.yaml](H:/Programming/Projects/Home-Circus/compose.yaml) and start the stack. cAdvisor provides node/container metrics for Prometheus to scrape.

## Development & building

Build and run images locally (useful after modifying any Dockerfiles):
- docker compose build --parallel
- docker compose up -d

Rebuild a single service:
- docker compose build open-webui

View logs and health:
- docker compose logs -f
- docker compose ps
- docker compose exec <service> /bin/sh (or /bin/bash) to inspect containers

Updating or adding services
- Services are included modularly via the include list in compose.yaml. Add a new service by creating services/<name>/compose.yaml and adding it to the include list.

## Troubleshooting

Common issues and fixes
- "docker compose" command not found: install Docker Desktop or Docker Engine + Compose plugin
- Authelia or Caddy fails to get TLS: ensure ROOT_DOMAIN is set, DNS points at the host, and ports 80/443 are reachable
- Permissions when generating secrets: ensure init.sh runs under a user with write permissions to the repo folder, or run with sudo where appropriate (prefer not to run containers as root)
- Ollama healthcheck failing: check that data/.ollama is present and correct model files are installed; check container logs for errors
- GPU not visible: confirm nvidia-smi works on the host and NVIDIA Container Toolkit is installed

## Security notes
- Do not commit .env, secrets files, or data containing private keys / model files
- Rotate Authelia secrets if they are ever exposed
- Review Caddy and Authelia configuration before exposing services to the public internet

## Contributing
- Fork the repo and open a PR for non-trivial changes
- Keep changes modular: add services under services/ and reference them in compose.yaml
- Update this README and any service-level docs for any breaking or notable changes

## License
This repository does not currently include an explicit license file. If you want to make this project public, add a LICENSE (MIT recommended) and update this section.

## Acknowledgements & References
- Caddy — automatic TLS and reverse proxying
- Authelia — authentication gateway
- Ollama — local LLM runtime
- Open-WebUI / Open-Terminal — web interfaces

### Contact
- Maintainer: LePaVuki
- Repository: https://github.com/LePaVuki/Home-Circus