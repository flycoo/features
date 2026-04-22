# Webman Dev Container Features

This repository is a standalone Dev Container Feature repo for `webman-net-tools`.

## Feature

- Source: `src/webman-net-tools`
- Published package name: `webman-net-tools`
- Example GHCR reference after release: `ghcr.io/<your-github-user-or-org>/<your-feature-repo>/webman-net-tools:1`

## Usage

Add the published feature to your `devcontainer.json`:

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:1": {}
	}
}
```

You can also pin the full version tag:

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:1.0.0": {}
	}
}
```

You can also use the rolling `latest` tag:

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:latest": {}
	}
}
```

`latest` is valid because the publish step also pushes a `latest` tag. Use it when you want the newest released version automatically.

For stable environments, prefer `:1` or an exact version like `:1.0.0` to avoid unexpected changes after future releases.

## Custom Parameters

This feature supports two options:

- `installWebman`: `true` or `false`, defaults to `true`
- `webmanPath`: target directory for the starter project, defaults to `/opt/webman`

Example:

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:latest": {
			"installWebman": true,
			"webmanPath": "/workspaces/webman"
		}
	}
}
```

To skip the Webman skeleton entirely:

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:latest": {
			"installWebman": false
		}
	}
}
```

## What it installs

- PHP runtime
- Composer
- Webman starter project under `/opt/webman`
- Network tools: `curl`, `wget`, `ping`, `traceroute`, `dig`, `net-tools`, `iproute2`

## Publish

This repository is designed to publish from GitHub Actions.
Use the workflow in `.github/workflows/release.yml`.

## Discoverability

Custom features published to GHCR are usually referenced directly by OCI address. They may not appear in feature search UIs just because they exist in GHCR.

If you want others to access the feature, make sure the GHCR package visibility is set to public.
