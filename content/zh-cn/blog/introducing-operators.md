---
title: "Introducing Operators"
description: "Introducing Operators: Putting Operational Knowledge into Software."
date: 2020-07-28T13:12:05+08:00
author: LH
---

> 此文章为 [CoreOS Blog：Introducing Operators](https://coreos.com/blog/introducing-operators.html) 的译文。原文由 *Brandon Philips* 在 2016 年 11 月 3 日发表。文章内容已经过时，因此仅作为理解 Operator 的参考文章。

网站可靠性工程师（SRE）是通过编写软件来操作应用程序的人。他们是工程师，是开发者，他们知道如何专门为特定应用程序域开发软件。所产生的软件已在其中编程了应用程序的操作领域知识。我们的团队一直在 Kubernetes 社区中忙于设计和实施此概念，以在 Kubernetes 上可靠地创建、配置和管理复杂的应用程序实例。

我们称这种新的软件类别为操作员。Operator 是特定于应用程序的控制器，它扩展了 Kubernetes API 以代表 Kubernetes 用户创建、配置和管理复杂的有状态应用程序实例。它建立在 Kubernetes 基本资源和控制器概念的基础上，但包括领域或特定应用程序的知识，可自动执行常见任务。

## 无状态容易，有状态很难

借助 Kubernetes，即可相对轻松地管理和扩展 Web 应用程序、移动后端和开箱即用的 API 服务。为什么呢？因为这些应用程序通常是无状态的，因此基本的 Kubernetes API（例如 Deployments）可以在没有其他知识的情况下进行扩展并从故障中恢复。

更大的挑战是管理有状态的应用程序，例如数据库、缓存和监控系统。这些系统需要应用程序领域知识来正确扩展、升级和重新配置，同时防止数据丢失或不可用。我们希望将此特定于应用程序的操作知识编码到软件中，以利用强大的 Kubernetes 抽象来正确地运行和管理应用程序。

Operator 是一种软件，它对该领域知识进行了编码，并通过[第三方资源](http://kubernetes.io/docs/user-guide/thirdpartyresources/)机制扩展 Kubernetes API，使用户能够创建、配置和管理应用程序。像 Kubernetes 的内置资源一样，Operator 不仅管理应用程序的单个实例，而且管理整个集群中的多个实例。

![Overview-etcd_0](https://coreos.com/sites/default/files/inline-images/Overview-etcd_0.png)

为了在运行中代码演示 Operator 的概念，如今我们有两个具体的示例公开为了开源项目：

1. [*etcd Operator*](https://coreos.com/blog/introducing-the-etcd-operator.html) 创建、配置和管理 etcd 集群。etcd 是 CoreOS 引入的一种可靠的分布式键值存储，用于维持分布式系统中最关键的数据，并且是 Kubernetes 本身的主要配置数据存储。
2. [*Prometheus Operator*](https://coreos.com/blog/the-prometheus-operator.html) 创建、配置和管理 Prometheus 监控实例。Prometheus 是功能强大的监控、指标和警报工具，并且是 CoreOS 团队支持的 Cloud Native Computing Foundation（CNCF）项目。

## 如何构建 Operator？

Operator 基于 Kubernetes 的两个核心概念：资源和控制器。例如，内置的 [*ReplicaSet*](http://kubernetes.io/docs/user-guide/replicasets/) 资源使用户可以设置要运行的 Pod 的期望数量，并且 Kubernetes 内部的控制器通过创建或删除正在运行的 Pod 来确保 ReplicaSet 资源中设置的期望状态保持为 true。Kubernetes 中有许多以这种方式工作的基本控制器和资源，其中包括 [Services](http://kubernetes.io/docs/user-guide/services/)、[Deployments](http://kubernetes.io/docs/user-guide/deployments/) 和 [Daemon Sets](http://kubernetes.io/docs/admin/daemons/)。

![RS-before](https://coreos.com/sites/default/files/inline-images/RS-before.png)

示例1a：单个 Pod 正在运行，并且用户将期望的 Pod 数量更新为3。

![RS-scaled](https://coreos.com/sites/default/files/inline-images/RS-scaled.png)

示例1b：过了一会儿，Kubernetes 内部的控制器创建了新的 Pod 来满足用户的要求。

Operator 以 Kubernetes 基本资源和控制器概念为基础，并添加了一组知识或配置，以使 Operator 可以执行常见的应用程序任务。例如，当手动扩展 etcd 集群时，用户必须执行几个步骤：为新的 etcd 成员创建 DNS 名称，启动新的 etcd 实例，然后使用 etcd 管理工具（`etcdctl member add`）来告知现有群集有关此新成员的信息。取而代之的是，用户可以使用 *etcd Operator* 将 etcd 群集大小字段简单地增加 1。

![Operator-scale](https://coreos.com/sites/default/files/inline-images/Operator-scale.png)

示例2：备份由用户使用 kubectl 触发。

Operator 可能处理的其他复杂管理任务的示例包括安全协调应用程序升级、配置到异地存储的备份、通过原生 Kubernetes API 进行服务发现、应用程序 TLS 证书配置和灾难恢复。

## 如何创建 Operator？

Operator 本质上是特定于应用程序的，因此艰苦的工作是将所有应用程序操作领域知识编码为合理的配置资源和控制循环。在构建 Operator 时，我们发现了一些常见的模式，这些模式我们认为对任何应用程序都很重要的：

1. Operator 应将其作为单个部署进行安装，例如 `kubectl create -f https://coreos.com/operators/etcd/latest/deployment.yaml`，并且安装后无需执行任何其他操作。
2. Operator 在安装到 Kubernetes 中时应创建新的第三方类型。用户将使用此第三方类型创建新的应用程序实例。
3. Operator 应尽可能利用诸如 Services 和 Replica Sets 之类的内置 Kubernetes 原语，以利用经过良好测试和理解的代码。
4. Operator 应向后兼容，并始终理解用户创建的资源的先前版本。
5. Operator 应该被设计为无论 Operator 是否已停止或删除，应用程序实例都可以继续运行而不会受到影响。
6. Operator 应使用户能够声明期望版本，并基于期望版本协调应用程序升级。不升级软件是操作 bug 和安全问题的常见根源，Operator 可以帮助用户更自信地解决此负担。
7. Operator 应使用 "Chaos Monkey" 测试套件进行测试，该套件模拟了 Pod、配置和网络的潜在故障。

## Operator 发展方向

今天，CoreOS 推出的 etcd Operator 和 Prometheus Operator 展示了 Kubernetes 平台的强大功能。去年，我们与更广泛的 Kubernetes 社区一起工作，专注于使 Kubernetes 稳定、安全、易于管理和快速安装。

现在，在奠定了 Kubernetes 的基础之后，我们的新重点是建立在之上的系统：扩展 Kubernetes 使其具有新功能的软件。我们设想了一个未来，用户将在其 Kubernetes 集群上安装 Postgres Operator、Cassandra Operator 或 Redis Operator，并操作这些程序的可伸缩实例，就像它们今天轻松部署其无状态 Web 应用程序的副本一样。

要了解更多信息，请深入 GitHub 仓库，在我们的[社区频道上讨论，或者 11 月 8 日星期二在 [KubeCon](https://tectonic.com/blog/kubecon-preview.html) 上与 CoreOS 团队进行交流。不要错过太平洋时间 11 月 8 日星期二下午 5:25 的主题演讲，在这里我将介绍 Operator 和其他 Kubernetes 主题。

## FAQ

**Q：这与 StatefulSets（以前称为 PetSets）有何不同？**

A：StatefulSets 旨在为集群中的应用程序提供支持，这些应用程序需要集群为其提供“有状态资源”，例如静态 IP 和存储。需要这种更具有状态部署模型的应用程序仍需要 Operator 自动的根据故障，备份或重新配置采取行动。因此，需要这些部署属性的应用程序的 Operator 可以使用 StatefulSet，而不是利用 ReplicaSet 或 Deployment。

**Q：这与 Puppet 或 Chef 之类的配置管理有何不同？**

A：容器和 Kubernetes 是最大的差异，它使 Operator 成为可能。通过这两种技术，使用 Kubernetes API 部署新软件、协调分布式配置以及检查多主机系统状态，这是一致且容易的。Operator 以一种对应用程序使用者有用的方式将这些原语粘合在一起；它不仅涉及配置，还涉及整个实时应用程序状态。

**Q：这与 Helm 有何不同？**

A：Helm 是用于将多个 Kubernetes 资源打包到一个包中的工具。将多个应用程序打包在一起的概念和使用 Operator 主动管理应用程序是互补的。例如，traefik 是一个负载均衡器，可以将 etcd 用作其后端数据库。您可以创建一个 Helm Chart，将部署 traefik Deployment 和 etcd 集群实例放在一起。etcd 集群稍后将由 etcd Operator 进行部署和管理。

**Q：Kubernetes 新手该怎么办？这意味着什么？**

A：对于新用户来说，除了使他们部署复杂的应用程序（例如 etcd、Prometheus和未来的其他应用）更容易以外，这将不会改变任何东西，除非它使他们将来更容易部署诸如etcd，Prometheus等复杂的应用程序。我们建议的 Kubernetes 入门路径仍然是 [minikube](https://github.com/kubernetes/minikube)，[kubectl run](http://kubernetes.io/docs/user-guide/kubectl/kubectl_run/)，然后也许开始使用 Prometheus Operator 来监控使用 `kubectl run` 部署的应用程序。

**Q：如今 etcd Operator 和 Prometheus Operator 的代码是可用的吗？**

A：是的！可以在 GitHub 上的 https://github.com/coreos/etcd-operator 和 https://github.com/coreos/prometheus-operator 上找到他们。

**Q：您是否有其他 Operator 的计划？**

A：是的，将来可能会这样。我们也希望看到社区也建立了新的 Operator。让我们知道您接下来还想看到其他哪些 Operator。

**Q：Operator 如何帮助保护集群？**

A：不升级软件是操作 bug 和安全问题的常见根源，Operator 可以帮助用户更自信地解决正确升级的负担。

**Q：Operator 可以帮助灾难恢复吗？**

A：Operator 可以轻松地定期备份应用程序状态并从备份中恢复以前的状态。我们希望该功能将成为 Operator 的常见功能，它使用户能够轻松地从备份部署新实例。