# Webman Dev Container Features

This repository is a standalone Dev Container Feature repo for `webman-net-tools`.

## Feature

- Source: `src/webman-net-tools`
- Published package name: `webman-net-tools`
- Example GHCR reference after release: `ghcr.io/<your-github-user-or-org>/webman-net-tools:1.0.0`

## What it installs

- PHP runtime
- Composer
- Webman starter project under `/opt/webman`
- Network tools: `curl`, `wget`, `ping`, `traceroute`, `dig`, `net-tools`, `iproute2`

## Publish

This repository is designed to publish from GitHub Actions.
Use the workflow in `.github/workflows/release.yml`.
