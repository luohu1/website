

# Pod Overview

Pod 是 Kubernetes 对象模型中最小的可部署对象。

## 理解 Pods

Pod 是 Kubernetes 应用程序的基本执行单元 - 在您创建或部署的 Kubernetes 对象模型中最小和最简单的单元。Pod 表示集群中运行的进程。

Pod 封装了一个应用程序的容器（或在某些情况下为多个容器），存储资源，唯一的网络标识（IP 地址）以及管理容器容器如何运行的选项。Pod 表示部署的单元：Kubernetes 中应用程序的单个实例，可能由单个容器或紧密耦合并共享资源的少量容器组成。

Kubernetes 集群中的 Pod 可以通过两种主要方式使用：

- 运行单个容器的 Pod：”one-container-per-Pod“ 模型是最常见的 Kubernetes 用例。在这种情况下，您可以将 Pod 视为单个容器的包装，而 Kubernetes 则直接管理 Pod，而不是直接管理容器。
- 运行多个需要协同工作的容器的 Pod：Pod 可能封装了一个应用程序，该应用程序由紧密耦合且需要共享资源的多个并置容器组成。这些并置的容器可能形成一个内聚的服务单元 - 一个容器将文件从共享卷提供给公众，而一个单独的”sidecar“容器则刷新或更新这些文件。Pod 将这些容器和存储资源包装在一起，成为一个可管理的实体。

每个 Pod 旨在运行给定应用程序的单个实例。如果要水平扩展应用程序（通过运行更多实例来提供更多整体资源），则应使用多个 Pod，每个实例一个。在 Kubernetes 中，这通常称为复制 replication。复制的 Pods 通常作为一个组被 workload 资源及其 `_controller_`  创建和管理。

### Pods 如何管理多个容器

Pod 被设计为支持多个协作进程（即容器）组成一个内聚的服务单元。Pod 中的容器会自动地共同放置和调度到集群中的同一物理或虚拟机上。这些容器可以共享资源和依赖项，彼此通信，并协调何时以及如何终止他们。

请注意，在单个 Pod 中对多个共同放置和管理的容器进行分组是一个相对高级的用例。您仅应在容器紧密耦合的特定实例中使用此模式。例如，您可能有一个容器充当共享卷中文件的 Web 服务器，以及一个单独的”sidecar“容器从远程源更新这些文件，如下图所示：

![pod](https://d33wubrfki0l68.cloudfront.net/aecab1f649bc640ebef1f05581bfcc91a48038c4/728d6/images/docs/pod.svg)

有些 Pod 具有 init 容器和 app 容器。init 容器在 app 容器启动前运行并完成。

Pod 为其组成的容器提供两种共享资源：networking 和 storage。

#### Networking

每个 Pod 为每个地址族分配一个唯一的 IP 地址。Pod 中的每个容器都共享这个网络名称空间，包括 IP 地址和网络端口。在同一个 Pod 中的容器可以使用 `localhost` 相互通信。当 Pod 中的容器与 Pod 外部的实体进行通信时，它们必须协调如何使用共享的网络资源（例如端口）。

#### Storage

一个 Pod 可以指定一组共享存储卷。这个 Pod 中的所有容器都可以访问共享卷，从而使这些容器可以共享数据。Volumes 还允许 Pod 中的持久化数据保存下来，以防其中的容器之一需要重新启动。

## Working with Pods

您很少会直接在 Kubernetes 中创建单个 Pod -- 甚至是单身 Pod。这是因为 Pod 被设计为相对短暂的一次性的实体。当一个 Pod 被创建时（直接由您创建，或者由 _controller_ 间接创建），它将被安排在集群中的 Node 上运行。Pod 会保留在该节点上，直到进程终止，Pod 对象被删除，Pod 由于缺少资源而被驱逐，或节点发生故障为止。

> 说明：不要将重新启动 Pod 中的容器与重新启动 Pod 混淆。Pod 不是进程，而是用于运行容器的环境。Pod 会一直存在直到被删除。

Pod 本身无法自我修复。如果 Pod 被调度到发生故障的节点，或者调度操作本身失败，Pod 将被删除。同样，由于缺乏资源或 Node 维护，Pod 无法幸免。Kubernetes 使用称为控制器的更高级的抽象来处理管理相对一次性的 Pod 实例的工作。因此，虽然可以直接使用 Pod，但在 Kubernetes 中使用控制器来管理 Pod 更为常见。

### Pods and controllers

您可以使用工作负载资源为您创建和管理多个 Pod。资源的控制器处理 Pod 失败时的复制和回滚以及自动修复。例如，如果某个节点发生故障，则控制器会注意到该节点上的 Pod 已停止工作，并创建了一个替换 Pod。调度程序将替换的 Pod 放置到健康的节点上。

以下是管理一个或多个 Pod 的工作负载资源的一些示例：

- Deployment
- StatefulSet
- DaemonSet

## Pod templates

工作负载资源的控制器从 Pod 模板创建 Pod，并代表您管理这些 Pod。 PodTemplates 是用于创建 Pod 的规范，并且包含在工作负载资源（如 Deployments，Jobs 和 DaemonSets）中。

工作负载资源的每个控制器都使用工作负载对象内部的 PodTemplate 来创建实际的 Pod。PodTemplate 是用于运行应用程序的任何工作负载资源的期望状态的一部分。

下面的示例是一个简单的 Job 的清单，带有一个启动一个容器的 `template`。该 Pod 中的容器会打印一条消息，然后暂停。

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello
spec:
  template:
    # This is the pod template
    spec:
      containers:
      - name: hello
        image: busybox
        command: ['sh', '-c', 'echo "Hello, Kubernetes!" && sleep 3600']
      restartPolicy: OnFailure
    # The pod template ends here
```

修改 pod 模板或切换到新的 pod 模板对已存在的 Pod 无效。 Pod 不会直接接收模板更新。而是创建一个新的 Pod 以匹配修订后的 Pod 模板。

例如，Deployment 控制器可确保正在运行的 Pod 与当前 Pod 模板匹配。如果模板已更新，则控制器必须删除现有的 Pod 并根据更新的模板创建新的 Pod。每个工作负载控制器都实现自己的规则，以处理 Pod 模板的更改。

在节点上，kubelet 不会直接观察或管理有关 pod 模板和更新的任何详细信息。这些细节被抽象掉了。关注点的抽象和分离简化了系统语义，并使得在不更改现有代码的情况下扩展集群的行为变得可行。

 