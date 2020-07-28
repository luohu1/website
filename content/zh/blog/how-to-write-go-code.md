---
title: "How to Write Go Code"
description: "如何编写 Go 代码"
date: 2020-07-28T16:58:24+08:00
author: LH
---

## 介绍

本文档演示了模块内部简单 Go 软件包的开发，并介绍了 [go 工具](https://golang.org/cmd/go/)，这是获取、构建和安装 Go 模块、软件包和命令的标准方法。

注意：本文档假定您使用的是 Go 1.13 或更高版本，并且未设置 `GO111MODULE` 环境变量。如果您正在寻找本文档的较早的 pre-modules 版本，它在[这里](https://golang.org/doc/gopath_code.html)存档。

## 代码组织

Go 程序被组织到 package 中。*package* 是同一目录中一起编译的源文件的集合。在一个源文件中定义的函数、类型、变量和常量对于同一 package 中的所有其他源文件可见。

一个存储库（repository）包含一个或多个模块（module）。*模块* 是一起发布的相关 Go 软件包的集合。Go 存储库通常仅包含一个模块，位于存储库的根目录。在那里名为 `go.mod` 的文件声明了*模块路径*：模块内所有软件包的导入路径前缀。该模块包含了在包含其 `go.mod` 文件的目录以及该目录的子目录中包含的软件包，直至包含另一个 `go.mod` 文件（如果有）的下一个子目录。

请注意，在构建代码之前，无需将代码发布到远程存储库。可以在本地定义模块，而不必属于存储库。但是，像您有一天要发布的代码一样组织代码是一种好习惯。

每个模块的路径不仅充当其软件包的导入路径前缀，而且还指示 go 命令应该在哪里下载它。例如，为了下载模块 `golang.org/x/tools`，go 命令将查询 `https://golang.org/x/tools` 所指示的存储库（[此处](https://golang.org/cmd/go/#hdr-Relative_import_paths)有更多说明）。

*导入路径* 是用于导入软件包的字符串。包的导入路径是其模块路径及其在模块中的子目录。例如，模块 `github.com/google/go-cmp` 包含了一个在目录 `cmp/` 中的包。该软件包的导入路径为 `github.com/google/go-cmp/cmp`。标准库中的软件包没有模块路径前缀。

## 您的第一个程序

要编译和运行一个简单的程序，首先选择一个模块路径（我们将使用 `example.com/user/hello`），然后创建一个 `go.mod` 文件声明该路径：

```shell
$ mkdir hello # 或者，如果它已经在版本控制中，则将其克隆。
$ cd hello
$ go mod init example.com/user/hello
go: creating new go.mod: module example.com/user/hello
$ cat go.mod
module example.com/user/hello

go 1.14
```

Go 源文件中的第一条语句必须是 `package name`。可执行命令必须始终使用 `package main`。

接下来，在该目录中创建一个名为 `hello.go` 的文件，其中包含以下Go 代码：

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, world.")
}
```

现在，您可以使用 `go` 工具构建并安装该程序：

```shell
$ go install example.com/user/hello
```

此命令构建 `hello` 命令，生成一个可执行二进制文件。然后，将该二进制文件安装为 `$HOME/go/bin/hello`（或在Windows下为 `%USERPROFILE%\go\bin\hello.exe`）。

安装目录由 `GOPATH` 和 `GOBIN` [环境变量](https://golang.org/cmd/go/#hdr-Environment_variables)控制。如果设置了 `GOBIN`，则二进制文件将安装到该目录。如果设置了 `GOPATH`，二进制文件将安装到 `GOPATH` 列表中第一个目录的 `bin` 子目录中。否则，二进制文件将安装到默认 `GOPATH` 的 `bin` 子目录（`$HOME/go` 或 `%USERPROFILE%\go`）。

您可以使用 `go env` 命令为以后的 `go` 命令便捷地设置环境变量的默认值：

```shell
$ go env -w GOBIN=/somewhere/else/bin
```

要取消设置先前由 `go env -w` 设置的变量，请使用 `go env -u`：

```shell
$ go env -u GOBIN
```

类似 `go install` 之类的命令适用于包含当前工作目录的模块的上下文。如果工作目录不在 `example.com/user/hello` 模块内，则 `go install` 可能会失败。

为了方便起见，`go` 命令接受相对于工作目录的路径，如果没有给出其他路径，则默认使用当前工作目录中的软件包。因此，在我们的工作目录中，以下命令都是等效的：

```shell
$ go install example.com/user/hello
$ go install .
$ go install
```

接下来，让我们运行该程序以确保其正常工作。为了更加方便，我们将安装目录添加到 `PATH` 中，以使运行二进制文件变得容易：

```shell
# Windows 用户应该参考 https://github.com/golang/go/wiki/SettingGOPATH
# 来设置 ％PATH％。
$ export PATH=$PATH:$(dirname $(go list -f '{{.Target}}' .))
$ hello
Hello, world.
```

如果您在使用源代码控制系统，那么现在正是初始化存储库，添加文件并提交第一个更改的好时机。同样，此步骤是可选的：您无需使用源代码控制来编写Go代码。

```shell
$ git init
Initialized empty Git repository in /home/user/hello/.git/
$ git add go.mod hello.go
$ git commit -m "initial commit"
[master (root-commit) 0b4507d] initial commit
 1 file changed, 7 insertion(+)
 create mode 100644 go.mod hello.go
```

`go` 命令通过请求相应的 HTTPS URL 并读取 HTML 响应中嵌入的元数据来查找包含给定模块路径的存储库（请参阅 `go help importpath`）。许多托管服务已经为包含 Go 代码的存储库提供了该元数据，因此使您的模块可供其他人使用的最简单方法通常是使其模块路径与存储库的URL相匹配。

### 从您的模块导入包

让我们编写一个 `morestrings` 包，并在 `hello` 程序中使用它。首先，为名为 `$HOME/hello/morestrings` 的包创建一个目录，然后在该目录中创建一个名为 `reverse.go` 的文件，其中包含以下内容：

```go
// 包 morestrings 实现了额外的功能来操纵 UTF-8
// 编码的字符串，超出标准 "strings" 包中提供的字符串。
package morestrings

// ReverseRunes 返回其参数字符串，从左向右以符文方向反转。
func ReverseRunes(s string) string {
	r := []rune(s)
	for i, j := 0, len(r)-1; i < len(r)/2; i, j = i+1, j-1 {
		r[i], r[j] = r[j], r[i]
	}
	return string(r)
}
```

因为我们的 `ReverseRunes` 函数以大写字母开头，所以它是 [exported](https://golang.org/ref/spec#Exported_identifiers)，并且可以在导入 `morestrings` 包的其他包中使用。

让我们测试一下使用 `go build` 编译该软件包：

```shell
$ cd $HOME/hello/morestrings
$ go build
```

这不会产生输出文件。而是将已编译的程序包保存在本地构建缓存中。

确认 `morestrings` 软件包已生成后，让我们从 `hello` 程序中使用它。为此，请修改原始的 `$HOME/hello/hello.go` 以使用 morestrings 包：

```go
package main

import (
	"fmt"

	"example.com/user/hello/morestrings"
)

func main() {
	fmt.Println(morestrings.ReverseRunes("!oG ,olleH"))
}
```

安装 `hello` 程序：

```shell
$ go install example.com/user/hello
```

运行新版本的程序，您应该看到一条新的反向的消息：

```shell
$ hello
Hello, Go!
```

### 从远程模块导入包

导入路径可以描述如何使用版本控制系统（例如 Git 或 Mercurial）获取软件包源代码。`go` 工具使用此属性来自动从远程存储库获取软件包。例如，要在您的程序中使用 `github.com/google/go-cmp/cmp`：

```go
package main

import (
	"fmt"

	"example.com/user/hello/morestrings"
	"github.com/google/go-cmp/cmp"
)

func main() {
	fmt.Println(morestrings.ReverseRunes("!oG ,olleH"))
	fmt.Println(cmp.Diff("Hello World", "Hello Go"))
}
```

当您运行诸如 `go install`、`go build` 或 `go run` 之类的命令时，`go` 命令将自动下载远程模块并将其版本记录在您的 `go.mod` 文件中：

```shell
$ go install example.com/user/hello
go: finding module for package github.com/google/go-cmp/cmp
go: downloading github.com/google/go-cmp v0.4.0
go: found github.com/google/go-cmp/cmp in github.com/google/go-cmp v0.4.0
$ hello
Hello, Go!
  string(
- 	"Hello World",
+ 	"Hello Go",
  )
$ cat go.mod
module example.com/user/hello

go 1.14

require github.com/google/go-cmp v0.4.0
```

模块依赖项将自动下载到 `GOPATH` 环境变量指示的目录的 `pkg/mod` 子目录中。这些给定版本的模块的下载内容在 `require` 该版本的所有其他模块之间共享，因此 `go` 命令将这些文件和目录标记为只读。要删除所有下载的模块，可以通过给 `go clean` 传递 `-modcache` 标志：

```shell
$ go clean -modcache
```

## 测试

Go 具有由 `go test` 命令和 `testing` 包组成的轻量级测试框架。

通过创建一个名称以 `_test.go` 结尾的文件来编写测试，该文件包含名为 `TestXXX` 且具有 `func (t *testing.T)` 签名的函数。测试框架运行每个这样的函数；如果该函数调用了诸如 `t.Error` 或 `t.Fail` 之类的失败函数，则认为测试已失败。

通过创建包含以下 Go 代码的文件 `$HOME/hello/morestrings/reverse_test.go`，将测试添加到 `morestrings` 包中。

```go
package morestrings

import "testing"

func TestReverseRunes(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"Hello, world", "dlrow ,olleH"},
		{"Hello, 世界", "界世 ,olleH"},
		{"", ""},
	}
	for _, c := range cases {
		got := ReverseRunes(c.in)
		if got != c.want {
			t.Errorf("ReverseRunes(%q) == %q, want %q", c.in, got, c.want)
		}
	}
}
```

然后使用 `go test` 运行测试：

```shell
$ go test
PASS
ok  	example.com/user/morestrings 0.165s
```

运行 `go help test` 和查看 [testing package documentation](https://golang.org/pkg/testing/) 以获取更多详细信息。

## 下一步

订阅 [golang-announce](https://groups.google.com/group/golang-announce) 邮件列表，以便在发布新的 Go 稳定版时收到通知。

有关编写清晰，惯用的 Go 代码的提示，请参见 [Effective Go](https://golang.org/doc/effective_go.html)。

参加 [A Tour of Go](https://tour.golang.org/) 以正确地学习 Go 语言。

请访问[文档页面](https://golang.org/doc/#articles)，获取有关 Go 语言及其库和工具的一系列深入文章。

## 获得帮助

要获得实时帮助，请在社区运行的 [gophers Slack server](https://gophers.slack.com/messages/general/) 中询问有用的 gopher（在[此处](https://invite.slack.golangbridge.org/)获取邀请）。

用于讨论 Go 语言的官方邮件列表是 [Go Nuts](https://groups.google.com/group/golang-nuts)。

使用 [Go 问题跟踪器](https://golang.org/issue)报告错误。