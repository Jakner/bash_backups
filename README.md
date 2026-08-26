# Multi-Cloud & On-Prem Backup Automation

A collection of Bash scripts that automate configuration and data backups across **Azure**, **Google Cloud**, **Oracle Cloud Infrastructure (OCI)**, and **on-prem network devices (FortiGate)** — plus a daily monitoring script that emails a report of what ran and what didn't.

Written for environments where infrastructure spans multiple providers and there's no single managed backup service that covers all of them.

## What's in here

| Script | Backs up | Method |
|---|---|---|
| `Azure_Firewall.sh` | Azure Firewall configuration | Azure CLI export → compressed archive |
| `azure_resources.sh` | Azure Application Gateway configuration | Azure CLI export → compressed archive |
| `oracle_resources.sh` | OCI networking (VCNs, subnets, route tables, peering gateways, DHCP options, security lists) | OCI CLI export → compressed archive |
| `BKP_FGT_FRW.sh` | FortiGate firewall configs (multiple devices) | REST API over HTTPS (bearer token), reads device list from CSV |
| `datacenter-dns1i.sh` | Arbitrary remote directories on datacenter servers | SSH + streaming `tar` compression |
| `envia_V2.sh` | — (monitoring, not backup) | Parses the daily backup log, flags undersized/failed backups, emails a summary report |
| `list-ip-Gcloud.sh`, `list-rules-Gcloud.sh`, `list-rules-Gcloud-multport.sh`, `ListRulesGcloudProjectedId.sh`, `ListRulesGcloudProjectedIdAlert.sh` | Google Cloud firewall rules / project IPs | `gcloud` CLI queries used for auditing and alerting on rule changes |

## Design decisions worth calling out

- **Streaming compression over SSH** (`datacenter-dns1i.sh`) — pipes `tar` output directly to local storage instead of staging on the remote host first, so it doesn't need extra disk space on servers it's backing up.
- **Retry + keepalive on SSH backups** — up to 2 retry attempts with delay, SSH timeout and keepalive settings, so a flaky network link doesn't silently produce a partial backup.
- **30-day retention** — old archives are deleted automatically after 30 days instead of growing storage forever.
- **Size-based failure detection** (`envia_V2.sh`) — a completed-but-empty or near-empty backup file is a common silent failure mode; this script specifically flags anything under 1KB rather than trusting "the job exited 0."
- **Everything logs to a shared log file**, and `envia_V2.sh` reads *that* log rather than re-deriving status — one source of truth for "did last night's backups actually work."

## Requirements

- Azure CLI (authenticated) for the Azure scripts
- `gcloud` CLI (authenticated) for the Google Cloud scripts
- OCI CLI (authenticated) for the Oracle Cloud scripts
- SSH key access to target hosts for `datacenter-dns1i.sh`
- A Fortinet API token per device for `BKP_FGT_FRW.sh` (read from a CSV — not committed)
- `mailx` (or equivalent) configured for `envia_V2.sh` to send its report

## Status

These are operational scripts, not a packaged tool — each one is standalone and assumes its own CLI/credentials are already configured in the environment it runs in (e.g. via cron). No secrets or environment-specific hostnames are committed; credentials are expected to be supplied via config files or environment variables at runtime.
