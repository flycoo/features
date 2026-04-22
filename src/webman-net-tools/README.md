# Webman + Network Tools Feature

This feature installs a PHP runtime, Composer, a Webman starter workspace under `/opt/webman`, and common network utilities such as `curl`, `wget`, `ping`, `traceroute`, `dig`, `iproute2`, and `net-tools`.

## Included commands

- `php`
- `composer`
- `curl`
- `wget`
- `ping`
- `traceroute`
- `dig`
- `ss`
- `netstat`
- `ifconfig`
- `webman-tools-check`

## Notes

The sample installation uses `composer create-project workerman/webman /opt/webman` so you can inspect a ready-to-run Webman skeleton inside the container. If you only want the runtime dependencies, remove that block from `install.sh`.
