---
title: "Prometheus Operator"
description: "The Prometheus Operator: Managed Prometheus setups for Kubernetes."
date: 2020-07-27T13:51:23+08:00
author: LH
---

> 此文章为 [CoreOS Blog：The Prometheus Operator](https://coreos.com/blog/the-prometheus-operator.html) 的译文。

**Note: 这篇文章中的说明已过期。**要尝试 Prometheus Operator，请查看最新的 [Prometheus 文档](https://coreos.com/operators/prometheus/docs/latest/user-guides/getting-started.html) ，以获取最新的入门指南。

今天，CoreOS 推出了一种全新的软件类别，被称为 [Operators](https://coreos.com/blog/introducing-operators.html)，并且还将引入两个 Operator 作为开源项目，一个用于 etcd，另一个用于 Prometheus。在本文中，我们将概述 Operator 对于 Prometheus（Kubernetes 的监控系统）的重要性。

Operator 以 Kubernetes 基本资源和控制器概念为基础，但包括应用程序领域知识以执行常见任务。它们最终将帮助您专注于期望的配置，而不是手动部署和生命周期管理的细节。

Prometheus 是 Kubernetes 的近亲：Google 引入了 Kubernetes 作为其 Borg 集群系统的开源后代，Prometheus 来分享 Borgmon（与 Borg 配套的监控系统）的基本设计理念。如今，Prometheus 和 Kubernetes 都由 Cloud Native Computing Foundation（CNCF）管理。在技术层面上，Kubernetes 以原生 Prometheus 格式导出其所有内部指标。

## Prometheus Operator：整合 Kubernetes 和 Prometheus 的最佳方法

Prometheus Operator 只需一个命令行即可轻松安装，并且允许用户使用简单的声明性配置来配置和管理Prometheus实例，该配置将作为响应来创建，配置和管理Prometheus监视实例。

![Overview-prometheus_0](https://coreos.com/sites/default/files/inline-images/Overview-prometheus_0.png)

Prometheus Operator 安装后，将提供以下功能：

- 创建/销毁：使用 Operator 轻松为您的 Kubernetes 命名空间，特定的应用程序或团队启动 Prometheus 实例。

- 简单配置：从原生 Kubernetes 资源配置 Prometheus 的基础知识，例如版本、持久性、保留策略和副本。

- 通过标签的目标服务：基于熟悉的 Kubernetes 标签查询自动生成监控目标配置；无需学习 Prometheus 特定的配置语言。

> 请注意，Prometheus Operator 正在大量开发中，请关注 [GitHub上的项目](https://github.com/coreos/prometheus-operator) 以获取最新信息。

## 工作原理

Operator 的核心思想是将 Prometheus 实例的部署与它们所监视的实体的配置分离。为此，定义了两个[第三方资源](http://kubernetes.io/docs/user-guide/thirdpartyresources/)（TPR）：`Prometheus` 和 `ServiceMonitor`。

Operator 始终确保对于群集中的每个 `Prometheus` 资源，一组具有期望配置的 Prometheus server 正在运行。这涉及到诸如数据保留时间、持久卷声明、副本数量、Prometheus 版本和 Alertmanager 实例向谁发送警报等方面。每个 Prometheus 实例都与各自的配置配对，该配置指定要向哪些监控目标抓取指标以及使用哪些参数。

用户可以手动指定此配置，也可以让 Operator 根据第二个TPR `ServiceMonitor` 生成它。`ServiceMonitor` 资源指定如何从一组以通用方式公开指标的服务中检索指标。`Prometheus` 资源对象可以通过其标签动态包含 `ServiceMonitor` 对象。Operator 配置 Prometheus 实例去监控该实例中包括的 `ServiceMonitor` 所覆盖的所有服务，并使此配置与群集中发生的任何更改保持同步。

Operator 封装了 Prometheus 领域知识的很大一部分，并且仅显示了对监控系统最终用户有意义的方面。这是一种强大的方法，可以使组织中所有团队的工程师以这种自主且灵活的方式运行他们的监控。

![p1](https://coreos.com/sites/default/files/inline-images/p1.png)

## Prometheus Operator in Action

我们将通过创建 Prometheus 实例和一些要监视的服务来逐步演示 Prometheus Operator。让我们从部署第一个 Prometheus 实例开始。

首先，您需要一个运行中的 Kubernetes 集群，该集群版本为 v1.3.x 或 v1.4.x 并且启用了 alpha API（请注意，v1.5.0+ 的群集不适用于此博客文章中使用的 Prometheus Operator 版本；有关如何在新版本的 Kubernetes 上运行的最新信息，请参见Prometheus Operator [文档](https://github.com/coreos/prometheus-operator/tree/master/Documentation)和 [kube-prometheus](https://github.com/coreos/kube-prometheus)）。如果您还没有一个集群，请按照 [minikube 的提示](https://github.com/kubernetes/minikube)快速启动并运行本地集群。

> 注意：minikube 隐藏了 Kubernetes 的某些组件，但这是设置要使用的集群的最快方法。对于更广泛且类似于生产的环境，请查看使用 [bootkube](https://github.com/kubernetes-incubator/bootkube) 设置集群。

### 托管部署

让我们首先在集群中部署 Prometheus Operator：

```shell
$ kubectl create -f https://coreos.com/operators/prometheus/latest/prometheus-operator.yaml
deployment "prometheus-operator" created
```

验证它已启动并正在运行，并且已向 Kubernetes API server 注册了 TPR 类型。

```shell
$ kubectl get pod
NAME                                   READY     STATUS    RESTARTS   AGE
prometheus-operator-1078305193-ca4vs   1/1       Running   0          5m
$ until kubectl get prometheus; do sleep 1; done
# … wait ...
# If no more errors are printed, the TPR types were registered successfully.
```

部署单个 Prometheus 实例的 Prometheus TPR 的简单定义如下所示：

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: Prometheus
metadata:
  name: prometheus-k8s
  labels:
    prometheus: k8s
spec:
  version: v1.3.0
```

要在集群中创建它，请运行：

```shell
$ kubectl create -f https://coreos.com/operators/prometheus/latest/prometheus-k8s.yaml
prometheus "prometheus-k8s" created
service "prometheus-k8s" created
```

这还将创建服务以使用户可以访问 Prometheus UI。出于本演示的目的，创建了将其暴露在 NodePort 30900 上的服务。

之后立即观察 Operator 部署 Prometheus pod：

```shell
$ kubectl get pod -w
NAME                                   READY     STATUS    RESTARTS   AGE
prometheus-k8s-0                       3/3       Running   0          2m
```

现在我们可以通过转到 `http://:30900` 来访问 Prometheus UI，使用 minikube 时运行 `$ minikube service prometheus-k8s`。

以相同的方式，我们可以轻松地部署其他 Prometheus server，并在 Prometheus TPR 中使用高级选项，以使 Operator 能够处理版本升级、持久卷声明以及将 Prometheus 连接到 Alertmanager 实例。

您可以在[存储库文档](https://github.com/coreos/prometheus-operator/blob/0e6ed120261f101e6f0dc9581de025f136508ada/Documentation/prometheus.md)中阅读有关托管 Prometheus 部署的全部功能的更多信息。

### 集群监控

我们成功创建了托管的 Prometheus server。但是，由于我们未提供任何配置，因此它尚未监视任何内容。每个 Prometheus 部署都会挂载一个以自身命名的 Kubernetes ConfigMap，即我们的 Prometheus server 会在其命名空间中挂载 “prometheus-k8s” ConfigMap 中提供的配置。

我们希望 Prometheus server 监视群集本身的所有方面，例如容器资源使用情况、群集节点和 kubelet。Kubernetes 选择 Prometheus 指标格式作为公开其所有组件的指标的方式。因此，我们只需要将 Prometheus 指向正确的端点即可检索这些指标。几乎在任何集群上这都可以工作，我们可以在 kube-prometheus 存储库中使用预定义的清单。

```shell
# Deploy exporters providing metrics on cluster nodes and Kubernetes business logic
$ kubectl create -f https://coreos.com/operators/prometheus/latest/exporters.yaml
deployment "kube-state-metrics" created
service "kube-state-metrics" created
daemonset "node-exporter" created
service "node-exporter" created
# Create the ConfigMap containing the Prometheus configuration
$ kubectl apply -f https://coreos.com/operators/prometheus/latest/prometheus-k8s-cm.yaml
configmap "prometheus-k8s" configured
```

Kubernetes 更新 Prometheus Pod 中配置后不久，我们可以在 “Targets” 页面上看到目标出现。Prometheus 实例现在正在接收指标，并已经可以在 UI 或仪表板中查询并评估警报。

![p3](https://coreos.com/sites/default/files/inline-images/p3.png)

### 服务监控

除了监视集群组件之外，我们还希望监视我们自己的服务。使用常规的 Prometheus 配置，我们必须处理 [relabeling](https://prometheus.io/docs/operating/configuration/#) 的概念才能正确发现和配置监视目标。它是一种强大的方法，可以使 Prometheus 与各种服务发现机制和任意操作模型集成。但是，它非常[冗长和重复](https://github.com/prometheus/prometheus/blob/63fe65bf2ff8c480bb4350e4d278d3208ca687be/documentation/examples/prometheus-kubernetes.yml#L96-L120)，因此通常不适合手动编写。

Prometheus Operator 通过定义第二个 TPR 来解决此问题，该 TPR 表示如何以对 Kubernetes 完全惯用的方式监视我们的自定义服务。

假设我们所有带有 `tier = frontend` 标签的服务都在命名端口 `web` 上的标准路径 `/metrics` 下提供了指标。`ServiceMonitor` TPR 允许我们声明性地表示适用于所有那些服务的监视配置，并通过标签 `tier` 进行选择。

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: ServiceMonitor
metadata:
  name: frontend
  labels:
    tier: frontend
spec:
  selector:
    matchLabels:
      tier: frontend
  endpoints:
  - port: web            # works for different port numbers as long as the name matches
    interval: 10s        # scrape the endpoint every 10 seconds
```

这仅定义了应如何监视一组服务。我们现在需要定义 Prometheus 实例将该 `ServiceMonitor` 包含在其配置中。再次根据标签选择属于 Prometheus 设置的 `ServiceMonitor`。在部署所述 Prometheus 实例时，Operator 将根据匹配的服务监视器对其进行配置。

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: Prometheus
metadata:
  name: prometheus-frontend
  labels:
    prometheus: frontend
spec:
  version: v1.3.0
  # Define that all ServiceMonitor TPRs with the label `tier = frontend` should be included
  # into the server's configuration.
  serviceMonitors:
  - selector:
      matchLabels:
        tier: frontend
```

我们通过运行以下命令创建 `ServiceMonitor` 和 `Prometheus` 对象：

```
$ kubectl create -f https://coreos.com/operators/prometheus/latest/servicemonitor-frontend.yaml
servicemonitor "frontend" created
$ kubectl create -f https://coreos.com/operators/prometheus/latest/prometheus-frontend.yaml
prometheus "prometheus-frontend" created
service "prometheus-frontend" created
```

访问 `http://:30100`（使用 minikube 时运行 `$ minikube service prometheus-frontend`），我们可以看到新的 Prometheus server 的UI。由于 `ServiceMonitor` 没有服务应用 `ServiceMonitor`，因此 “Targets” 页面仍然为空。

以下命令部署四个示例应用程序的实例，以暴露由 `ServiceMonitor` 定义的指标，并匹配其 `tier = frontend` 标签选择器。

```shell
$ kubectl create -f https://coreos.com/operators/prometheus/latest/example-app.yaml
```

回到 Web UI，我们可以看到新的 Pod 立即显示在 “Targets” 页面上，并且可以查询其公开的指标。我们的示例应用程序的服务和 Pod 标签，以及 Kubernetes 命名空间，作为标签自动地附加到了抓取的指标。这使我们能够在 Prometheus 查询和警报中进行汇总和过滤。

![p2](https://coreos.com/sites/default/files/inline-images/p2.png)

Prometheus 将自动选择带有 `tier = frontend` 标签的新服务，并适配其上下扩展的部署。此外，如果添加、删除或修改 `ServiceMonitor`，Operator 将立即适当地重新配置 Prometheus。

下图形象地显示了控制器如何通过观察我们的 `Prometheus` 和 `ServiceMonitor` 资源的状态来管理 Prometheus 部署。资源之间的关系通过标签表示，在运行时任何更改都会立即生效。

## 未来发展方向

今天通过引入 Operator，我们展示了 Kubernetes 平台的强大功能。Prometheus Operator 扩展了 Kubernetes API 新的监视功能。我们已经了解了 Prometheus Operator 如何帮助我们动态部署 Prometheus 实例并管理其生命周期。此外，它提供了一种以纯粹的 Kubernetes 习惯用语表达定义服务监视的方法。监控真正成为集群本身的一部分，并且抽象出了所使用的不同系统的所有实现细节。

尽管仍处于开发的早期阶段，但是 Operator 已经处理了 Prometheus 设置的多个方面，这些方面超出了本博客文章的范围，例如持久性存储、复制、警报和版本更新。查看 [Operator 文档](https://github.com/coreos/prometheus-operator/blob/master/README.md)以了解更多信息。[kube-prometheus](https://github.com/coreos/kube-prometheus) 存储库包含各种基本知识，可以使您的群集监控立即启动并运行。它还为群集组件提供了现成的仪表板和警报。

敬请期待 Prometheus Operator的更多功能和其他 operator 同样轻松地在集群内部运行 [Prometheus Alertmanager](https://prometheus.io/docs/alerting/alertmanager/) 和 [Grafana](http://grafana.org/)。

## 在 KubeCon 上加入 CoreOS

2016 年 11 月 8 日至 9 日，我们将在西雅图 KubeCon 的 Kubernetes 会议上举办一系列活动。加入我们，尤其是在 [11 月 9 日（星期三）下午 3:30 举行的普罗米修斯主题演讲中](http://sched.co/8NaV)。 PT，它将深入探究 Prometheus Operator。

确保检查出[完整的 CoreOS KubeCon 活动日程](https://tectonic.com/blog/kubecon-preview.html)，然后停下来，在 CoreOS 展位与我们的工程师一起解决您的 Kubernetes 和容器问题，或者[请求与专家进行现场销售会议](https://coreos.com/resources/meeting-request/)。

Be sure to check out the [full schedule of CoreOS KubeCon events](https://tectonic.com/blog/kubecon-preview.html), then stop by and visit our engineers at the CoreOS booth with your Kubernetes and container questions, or [request an on-site sales meeting](https://coreos.com/resources/meeting-request/) with a specialist.

## 相关文章：

[Operator 简介：将操作知识纳入软件](https://coreos.com/blog/introducing-operators.html)

