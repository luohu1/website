---
title: "Overview"
date: 2020-07-25T13:34:21+08:00
weight: 1
---

## 什么是 Prometheus？

[Prometheus](https://github.com/prometheus) 是最初在 [SoundCloud](https://soundcloud.com/) 上构建的开源系统监视和警报工具包。自 2012 年成立以来，许多公司和组织都采用了 Prometheus，该项目拥有非常活跃的开发人员和用户[社区](https://prometheus.io/community)。现在，它是一个独立的开源项目，并且独立于任何公司进行维护。为了强调这一点并阐明项目的治理结构，Prometheus 在 2016 年加入了 [Cloud Native Computing Foundation](https://cncf.io/) ，这是继 Kubernetes 之后的第二个托管项目。有关 Prometheus 的详细说明，请参见 [media](https://prometheus.io/docs/introduction/media/) 部分中的资源链接。

### 特性

Prometheus 的主要特性是：

- 一个多维[数据模型](https://prometheus.io/docs/concepts/data_model/)，其中包含通过指标名称和键/值对标识的时间序列数据。
- PromQL，一种[灵活的查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)，可利用此维度。
- 不依赖分布式存储；单服务器节点是自治的。
- 时间序列收集通过 HTTP 上的拉模型进行。
- 通过中间网关支持[推送时间序列](https://prometheus.io/docs/instrumenting/pushing/)。
- 通过服务发现或静态配置发现目标。
- 支持多种模式的图形和仪表板

### 组件

Prometheus 生态系统由多个组件组成，其中许多是可选的：

- 主要的 [Prometheus server](https://github.com/prometheus/prometheus) 用于搜集并存储时间序列数据。
- [client libraries](https://prometheus.io/docs/instrumenting/clientlibs/) 用于检测应用程序代码。
- [push gateway](https://github.com/prometheus/pushgateway) 用于支持短期工作
- 服务专用的 [exporters](https://prometheus.io/docs/instrumenting/exporters/)，比如用于 HAProxy、StatsD、Graphite等服务。
- [alertmanager](https://github.com/prometheus/alertmanager) 用于处理警报。
- 各种支持工具

大多数 Prometheus 组件都是用 [Go](https://golang.org/) 编写的，因此易于构建和部署为静态二进制文件。

### 架构

下图说明了 Prometheus 的体系结构及其某些生态系统组件：

![architecture](https://prometheus.io/assets/architecture.png)

Prometheus 从已检测作业中搜集指标，或是直接地，或是通过中间推送网关处理短期工作。它将所有搜集的样品存储在本地，并对这些数据运行规则，以从现有数据中汇总和记录新时间序列，或生成警报。[Grafana](https://grafana.com/) 或其他 API 使用者可以用来可视化收集的数据。

## 什么时候适合？

Prometheus 可以很好地记录任何纯数字时间序列。它既适用于以机器为中心的监控，也适用于高度动态的面向服务的体系结构的监控。在微服务世界中，它对多维数据收集和查询的支持是一种特别的优势。

Prometheus 专为可靠性而设计，成为您要使用的系统，该系统帮助您在中断期间能够快速诊断问题。每个 Prometheus server 都是独立的，而不依赖于网络存储或其他远程服务。当基础结构的其他部分损坏时，您可以依靠它，并且无需设置广泛的基础结构即可使用它。

## 什么时候不适合？

Prometheus 重视可靠性。即使在故障情况下，您始终可以查看有关系统的可用统计信息。如果您需要 100％ 的准确性（例如按请求计费），则 Prometheus 并不是一个很好的选择，因为所收集的数据可能不够详细和完整。在这种情况下，最好使用其他系统来收集和分析数据以进行计费，并使用 Prometheus 进行其余的监视。