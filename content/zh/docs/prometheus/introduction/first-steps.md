---
title: "First Steps"
date: 2020-07-25T15:01:08+08:00
weight: 2
---

欢迎来到 Prometheus！Prometheus 是一个监控平台，它通过在这些目标上搜集指标 HTTP 端点来从被监视的目标收集指标数据。本指南将向您展示如何安装、配置和使用 Prometheus 监控我们的第一个资源。您将下载，安装并运行 Prometheus。您还将下载并安装 exporter，这些工具可在主机和服务上暴露时间序列数据。我们的第一个 exporter 将是 Prometheus 本身，它提供了关于内存使用，垃圾回收等各种主机级别的指标。

## 下载 Prometheus

为您的平台[下载最新版本](https://prometheus.io/download)的 Prometheus，然后解压缩它：

```bash
tar xvfz prometheus-*.tar.gz
cd prometheus-*
```

Prometheus server 是一个称为 `prometheus`（或 `prometheus.exe` 在 Microsoft Windows上）的二进制文件。我们可以运行二进制文件并通过传递 `--help` 标志来查看有关其选项的帮助。

```bash
./prometheus --help
usage: prometheus [<flags>]

The Prometheus monitoring server

. . .
```

在启动 Prometheus 之前，让我们对其进行配置。

## 配置 Prometheus

Prometheus 配置为 [YAML](http://www.yaml.org/start.html) 格式。 Prometheus 下载包附带了示例配置在一个名为 `prometheus.yml` 的文件中，这个文件是开始的好地方。

我们删除了示例文件中的大多数注释，以使其更加简洁（注释是带有 `#` 前缀的行）。

```yaml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

rule_files:
  # - "first.rules"
  # - "second.rules"

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
```

示例配置文件中包含三个配置块：`global`、`rule_files` 和 `scrape_configs`。

`global` 控制 Prometheus server 的全局配置。我们目前有两个选项。首先，`scrape_interval` 控制 Prometheus 多久搜集一次目标。您可以为单个目标覆盖此选项。在这个例子中，全局设置是每 15 秒搜集一次。`evaluation_interval` 选项控制 Prometheus 多久评估一次 rule。Prometheus 使用 rule 来创建新的时间序列并生成警报。

`rule_files` 块指定我们要 Prometheus server 加载的任何规则的位置。目前，我们还没有任何规则。

最后一块 `scrape_configs` 控制 Prometheus 监控哪些资源。由于 Prometheus 还将有关自身的数据公开为 HTTP 端点，因此它可以抓取并监视其自身的运行状况。在默认配置中，有一个名为 `prometheus` 的作业，它会抓取 Prometheus server 公开的时间序列数据。该作业包含了单个静态配置的目标：`'localhost:9090'`。Prometheus 希望指标在目标的 `/metrics` 路径上是可用的。因此，此默认作业是通过以下网址进行抓取：http://localhost:9090/metrics。

返回的时间序列数据将详细说明 Prometheus 服务器的状态和性能。

有关配置选项的完整说明，请参阅[配置文档](https://prometheus.io/docs/operating/configuration)。

## 启动 Prometheus

要使用我们新创建的配置文件启动 Prometheus，切换到包含 Prometheus 二进制文件的目录并运行：

```bash
./prometheus --config.file=prometheus.yml
```

Prometheus 将会启动。您还应该能够在 [http://localhost:9090](http://localhost:9090/) 上浏览到有关其自身的状态页。给它大约 30 秒的时间，以从其自己的 HTTP 指标端点收集有关自身的数据。

您还可以通过导航到它自己的指标端点：http://localhost:9090/metrics 来验证 Prometheus 是否正在提供有关其自身的指标。

## 使用表达式浏览器

让我们尝试查看 Prometheus 收集到的有关自身的一些数据。要使用 Prometheus 的内置表达式浏览器，请导航至 http://localhost:9090/graph 并在 "Graph" 选项卡中选择 "Console" 视图。

正如您可以从 http://localhost:9090/metrics 收集的那样，Prometheus 导出的有关其自身的一个指标称为 `promhttp_metric_handler_requests_total` （Prometheus server 已处理的 `/metrics` 请求总数）。继续并将以下内容输入到表达式控制台中：

```
promhttp_metric_handler_requests_total
```

这应该返回一些不同的时间序列（以及每个时间序列的最新值），所有时间序列的指标名称均为 `promhttp_metric_handler_requests_total`，但具有不同的标签。这些标签指定不同的请求状态。

如果我们只对返回 HTTP code 200 的请求感兴趣，则可以使用此查询来检索该信息：

```
promhttp_metric_handler_requests_total{code="200"}
```

要统计返回的时间序列数，您可以编写：

```
count(promhttp_metric_handler_requests_total)
```

有关表达语言的更多信息，请参见 [expression language documentation](https://prometheus.io/docs/querying/basics/)。

## 使用绘图界面

要绘制表达式的图形，请导航到 http://localhost:9090/graph 并使用 "Graph" 选项卡。

例如，输入以下表达式以绘制在自抓取的 Prometheus 中发生的每秒返回状态码 200 的 HTTP 请求速率

```
rate(promhttp_metric_handler_requests_total{code="200"}[1m])
```

您可以尝试使用图形 range 参数和其他设置。

## 监控其他目标

仅从 Prometheus 收集指标并不能很好地说明 Prometheus 的功能。为了更好地了解 Prometheus 可以做什么，我们建议您浏览有关其他 exporter 的文档。[Monitoring Linux or macOS host metrics using a node exporter](https://prometheus.io/docs/guides/node-exporter) 指南是一个不错的起点。

## 总结

在本指南中，您安装了 Prometheus，配置了 Prometheus 实例以监视资源，并了解了在 Prometheus 表达式浏览器中使用时间序列数据的一些基础知识。要继续学习 Prometheus，请查看 [Overview](https://prometheus.io/docs/introduction/overview) 以获取有关接下来要探索的内容的一些想法。