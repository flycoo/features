# Dev Container Features

本仓库是一个独立的 Dev Container Feature 仓库，包含以下功能。

## 功能列表

| Feature | 位置 | 描述 |
|---------|------|------|
| `webman-net-tools` | `src/webman-net-tools` | 安装 PHP 运行时、Composer、Webman 骨架和常用网络工具 |
| `opencode` | `src/opencode` | 安装 OpenCode CLI - AI 驱动的开发工具 |
| `claude-code` | `src/claude-code` | 安装 Claude Code CLI - Anthropic 的 AI 编码助手 |

---

## opencode

安装 OpenCode CLI 工具，用于软件工程任务。

### 使用方法

```json
{
	"features": {
		"ghcr.io/flycoo/features/opencode:1": {}
	}
}
```

### 自定义参数

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `version` | string | `latest` | 要安装的 OpenCode 版本 (如 `latest`、`1.0.180`) |

```json
{
	"features": {
		"ghcr.io/flycoo/features/opencode:latest": {
			"version": "1.0.180"
		}
	}
}
```

### 安装内容

- OpenCode 二进制文件安装到 `/usr/local/bin/opencode`
- 依赖：`curl`、`tar`、`ca-certificates`

---

## claude-code

安装 Claude Code CLI 工具，Anthropic 官方的 AI 编码助手。

### 使用方法

```json
{
    "features": {
        "ghcr.io/flycoo/features/claude-code:1": {}
    }
}
```

### 自定义参数

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `version` | string | `latest` | 要安装的 Claude Code 版本 (如 `latest`、`1.0.0`) |
| `claude-base` | string | (必填) | Claude Code 持久化数据目录 |

```json
{
    "features": {
        "ghcr.io/flycoo/features/claude-code:latest": {
            "version": "latest",
            "claude-base": "/usr/local/share/claude-code-data"
        }
    }
}
```

### 安装内容

- Claude Code CLI 通过 npm 全局安装
- 依赖：`curl`、`ca-certificates`、`node`（需要 `ghcr.io/devcontainers/features/node`）
- 持久化目录：`claude-base` 下的 config、projects、memory

---

## webman-net-tools

### 使用方法

```json
{
	"features": {
		"ghcr.io/flycoo/features/webman-net-tools:1": {}
	}
}
```

### 自定义参数

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `installWebman` | boolean | `true` | 是否安装 Webman 启动项目到目标路径 |
| `webmanPath` | string | `/opt/webman` | Webman 启动项目的目标目录 |

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

### 安装内容

- PHP 运行时
- Composer
- `/opt/webman` 下的 Webman 启动项目
- 网络工具：`curl`、`wget`、`ping`、`traceroute`、`dig`、`net-tools`、`iproute2`

---

## 发布

本仓库设计为通过 GitHub Actions 发布。
使用 `.github/workflows/release.yml` 中的工作流进行发布。

`latest` 标签在每次发布时都会推送。对于稳定环境，建议使用 `:1` 或精确版本号。

## 可发现性

发布到 GHCR 的自定义 feature 通常通过 OCI 地址直接引用。请确保 GHCR 包的可见性设置为公开。