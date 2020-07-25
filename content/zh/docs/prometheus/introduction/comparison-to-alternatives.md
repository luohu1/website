---
title: "Comparison to Alternatives"
date: 2020-07-25T16:26:46+08:00
weight: 3
---

## Prometheus vs. Graphite

### Scope

[Graphite](https://graphite.readthedocs.org/en/latest/) 专注于成为具有查询语言和图形功能的被动时间序列数据库。 其他任何问题都可以通过外部组件解决。

Prometheus 是一个完整的监视和趋势分析系统，包括基于时间序列数据的内置和主动抓取、存储、查询、图形化和警报。它了解世界应该是什么样子（应该存在哪些端点，什么时间序列模式意味着麻烦等），并积极尝试查找错误。

### Data model

Graphite 存储命名时间序列的数值样本，就像 Prometheus 一样。但是，Prometheus 的元数据模型更加丰富：Graphite 指标名称由点分隔的成分组成，这些成分隐式地对维度进行编码，Prometheus 将维度明确编码为键值对（称为标签），并附加到度量标准名称。这允许查询语言通过这些标签轻松进行过滤，分组和匹配。

此外，尤其是当 Graphite 与 [StatsD](https://github.com/etsy/statsd/) 结合使用时，它通常只存储在所有受监视实例上的聚合数据，而不是将实例保留为一个维度并能够向下钻取到有问题的实例。

例如，在  Graphite/StatsD 中存储对 API server 发起的 `POST` 方法到 `/tracks` 端点且响应码是 500  的 HTTP 请求数通常会这样编码：

```
stats.api-server.tracks.post.500 -> 93
```

在 Prometheus 中，相同的数据将会像这样编码（假设三个 api-server 实例）：

```
api_server_http_requests_total{method="POST",handler="/tracks",status="500",instance="<sample1>"} -> 34
api_server_http_requests_total{method="POST",handler="/tracks",status="500",instance="<sample2>"} -> 28
api_server_http_requests_total{method="POST",handler="/tracks",status="500",instance="<sample3>"} -> 31
```

### Storage

Graphite 将时间序列数据以 [Whisper](https://graphite.readthedocs.org/en/latest/whisper.html) 格式存储在本地磁盘上，

Graphite 以 [Whisper](https://graphite.readthedocs.org/en/latest/whisper.html) 格式将时间序列数据存储在本地磁盘上，这是一种 RRD 风格的数据库，它希望样本以固定的时间间隔到达。每个时间序列都存储在一个单独的文件中，新样本在一定时间后会覆盖旧样本。

Prometheus 同样为每个时间序列创建一个本地文件，但允许在出现抓取或规则评估时以任意间隔存储样本。由于新样本只是简单地附加，因此旧数据可以任意保留。Prometheus 也适用于许多短暂的，经常变化的时间序列集。

### Summary

Prometheus 除了更易于运行和集成到您的环境之外，还提供了更丰富的数据模型和查询语言。如果您想要一个可以长期保存历史数据的群集解决方案，那么 Graphite 可能是一个更好的选择。

## Prometheus vs. InfluxDB

[InfluxDB](https://influxdata.com/) 是一个开源时间序列数据库，具有用于扩展和集群化的商业选项。Prometheus 开发开始将近一年后，InfluxDB 项目才发布，因此我们当时无法将其视为替代方案。尽管如此，Prometheus 和 InfluxDB 之间仍然存在重大差异，并且两种系统都针对稍有不同的用例。

### Scope

为了进行公平的比较，我们还必须将 [Kapacitor](https://github.com/influxdata/kapacitor) 与 InfluxDB 一起考虑，因为它们结合起来可以解决与 Prometheus 和 Alertmanager 相同的问题空间。

与 [Graphite](https://prometheus.io/docs/introduction/comparison/#prometheus-vs-graphite) 相同的范围差异在这里适用于 InfluxDB 本身。另外，InfluxDB 提供了连续查询，这些查询等同于 Prometheus 记录规则。

Kapacitor 的范围是 Prometheus 记录规则，警报规则和 Alertmanager 的通知功能的组合。Prometheus 提供了[更强大的查询语言来进行图形显示和警报](https://www.robustperception.io/translating-between-monitoring-languages/)。 Prometheus Alertmanager 还提供分组，重复数据删除和静音功能。

### Data model / storage

与 Prometheus 一样，InfluxDB 数据模型也使用键值对作为标签，称为 tags。此外，InfluxDB 还有第二级标签，称为字段，使用范围受到更多限制。InfluxDB 支持最高达纳秒级的时间戳，以及 float64，int64，bool 和字符串数据类型。相比之下，Prometheus 支持 float64 数据类型，有限的字符串支持和毫秒级的时间戳。

InfluxDB 使用 [log-structured merge tree for storage with a write ahead log](https://docs.influxdata.com/influxdb/v1.7/concepts/storage_engine/) 的变体，使用时间分片。与 Prometheus 的为每个时间序列仅附加到文件的方法相比，此方法更适合事件记录。

InfluxDB uses a variant of a [log-structured merge tree for storage with a write ahead log](https://docs.influxdata.com/influxdb/v1.7/concepts/storage_engine/), sharded by time. This is much more suitable to event logging than Prometheus's append-only file per time series approach.

[Logs and Metrics and Graphs, Oh My!](https://blog.raintank.io/logs-and-metrics-and-graphs-oh-my/) 描述了事件记录和指标记录之间的区别。

### Architecture

Prometheus servers 彼此独立运行，并且仅依靠其本地存储来实现其核心功能：抓取，规则处理和警报。 InfluxDB 的开源版本与此类似。

根据设计，商业 InfluxDB 产品是一个分布式存储集群，其中存储和查询由多个节点一次处理。

这意味着商业 InfluxDB 将更易于水平扩展，但这也意味着您必须从一开始就管理分布式存储系统的复杂性。Prometheus 将更容易运行，但是在某些时候，您将需要按照产品，服务，数据中心或类似方面的可伸缩性边界明确地划分服务器。独立的服务（可以并行冗余运行）也可以为您提供更好的可靠性和故障隔离。

Kapacitor 的开源版本没有内置分布式/冗余选项用于规则，警报或通知。Kapacitor 的开源发行版可以通过用户手动分片来扩展，类似于 Prometheus 本身。 Influx 提供了 [Enterprise Kapacitor](https://docs.influxdata.com/enterprise_kapacitor)，它支持了 HA/冗余 警报系统。

相比之下，Prometheus 和 Alertmanager 通过运行 Prometheus 的冗余副本并使用 Alertmanager 的 [High Availability](https://github.com/prometheus/alertmanager#high-availability) 模式提供了完全开源的冗余选项。

### Summary

系统之间有许多相似之处。两者都有标签（在 InfluxDB 中称为tags）以有效支持多维指标。两者都使用基本相同的数据压缩算法。两者都有广泛的集成，包括彼此之间的集成。两者都有钩子，可让您进一步扩展它们，例如使用统计工具分析数据或执行自动化操作。

InfluxDB 更好的地方：

- 如果您要进行事件记录。
- 商业选项为 InfluxDB 提供集群，这对于长期数据存储也更好。
- 最终在副本之间保持一致的数据视图。

Prometheus 更好的地方：

- 如果您主要是在做指标。
- 更强大的查询语言，警报和通知功能。
- 图形和警报的可用性和正常运行时间更高。

Where Prometheus is better:

- If you're primarily doing metrics.
- More powerful query language, alerting, and notification functionality.
- Higher availability and uptime for graphing and alerting.

InfluxDB 由一家商业公司按照开放核心模型进行维护，并提供高级功能，例如封源的群集，托管和支持。Prometheus 是一个[完全开源的独立项目](https://prometheus.io/community/)，由许多公司和个人维护，其中一些还提供商业服务和支持。



## Prometheus vs. OpenTSDB

[OpenTSDB](http://opentsdb.net/) is a distributed time series database based on [Hadoop](https://hadoop.apache.org/) and [HBase](https://hbase.apache.org/).

### Scope

The same scope differences as in the case of [Graphite](https://prometheus.io/docs/introduction/comparison/#prometheus-vs-graphite) apply here.

### Data model

OpenTSDB's data model is almost identical to Prometheus's: time series are identified by a set of arbitrary key-value pairs (OpenTSDB tags are Prometheus labels). All data for a metric is [stored together](http://opentsdb.net/docs/build/html/user_guide/writing/index.html#time-series-cardinality), limiting the cardinality of metrics. There are minor differences though: Prometheus allows arbitrary characters in label values, while OpenTSDB is more restrictive. OpenTSDB also lacks a full query language, only allowing simple aggregation and math via its API.

### Storage

[OpenTSDB](http://opentsdb.net/)'s storage is implemented on top of [Hadoop](https://hadoop.apache.org/) and [HBase](https://hbase.apache.org/). This means that it is easy to scale OpenTSDB horizontally, but you have to accept the overall complexity of running a Hadoop/HBase cluster from the beginning.

Prometheus will be simpler to run initially, but will require explicit sharding once the capacity of a single node is exceeded.

### Summary

Prometheus offers a much richer query language, can handle higher cardinality metrics, and forms part of a complete monitoring system. If you're already running Hadoop and value long term storage over these benefits, OpenTSDB is a good choice.

## Prometheus vs. Nagios

[Nagios](https://www.nagios.org/) is a monitoring system that originated in the 1990s as NetSaint.

### Scope

Nagios is primarily about alerting based on the exit codes of scripts. These are called “checks”. There is silencing of individual alerts, however no grouping, routing or deduplication.

There are a variety of plugins. For example, piping the few kilobytes of perfData plugins are allowed to return [to a time series database such as Graphite](https://github.com/shawn-sterling/graphios) or using NRPE to [run checks on remote machines](https://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details).

### Data model

Nagios is host-based. Each host can have one or more services and each service can perform one check.

There is no notion of labels or a query language.

### Storage

Nagios has no storage per-se, beyond the current check state. There are plugins which can store data such as [for visualisation](https://docs.pnp4nagios.org/).

### Architecture

Nagios servers are standalone. All configuration of checks is via file.

### Summary

Nagios is suitable for basic monitoring of small and/or static systems where blackbox probing is sufficient.

If you want to do whitebox monitoring, or have a dynamic or cloud based environment, then Prometheus is a good choice.

## Prometheus vs. Sensu

[Sensu](https://sensu.io/) is a composable monitoring pipeline that can reuse existing Nagios checks.

### Scope

The same general scope differences as in the case of Nagios apply here.

There is also a [client socket](https://docs.sensu.io/sensu-core/latest/reference/clients/#what-is-the-sensu-client-socket) permitting ad-hoc check results to be pushed into Sensu.

### Data model

Sensu has the same rough data model as [Nagios](https://prometheus.io/docs/introduction/comparison/#prometheus-vs-nagios).

### Storage

Sensu uses Redis to persist monitoring data, including the Sensu client registry, check results, check execution history, and current event data.

### Architecture

Sensu has a [number of components](https://docs.sensu.io/sensu-core/latest/overview/architecture/). It uses RabbitMQ as a transport, Redis for current state, and a separate server for processing and API access.

All components of a Sensu deployment (RabbitMQ, Redis, and Sensu Server/API) can be clustered for highly available and redundant configurations.

### Summary

If you have an existing Nagios setup that you wish to scale as-is, or want to take advantage of the automatic registration feature of Sensu, then Sensu is a good choice.

If you want to do whitebox monitoring, or have a very dynamic or cloud based environment, then Prometheus is a good choice.

comparison to alternatives