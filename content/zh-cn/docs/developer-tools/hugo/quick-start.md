---
title: "Quick Start"
date: 2022-06-13T16:50:51+08:00
---

## Quick Start

### 开发环境

- Hugo v0.99.1+extended
- Node.js v14.19.1 with npm 6.14.16
- themes/docsy dependencies/v0.2.0

### 安装 Hugo

```shell
$ brew install hugo
$ hugo version
hugo v0.99.1+extended darwin/amd64 BuildDate=unknown
```

### 开始写作

```shell
$ git clone https://github.com/luohu1/website.git
$ cd website
$ git submodule update --init --recursive
$ npm install
$ hugo new docs/developer-tools/hugo/_index.md
$ hugo server
```

visit [http://127.0.0.1:1313](http://127.0.0.1:1313)
