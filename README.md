# Webman Dev Container 功能

本仓库是一个独立的 Dev Container Feature 仓库，用于 `webman-net-tools`。

## 功能

- 源代码位置：`src/webman-net-tools`
- 发布包名称：`webman-net-tools`
- 发布后 GHCR 引用示例：`ghcr.io/<your-github-user-or-org>/<your-feature-repo>/webman-net-tools:1`

## 使用方法

将发布后的 feature 添加到你的 `devcontainer.json`：

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:1": {}
	}
}
```

你也可以指定完整版本标签：

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:1.0.0": {}
	}
}
```

你还可以使用滚动的 `latest` 标签：

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:latest": {}
	}
}
```

`latest` 是有效的，因为发布步骤也会推送 `latest` 标签。如果你希望自动获取最新发布版本，可以使用它。

对于稳定环境，建议使用 `:1` 或精确版本号如 `:1.0.0`，以避免未来发布后的意外变更。

## 自定义参数

该 feature 支持两个选项：

- `installWebman`：`true` 或 `false`，默认值为 `true`
- `webmanPath`：启动项目的目标目录，默认值为 `/opt/webman`

示例：

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

如果要完全跳过 Webman 模板：

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:latest": {
			"installWebman": false
		}
	}
}
```

`installWebman: false` 仅会在 feature 安装时跳过创建新的 Webman 模板。
它不会删除之前镜像构建或容器重建后遗留的已有 `/opt/webman` 目录。

如果你之前已将 Webman 安装到 `/opt/webman`，请手动删除该目录，或在验证新行为时无缓存重建 dev container。

## 安装内容

- PHP 运行时
- Composer
- `/opt/webman` 下的 Webman 启动项目
- 网络工具：`curl`、`wget`、`ping`、`traceroute`、`dig`、`net-tools`、`iproute2`

## 发布

本仓库设计为通过 GitHub Actions 发布。
使用 `.github/workflows/release.yml` 中的工作流进行发布。

## 可发现性

发布到 GHCR 的自定义 feature 通常通过 OCI 地址直接引用。它们可能不会因为存在于 GHCR 而出现在 feature 搜索界面中。

如果你希望其他人访问该 feature，请确保 GHCR 包的可见性设置为公开。