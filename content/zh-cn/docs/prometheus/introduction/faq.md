---
title: "Frequently Asked Questions"
date: 2020-07-25T18:12:30+08:00
weight: 4
---

## General

### 什么是 Prometheus？

Prometheus 是具有活跃生态系统的开源系统监视和警报工具包。请参阅 [overview](https://prometheus.io/docs/introduction/overview/)。

### Prometheus 与其他监控系统相比如何？

请参阅 [comparison](https://prometheus.io/docs/introduction/comparison/) 页面。

### Prometheus 有什么依赖性？

主要的 Prometheus server 独立运行，没有外部依赖性。

### 可以使 Prometheus 高度可用吗？

是的，在两台或更多台单独的计算机上运行相同的 Prometheus server。相同的警报将由 [Alertmanager](https://github.com/prometheus/alertmanager) 进行重复数据删除。

为了 [Alertmanager的高可用](https://github.com/prometheus/alertmanager#high-availability)，您可以在 [Mesh cluster](https://github.com/weaveworks/mesh) 中运行多个实例，并将 Prometheus server 配置为向每个实例发送通知。

### 有人告诉我 Prometheus “不能缩放”。

实际上，存在多种缩放和联合 Prometheus 的方法。阅读 Robust Perception 博客上的 [Scaling and Federating Prometheus](https://www.robustperception.io/scaling-and-federating-prometheus/)，以开始使用。

### Prometheus 用什么语言编写？

大多数 Prometheus 组件都是用Go编写的。有些还用 Java、Python 和 Ruby 编写。

### Prometheus 功能、存储格式和 API 的稳定性如何？

All repositories in the Prometheus GitHub organization that have reached version 1.0.0 broadly follow [semantic versioning](http://semver.org/). Breaking changes are indicated by increments of the major version. Exceptions are possible for experimental components, which are clearly marked as such in announcements.

Even repositories that have not yet reached version 1.0.0 are, in general, quite stable. We aim for a proper release process and an eventual 1.0.0 release for each repository. In any case, breaking changes will be pointed out in release notes (marked by `[CHANGE]`) or communicated clearly for components that do not have formal releases yet.

### 为什么要拉取而不是推送？

通过 HTTP 拉取有许多优点：

- 开发更改时，可以在笔记本电脑上运行监控。
- 您可以更轻松地判断目标是否已关闭。
- 您可以手动转到目标并使用Web浏览器检查其运行状况。

总体而言，我们认为拉取要比推送略好，但在考虑使用监控系统时，不应将其视为重点。

对于必须推送的情况，我们提供了 [Pushgateway](https://prometheus.io/docs/instrumenting/pushing/)。

### 如何将日志输入 Prometheus？

Short answer: Don't! Use something like the [ELK stack](https://www.elastic.co/products) instead.

Longer answer: Prometheus is a system to collect and process metrics, not an event logging system. The Raintank blog post [Logs and Metrics and Graphs, Oh My!](https://blog.raintank.io/logs-and-metrics-and-graphs-oh-my/) provides more details about the differences between logs and metrics.

If you want to extract Prometheus metrics from application logs, Google's [mtail](https://github.com/google/mtail) might be helpful.

### 谁写了 Prometheus？

Prometheus was initially started privately by [Matt T. Proud](http://www.matttproud.com/) and [Julius Volz](http://juliusv.com/). The majority of its initial development was sponsored by [SoundCloud](https://soundcloud.com/).

It's now maintained and extended by a wide range of companies and individuals.

### Prometheus 使用什么许可证？

Prometheus is released under the [Apache 2.0](https://github.com/prometheus/prometheus/blob/master/LICENSE) license.

### Prometheus 的复数是什么？

After [extensive research](https://youtu.be/B_CDeYrqxjQ), it has been determined that the correct plural of 'Prometheus' is 'Prometheis'.

### 我可以重新载入 Prometheus 的配置吗？

Yes, sending `SIGHUP` to the Prometheus process or an HTTP POST request to the `/-/reload` endpoint will reload and apply the configuration file. The various components attempt to handle failing changes gracefully.

### 我可以发送警报吗？

Yes, with the [Alertmanager](https://github.com/prometheus/alertmanager).

Currently, the following external systems are supported:

- Email
- Generic Webhooks
- [HipChat](https://www.hipchat.com/)
- [OpsGenie](https://www.opsgenie.com/)
- [PagerDuty](https://www.pagerduty.com/)
- [Pushover](https://pushover.net/)
- [Slack](https://slack.com/)

### Can I create dashboards?

Yes, we recommend [Grafana](https://prometheus.io/docs/visualization/grafana/) for production usage. There are also [Console templates](https://prometheus.io/docs/visualization/consoles/).

### Can I change the timezone? Why is everything in UTC?

To avoid any kind of timezone confusion, especially when the so-called daylight saving time is involved, we decided to exclusively use Unix time internally and UTC for display purposes in all components of Prometheus. A carefully done timezone selection could be introduced into the UI. Contributions are welcome. See [issue #500](https://github.com/prometheus/prometheus/issues/500) for the current state of this effort.

## Instrumentation

### Which languages have instrumentation libraries?

There are a number of client libraries for instrumenting your services with Prometheus metrics. See the [client libraries](https://prometheus.io/docs/instrumenting/clientlibs/) documentation for details.

If you are interested in contributing a client library for a new language, see the [exposition formats](https://prometheus.io/docs/instrumenting/exposition_formats/).

### Can I monitor machines?

Yes, the [Node Exporter](https://github.com/prometheus/node_exporter) exposes an extensive set of machine-level metrics on Linux and other Unix systems such as CPU usage, memory, disk utilization, filesystem fullness, and network bandwidth.

### Can I monitor network devices?

Yes, the [SNMP Exporter](https://github.com/prometheus/snmp_exporter) allows monitoring of devices that support SNMP.

### Can I monitor batch jobs?

Yes, using the [Pushgateway](https://prometheus.io/docs/instrumenting/pushing/). See also the [best practices](https://prometheus.io/docs/practices/instrumentation/#batch-jobs) for monitoring batch jobs.

### What applications can Prometheus monitor out of the box?

See [the list of exporters and integrations](https://prometheus.io/docs/instrumenting/exporters/).

### Can I monitor JVM applications via JMX?

Yes, for applications that you cannot instrument directly with the Java client, you can use the [JMX Exporter](https://github.com/prometheus/jmx_exporter) either standalone or as a Java Agent.

### What is the performance impact of instrumentation?

Performance across client libraries and languages may vary. For Java, [benchmarks](https://github.com/prometheus/client_java/blob/master/benchmark/README.md) indicate that incrementing a counter/gauge with the Java client will take 12-17ns, depending on contention. This is negligible for all but the most latency-critical code.

## 故障排除

### 我的 Prometheus 1.x server 需要很长时间才能启动，并且会向日志中发送有关崩溃恢复的大量信息的垃圾邮件。

You are suffering from an unclean shutdown. Prometheus has to shut down cleanly after a `SIGTERM`, which might take a while for heavily used servers. If the server crashes or is killed hard (e.g. OOM kill by the kernel or your runlevel system got impatient while waiting for Prometheus to shutdown), a crash recovery has to be performed, which should take less than a minute under normal circumstances, but can take quite long under certain circumstances. See [crash recovery](https://prometheus.io/docs/prometheus/1.8/storage/#crash-recovery) for details.

### My Prometheus 1.x server runs out of memory.

See [the section about memory usage](https://prometheus.io/docs/prometheus/1.8/storage/#memory-usage) to configure Prometheus for the amount of memory you have available.

### My Prometheus 1.x server reports to be in “rushed mode” or that “storage needs throttling”.

Your storage is under heavy load. Read [the section about configuring the local storage](https://prometheus.io/docs/prometheus/1.8/storage/) to find out how you can tweak settings for better performance.

## Implementation

### Why are all sample values 64-bit floats? I want integers.

We restrained ourselves to 64-bit floats to simplify the design. The [IEEE 754 double-precision binary floating-point format](https://en.wikipedia.org/wiki/Double-precision_floating-point_format) supports integer precision for values up to 253. Supporting native 64 bit integers would (only) help if you need integer precision above 253 but below 263. In principle, support for different sample value types (including some kind of big integer, supporting even more than 64 bit) could be implemented, but it is not a priority right now. A counter, even if incremented one million times per second, will only run into precision issues after over 285 years.

### Why don't the Prometheus server components support TLS or authentication? Can I add those?

Note: The Prometheus team has changed their stance on this during its development summit on August 11, 2018, and support for TLS and authentication in serving endpoints is now on the [project's roadmap](https://prometheus.io/docs/introduction/roadmap/#tls-and-authentication-in-http-serving-endpoints). This document will be updated once code changes have been made.

While TLS and authentication are frequently requested features, we have intentionally not implemented them in any of Prometheus's server-side components. There are so many different options and parameters for both (10+ options for TLS alone) that we have decided to focus on building the best monitoring system possible rather than supporting fully generic TLS and authentication solutions in every server component.

If you need TLS or authentication, we recommend putting a reverse proxy in front of Prometheus. See, for example [Adding Basic Auth to Prometheus with Nginx](https://www.robustperception.io/adding-basic-auth-to-prometheus-with-nginx/).

This applies only to inbound connections. Prometheus does support [scraping TLS- and auth-enabled targets](https://prometheus.io/docs/operating/configuration/#), and other Prometheus components that create outbound connections have similar support.