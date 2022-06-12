---
title: "Controllers"
date: 2020-07-23T16:43:26+08:00
---

在机器人技术和自动化领域, 控制回路是一个非终止回路，用于调节系统状态。

控制回路的一个示例：房间中的恒温器

当你设定温度时，即告诉恒温器你期望的状态 desired status。实际的室温是当前状态 current status。恒温器通过打开或关闭设备, 使当前状态更接近期望状态。

在 Kubernetes 中，控制器是控制循环，它们监视集群的状态，然后在需要的时候进行更改或请求更改。每个控制器都尝试将当前集群状态移动到更接近期望状态。

## Controller pattern

一个控制器至少跟踪一种 Kubernetes 资源类型。这些对象有一个特定的字段代表着期望的状态。该资源的控制器负责使当前状态更接近于期望状态。

### Control via API server

Job 控制器是 Kubernetes 内置控制器的一个示例。内置控制器通过与集群 API 服务器进行交互来管理状态。

### Direct control

于 Job 相比，某些控制器需要对集群外部的内容进行更改。

与外部状态进行交互的控制器从 API 服务器中找到期望的状态，然后直接与外部系统进行通信以使当前状态更加紧密。

## Desired versus current status

### Design

作为其设计宗旨，Kubernetes 使用许多控制器，每个控制器管理集群状态的特定方面。最常见的是，一个特定的控制循环（controller）使用一种资源作为其期望状态，并有另一种不同的资源来设法使该期望状态发生。例如，Jobs 的控制器跟踪 Job 对象（以发现新工作）和 Pod 对象（以运行 Jobs，然后查看工作何时完成）。在这种情况下，其他东西创建 Jobs，而 job 控制器将创建 Pods。

> Note: 可以有多个控制器创建或更新相同类型的对象。在幕后，Kubernetes 控制器确保了他们仅关注与控制资源有关联的资源。例如，你可以有 Deployments 和 Jobs，他们都创建 Pods。Job 控制器不会删除 Deployment 创建的 Pods，因为控制器可以使用某些信息（标签）来区分这些 Pod。

### Ways of running controllers

Kubernetes 带有一组在 kube-controller-manager 内部运行的内置控制器。这些内置控制器提供了重要的核心行为。

Kubernetes 允许你运行弹性的控制平面，这样，如果任何内置控制器发生故障，控制平面的另一部分将接管工作。

你可以找到在控制平面以外运行的控制器来扩展 Kubernetes。或者，如果需要，你可以编写一个新的控制器。你可以将自己的控制器作为一组 Pod 运行，也可以在 Kubernetes 外部运行。最合适的选择取决于特定控制器的功能。

