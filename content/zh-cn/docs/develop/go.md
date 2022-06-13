---
title: "Go"
date: 2022-06-13T17:13:19+08:00
---

## 开发环境

step1. 安装 Go

```shell
$ brew install go
go: stable 1.18 (bottled), HEAD
Open source programming language to build simple/reliable/efficient software
https://go.dev/

$ go version
go version go1.18 darwin/amd64
```

step2. 设置 Go env

```shell
# GOPATH, GOROOT, GOBIN, GO111MODULE, GOPROXY, GOPRIVATE
$ go env -w GO111MODULE=on
$ go env -w GOPROXY=https://goproxy.cn,direct
```

step3. 安装 VSCode 及 vscode-go 插件

```
Go: Install/Update Tools
```

https://marketplace.visualstudio.com/items?itemName=golang.Go

step4. 开始 Go 开发之旅

### Go 命令行

go mod

```
go mod tidy
```

升级依赖

```
go get -u github.com/spf13/cobra
go get -u github.com/spf13/pflag
```

```
go get
go install
go mod
```

## 项目开发

### 命令行工具

```shell
$ gh repo clone luohu1/cmdcli-go
```

## 交叉编译

Mac 下编译 Linux 和 Windows 64 位可执行程序

```shell
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o gitlab cmd/gitlab/main.go
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o appname.exe appname.go
```

Linux 下编译 Mac 和 Windows 64 位可执行程序

```shell
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build
```

```shell
export GITHUB_TOKEN="ghp_lRMj********************************"
~/go/bin/goreleaser release --rm-dist
~/go/bin/goreleaser release --snapshot --rm-dist
```

## Crontab

## 参考文档

- https://github.com/robfig/cron/
- https://pkg.go.dev/github.com/robfig/cron/v3
- https://github.com/golang-standards/project-layout
- https://juejin.cn/post/6855129007038726152#heading-0
- https://static.kancloud.cn/lhj0702/sockstack_gin/1805357
- https://goreleaser.com/quick-start/
- https://goreleaser.com/
