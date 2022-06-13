---
title: "干扰（Disruptions）"
date: 2020-07-23T16:43:26+08:00
weight: 11417
---

本指南针对的是希望构建高可用性应用程序的应用所有者，他们有必要了解可能发生在 Pod 上的干扰类型。

文档同样适用于想要执行自动化集群操作（例如升级和自动扩展集群）的集群管理员。

## 自愿干扰和非自愿干扰

Pod 不会消失，除非有人（用户或控制器）将其销毁，或者出现了不可避免的硬件或软件系统错误。

我们把这些不可避免的情况称为应用的*非自愿干扰*。例如：

- 节点下层物理机的硬件故障
- 集群管理员错误地删除虚拟机（实例）
- 云提供商或虚拟机管理程序中的故障导致的虚拟机消失
- 内核错误
- 节点由于集群网络隔离从集群中消失
- 由于节点[资源不足](https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/)导致 Pod 被驱逐。

除了资源不足的情况，大多数用户应该都熟悉这些情况；它们不是特定于 Kubernetes 的。

我们称其他情况为*自愿干扰*。包括由应用程序所有者发起的操作和由集群管理员发起的操作。典型的应用程序所有者的 作包括：

- 删除 deployment 或其他管理 pod 的控制器
- 更新了 deployment 的 pod 模板导致 pod 重启
- 直接删除 pod（例如，因为误操作）

集群管理员操作包括：

- [排空（drain）节点](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)进行修复或升级。
- 从集群中排空节点以缩小集群（了解[集群自动扩缩](https://kubernetes.io/docs/tasks/administer-cluster/cluster-management/#cluster-autoscaler)）。
- 从节点中移除一个 pod，以允许其他 pod 使用该节点。

这些操作可能由集群管理员直接执行，也可能由集群管理员所使用的自动化工具执行，或者由集群托管提供商自动执行。

咨询集群管理员或联系云提供商，或者查询发布文档，以确定是否为集群启用了任何自愿干扰源。如果没有启用，可以不用创建 Pod Disruption Budgets（Pod 干扰预算）。

> **警告：**并非所有的自愿干扰都会受到 Pod 干扰预算的限制。例如，删除 deployment 或 pod 的删除操作就会跳过 pod 干扰预算检查。

## 处理干扰

以下是减轻非自愿干扰的一些方法：

- 确保 Pod [请求所需资源](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-ram-container)。
- 如果需要更高的可用性，请复制应用程序。（了解有关运行多副本的[无状态](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/)和[有状态](https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/)应用程序的信息。）
- 为了在运行复制应用程序时获得更高的可用性，请跨机架（使用[反亲和性](https://kubernetes.io/docs/user-guide/node-selection/#inter-pod-affinity-and-anti-affinity-beta-feature)）或跨区域（如果使用[多区域集群](https://kubernetes.io/docs/setup/multiple-zones)）扩展应用程序。

自愿干扰的频率各不相同。在一个基本的 Kubernetes 集群中，根本没有自愿干扰。然而，集群管理员或托管提供商可能运行一些可能导致自愿干扰的额外服务。例如，节点软件更新可能导致自愿干扰。另外，集群（节点）自动缩放的某些实现可能导致碎片整理和紧缩节点的自愿干扰。集群管理员或托管提供商应该已经记录了各级别的自愿干扰（如果有的话）。

Kubernetes 提供特性来满足在出现频繁自愿干扰的同时运行高可用的应用程序。我们称这些特性为*干扰预算*。

## 干扰预算工作原理

**功能状态：** `Kubernetes v1.5 [beta]`

应用程序所有者可以为每个应用程序创建 `PodDisruptionBudget` 对象（PDB）。PDB 将限制在同一时间因自愿干扰导致的复制应用程序中宕机的 Pod 数量。例如，基于仲裁的应用程序希望确保运行的副本数永远不会低于仲裁所需的数量。Web 前端可能希望确保提供负载的副本数量永远不会低于总数的某个百分比。

集群管理员和托管提供商应该使用遵循 Pod Disruption Budgets 的工具（通过调用[驱逐 API](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#the-eviction-api)），而不是直接删除 Pod 或 Deployment。示例包括 `kubectl drain` 命令和 Kubernetes-on-GCE 集群升级脚本（`cluster/gce/upgrade.sh`）。

当集群管理员想排空一个节点时，可以使用 `kubectl drain` 命令。该命令试图驱逐机器上的所有 Pod。驱逐请求可能会暂时被拒绝，且该工具定时重试失败的请求直到所有的 Pod 都被终止，或者达到配置的超时时间。

PDB 指定应用程序可以容忍的副本数量（相当于应该有多少副本）。例如，具有 `.spec.replicas: 5` 的 Deployment 在任何时间都应该有 5 个 pod。如果 PDB 允许其在某一时刻有 4 个副本，那么驱逐 API 将允许同一时刻仅有一个而不是两个 Pod 自愿干扰。

使用标签选择器来指定构成应用程序的一组 Pod，这与应用程序的控制器（deployment，stateful-set 等）选择 Pod 的逻辑一样。

Pod 控制器的 `.spec.replicas` 计算“预期的” Pod 数量。根据 Pod 对象的 `.metadata.ownerReferences` 字段来发现控制器。

PDB 不能阻止[非自愿干扰](https://kubernetes.io/zh/docs/concepts/workloads/pods/disruptions/#voluntary-and-involuntary-disruptions)的发生，但是确实会计入预算。

由于应用程序的滚动升级而被删除或不可用的 Pod 确实会计入干扰预算，但是控制器（如 deployment 和 stateful-set）在进行滚动升级时不受 PDB 的限制。应用程序更新期间的故障处理是在控制器的 spec 中配置的。（了解[更新 deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)。）

当使用驱逐 API 驱逐 Pod 时，Pod 会被优雅地终止（参考 [PodSpec](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#podspec-v1-core) 中的 `terminationGracePeriodSeconds`）。

## PDB 例子

假设集群有 3 个节点，`node-1` 到 `node-3`。集群上运行了一些应用。其中一个应用有 3 个副本，分别是 `pod-a`，`pod-b` 和 `pod-c`。另外，还有一个不带 PDB 的无关 pod `pod-x` 也同样显示。最初，所有的 pod 分布如下：

| node-1            | node-2            | node-3            |
| ----------------- | ----------------- | ----------------- |
| pod-a *available* | pod-b *available* | pod-c *available* |
| pod-x *available* |                   |                   |

3 个 pod 都是 deployment 的一部分，并且共同拥有同一个 PDB，要求 3 个 pod 中至少有 2 个 pod 始终处于可用状态。

例如，假设集群管理员想要重启系统，升级内核版本来修复内核中的 bug。集群管理员首先使用 `kubectl drain` 命令尝试排空 `node-1` 节点。命令尝试驱逐 `pod-a` 和 `pod-x`。操作立即就成功了。两个 pod 同时进入 `terminating` 状态。这时的集群处于下面的状态：

| node-1 *draining*   | node-2            | node-3            |
| ------------------- | ----------------- | ----------------- |
| pod-a *terminating* | pod-b *available* | pod-c *available* |
| pod-x *terminating* |                   |                   |

Deployment 控制器观察到其中一个 pod 正在终止，因此它创建了一个替代 pod `pod-d`。由于 `node-1` 被封锁（cordon），`pod-d` 落在另一个节点上。同样其他控制器也创建了 `pod-y` 作为 `pod-x` 的替代品。

（注意：对于 StatefulSet 来说，`pod-a`（也称为 `pod-0`）需要在替换 pod 创建之前完全终止，替代它的也称为 `pod-0`，但是具有不同的 UID。反之，样例也适用于 StatefulSet。）

当前集群的状态如下：

| node-1 *draining*   | node-2            | node-3            |
| ------------------- | ----------------- | ----------------- |
| pod-a *terminating* | pod-b *available* | pod-c *available* |
| pod-x *terminating* | pod-d *starting*  | pod-y             |

在某一时刻，pod 被终止，集群如下所示：

| node-1 *drained* | node-2            | node-3            |
| ---------------- | ----------------- | ----------------- |
|                  | pod-b *available* | pod-c *available* |
|                  | pod-d *starting*  | pod-y             |

此时，如果一个急躁的集群管理员试图排空（drain）`node-2` 或 `node-3`，drain 命令将被阻塞，因为对于 deployment 来说只有 2 个可用的 pod，并且它的 PDB 至少需要 2 个。经过一段时间，`pod-d` 变得可用。

集群状态如下所示：

| node-1 *drained* | node-2            | node-3            |
| ---------------- | ----------------- | ----------------- |
|                  | pod-b *available* | pod-c *available* |
|                  | pod-d *available* | pod-y             |

现在，集群管理员试图排空（drain）`node-2`。drain 命令将尝试按照某种顺序驱逐两个 pod，假设先是 `pod-b`，然后是 `pod-d`。命令成功驱逐 `pod-b`，但是当它尝试驱逐 `pod-d` 时将被拒绝，因为对于 deployment 来说只剩一个可用的 pod 了。

Deployment 创建 `pod-b` 的替代 pod `pod-e`。因为集群中没有足够的资源来调度 `pod-e`，drain 命令再次阻塞。集群最终将是下面这种状态：

| node-1 *drained* | node-2            | node-3            | *no node*       |
| ---------------- | ----------------- | ----------------- | --------------- |
|                  | pod-b *available* | pod-c *available* | pod-e *pending* |
|                  | pod-d *available* | pod-y             |                 |

此时，集群管理员需要增加一个节点到集群中以继续升级操作。

可以看到 Kubernetes 如何改变干扰发生的速率，根据：

- 应用程序需要多少个副本
- 优雅关闭应用实例需要多长时间
- 启动应用新实例需要多长时间
- 控制器的类型
- 集群的资源容量

## 分离集群所有者和应用所有者角色

通常，将集群管理者和应用所有者视为彼此了解有限的独立角色是很有用的。这种责任分离在下面这些场景下是有意义的：

- 当有许多应用程序团队共用一个 Kubernetes 集群，并且有自然的专业角色
- 当第三方工具或服务用于集群自动化管理

Pod 干扰预算通过在角色之间提供接口来支持这种分离。

如果你的组织中没有这样的责任分离，则可能不需要使用 Pod 干扰预算。

## 如何在集群上执行干扰操作

如果你是集群管理员，并且需要对集群中的所有节点执行干扰操作，例如节点或系统软件升级，则可以使用以下选项

- 接受升级期间的停机时间。
- 故障转移到另一个完整的副本集群。
  - 没有停机时间，但是对于重复的节点和人工协调成本可能是昂贵的。
- 编写可容忍干扰的应用程序和使用 PDB。
  - 不停机。
  - 最小的资源重复。
  - 允许更多的集群管理自动化。
  - 编写可容忍干扰的应用程序是棘手的，但对于支持容忍自愿干扰所做的工作，和支持自动扩缩和容忍非自愿干扰所做的工作相比，有大量的重叠。

