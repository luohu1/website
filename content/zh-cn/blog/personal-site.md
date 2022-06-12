---
title: "基于 Hugo + GitHub Pages 快速搭建个人网站"
date: 2020-07-15T21:49:38+08:00
author: LH
---



## 文章概述

本章介绍了如何使用 Hugo 管理个人站点内容，并部署在 GitHub Pages 上以供浏览。

- GitHub 上创建 website 仓库用于存储站点相关的内容。

- 使用 Hugo 组织、管理并生成站点

- 在 GitHub Pages 托管个人站点

## 准备 website 仓库

1. 登录 [GitHub](https://github.com)
2. 创建 website 仓库
   - 仓库名称：website
   - 描述（可选）：对该存储库的简单描述
   - 公开的 或 私人的：选择该存储库的可见性及谁可以提交更改等。
   - 初始化存储库 README 文件（可选）
   - 选择 .gitignore 和 license
3. 使用 GitHub Desktop 客户端将存储库 clone 到本地

## 使用 Hugo 管理站点内容

### 步骤 1：安装 Hugo

```shell
$ brew install hugo
```

验证安装

```shell
$ hugo version
Hugo Static Site Generator v0.74.1/extended darwin/amd64 BuildDate: unknown
```

### 步骤 2：初始化站点

```shell
$ cd website
$ hugo new site --force .
$ tree -L 1 .
.
├── archetypes
├── config.toml
├── content
├── data
├── layouts
├── static
└── themes
```

> 关于目录结构的更多信息，请参考[目录结构说明](https://gohugo.io/getting-started/directory-structure/#directory-structure-explained)

### 步骤 3：为站点添加主题

[themes.gohugo.io](https://themes.gohugo.io/) 提供了可选的主题列表，本示例中使用了 [Ananke theme](https://themes.gohugo.io/gohugo-theme-ananke/)

```shell
$ git submodule add https://github.com/budparr/gohugo-theme-ananke.git themes/ananke
$ echo 'theme = "ananke"' >> config.toml
```

### 步骤 4：为站点添加内容

使用 `hugo new [path]` 命令为站点添加内容，该命令以 `content` 作为根目录创建指定的文件，并将 `archetypes/default.md` 作为内容模板。

```shell
$ hugo new blog/my-first-post.md
$ cat content/blog/my-first-post.md
---
title: "My First Post"
date: 2020-07-15T21:47:19+08:00
draft: true
---
```

> 提示：关于如何管理内容，请参考[内容管理](https://gohugo.io/content-management/)；关于如何修改内容根目录，请参考 [Configuration Settings - contentDir](https://gohugo.io/getting-started/configuration/#all-configuration-settings)；阅读 [archetypes](https://gohugo.io/content-management/archetypes/) 了解更多相关信息。

### 可选：使用 Hugo server 预览站点

启动 Hugo server 

```shell
$ hugo server -D
```

访问 **http://localhost:1313/** 预览站点

## 构建并托管到 GitHub Pages

示例中使用 GitHub \<username\>.github.io master 分支作为托管存储库

### 步骤 1：修改站点配置文件

编辑 `config.toml` 文件，替换如下内容：

```toml
baseURL = "https://<username>.github.io"
title = "Website"
theme = ["ananke"]
```

### 步骤 2：构建静态文件

```shell
$ hugo --gc
```

上述命令将在 `public` 目录下生成站点文件。

### 步骤 3：发布到 GitHub 

```shell
$ cd public

$ git init
$ git add -A
$ git commit -m "@website"

# 替换 <username> 为你实际的 GitHub 用户名
$ git push -f https://github.com/<username>/<username>.github.io.git master
```

### 可选：使用自定义域名

1. 替换 `config.toml` 中的 `baseURL` 为实际的自定义域名
2. 创建 `static/CNAME` 文件，其内容为实际的自定义域名
3. 重新构建发布站点

## 参考链接

- https://gohugo.io/getting-started/quick-start/
- https://gohugo.io/hosting-and-deployment/







