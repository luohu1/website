# Pods

_Pod_ 是可以在 Kubernetes 中创建和管理的最小的可部署计算单元。

## What is a Pod?

_Pod_（就像在鲸鱼荚或者豌豆荚中）是一组（一个或多个）容器（例如 Docker 容器），这些容器具有共享的存储/网络，以及有关如何运行容器的规范。Pod 的内容总是并置（co-located）的并且一同调度，在共享上下文中运行。Pod 所建模的是特定于应用的“逻辑主机”，其中包含一个或多个相对紧密耦合的应用容器 — 在容器出现之前，在相同的物理机或虚拟机上运行意味着在相同的逻辑主机上运行。

虽然 Kubernetes 支持多种容器运行时，但 Docker 是最常见的一种运行时，它有助于使用 Docker 术语来描述 Pod。

Pod 的共享上下文是一组 Linux 命名空间、cgroups、以及其他潜在的资源隔离相关的因素，这些相同的东西也隔离了 Docker 容器。在 Pod 的上下文中，单个应用程序可能还会应用进一步的子隔离。

Pod 中的所有容器共享一个 IP 地址和端口空间，并且可以通过 `localhost` 互相发现。他们也能通过标准的进程间通信（如 SystemV 信号量或 POSIX 共享内存）方式进行互相通信。不同 Pod 中的容器的 IP 地址互不相同，没有 [特殊配置](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) 就不能使用 IPC 进行通信。这些容器之间经常通过 Pod IP 地址进行通信。

Pod 中的应用也能访问共享 [卷](https://kubernetes.io/docs/concepts/storage/volumes/)，共享卷是 Pod 定义的一部分，可被用来挂载到每个应用的文件系统上。

在 [Docker](https://www.docker.com/) 体系的术语中，Pod 被建模为一组具有共享命名空间和共享文件系统[卷](https://kubernetes.io/docs/concepts/storage/volumes/) 的 Docker 容器。

与单个应用程序容器一样，Pod 被认为是相对短暂的（而不是持久的）实体。如 [Pod 的生命周期](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/) 所讨论的那样：Pod 被创建、给它指定一个唯一 ID（UID）、被调度到节点、在节点上存续直到终止（取决于重启策略）或被删除。如果 [节点](https://kubernetes.io/docs/concepts/architecture/nodes/) 宕机，调度到该节点上的 Pod 会在一个超时周期后被安排删除。给定 Pod （由 UID 定义）不会重新调度到新节点；相反，它会被一个完全相同的 Pod 替换掉，如果需要甚至连 Pod 名称都可以一样，除了 UID 是新的(更多信息请查阅 [副本控制器（replication controller）](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/)）。

当某些东西被说成与 Pod（如卷）具有相同的生命周期时，这表明只要 Pod（具有该 UID）存在，它就存在。如果出于任何原因删除了该 Pod，即使创建了相同的 Pod，相关的内容（例如卷）也会被销毁并重新创建。

![pod](https://d33wubrfki0l68.cloudfront.net/aecab1f649bc640ebef1f05581bfcc91a48038c4/728d6/images/docs/pod.svg)

*一个多容器 Pod，其中包含一个文件拉取器和一个 Web 服务器，该 Web 服务器使用持久卷在容器之间共享存储*

## 设计 Pod 的目的

### 管理

Pod 是形成内聚服务单元的多个协作过程模式的模型。它们提供了一个比它们的应用组成集合更高级的抽象，从而简化了应用的部署和管理。Pod 可以用作部署、水平扩展和制作副本的最小单元。在 Pod 中，系统自动处理多个容器的在并置运行（协同调度）、生命期共享（例如，终止），协同复制、资源共享和依赖项管理。

### 资源共享和通信

Pod 使它的组成容器间能够进行数据共享和通信。

Pod 中的应用都使用相同的网络命名空间（相同 IP 和 端口空间），而且能够互相“发现”并使用 `localhost` 进行通信。因此，在 Pod 中的应用必须协调它们的端口使用情况。每个 Pod 在扁平的共享网络空间中具有一个 IP 地址，该空间通过网络与其他物理计算机和 Pod 进行全面通信。

Pod 中的容器获取的系统主机名与为 Pod 配置的 `name` 相同。[网络](https://kubernetes.io/docs/concepts/cluster-administration/networking/) 部分提供了更多有关此内容的信息。

Pod 除了定义了 Pod 中运行的应用程序容器之外，Pod 还指定了一组共享存储卷。该共享存储卷能使数据在容器重新启动后继续保留，并能在 Pod 内的应用程序之间共享。

## 使用 Pod

Pod 可以用于托管垂直集成的应用程序栈（例如，LAMP），但最主要的目的是支持位于同一位置的、共同管理的工具程序，例如：

- 内容管理系统、文件和数据加载器、本地缓存管理器等。
- 日志和检查点备份、压缩、旋转、快照等。
- 数据更改监视器、日志跟踪器、日志和监视适配器、事件发布器等。
- 代理、桥接器和适配器
- 控制器、管理器、配置器和更新器

通常，不会用单个 Pod 来运行同一应用程序的多个实例。

有关详细说明，请参考 [分布式系统工具包：组合容器的模式](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns)。

## 可考虑的备选方案

*为什么不在单个（Docker）容器中运行多个程序？*

1. 透明度。Pod 内的容器对基础设施可见，使得基础设施能够向这些容器提供服务，例如进程管理和资源监控。这为用户提供了许多便利。
2. 解耦软件依赖关系。可以独立地对单个容器进行版本控制、重新构建和重新部署。Kubernetes 有一天甚至可能支持单个容器的实时更新。
3. 易用性。用户不需要运行他们自己的进程管理器、也不用担心信号和退出代码传播等。
4. 效率。因为基础结构承担了更多的责任，所以容器可以变得更加轻量化。

*为什么不支持基于亲和性的容器协同调度？*

这种处理方法尽管可以提供同址，但不能提供 Pod 的大部分好处，如资源共享、IPC、有保证的命运共享和简化的管理

## Pod 的持久性（或稀缺性）

不得将 Pod 视为持久实体。它们无法在调度失败、节点故障或其他驱逐策略（例如由于缺乏资源或在节点维护的情况下）中生存。

一般来说，用户不需要直接创建 Pod。他们几乎都是使用控制器进行创建，即使对于单例的 Pod 创建也一样使用控制器，例如 [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)。控制器提供集群范围的自修复以及副本数和滚动管理。像 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset.md) 这样的控制器还可以提供支持有状态的 Pod。

在集群调度系统中，使用 API 合集作为面向用户的主要原语是比较常见的，包括 [Borg](https://research.google.com/pubs/pub43438.html)、[Marathon](https://mesosphere.github.io/marathon/docs/rest-api.html)、[Aurora](http://aurora.apache.org/documentation/latest/reference/configuration/#job-schema)、和 [Tupperware](https://www.slideshare.net/Docker/aravindnarayanan-facebook140613153626phpapp02-37588997)。

Pod 暴露为原语是为了便于：

- 调度器和控制器可插拔性
- 支持 Pod 级别的操作，而不需要通过控制器 API "代理" 它们
- Pod 生命与控制器生命的解耦，如自举
- 控制器和服务的解耦 — 端点控制器只监视 Pod
- kubelet 级别的功能与集群级别功能的清晰组合 — kubelet 实际上是 "Pod 控制器"
- 高可用性应用程序期望在 Pod 终止之前并且肯定要在 Pod 被删除之前替换 Pod，例如在计划驱逐或镜像预先拉取的情况下。

## Pod 的终止

因为 Pod 代表在集群中的节点上运行的进程，所以当不再需要这些进程时（与被 KILL 信号粗暴地杀死并且没有机会清理相比），允许这些进程优雅地终止是非常重要的。 用户应该能够请求删除并且知道进程何时终止，但是也能够确保删除最终完成。当用户请求删除 Pod 时，系统会记录在允许强制删除 Pod 之前所期望的宽限期，并向每个容器中的主进程发送 TERM 信号。一旦过了宽限期，KILL 信号就发送到这些进程，然后就从 API 服务器上删除 Pod。如果 Kubelet 或容器管理器在等待进程终止时发生重启，则终止操作将以完整的宽限期进行重试。

流程示例：

1. 用户发送命令删除 Pod，使用的是默认的宽限期（30秒）
2. API 服务器中的 Pod 会随着宽限期规定的时间进行更新，过了这个时间 Pod 就会被认为已 "死亡"。
3. 当使用客户端命令查询 Pod 状态时，Pod 显示为 "Terminating"。
4. （和第 3 步同步进行）当 Kubelet 看到 Pod 由于步骤 2 中设置的时间而被标记为 terminating 状态时，它就开始执行关闭 Pod 流程。
   1. 如果 Pod 的容器之一定义了 [preStop 钩子](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-details)，就在容器内部调用它。如果宽限期结束了，但是 `preStop` 钩子还在运行，那么就用小的（2 秒）扩展宽限期调用步骤 2。
   2. 给 Pod 内的容器发送 TERM 信号。请注意，并不是所有 Pod 中的容器都会同时收到 TERM 信号，如果它们关闭的顺序很重要，则每个容器可能都需要一个 `preStop` 钩子。
5. （和第 3 步同步进行）从服务的端点列表中删除 Pod，Pod 也不再被视为副本控制器的运行状态的 Pod 集的一部分。因为负载均衡器（如服务代理）会将其从轮换中删除，所以缓慢关闭的 Pod 无法继续为流量提供服务。
6. 当宽限期到期时，仍在 Pod 中运行的所有进程都会被 SIGKILL 信号杀死。
7. kubelet 将通过设置宽限期为 0 （立即删除）来完成在 API 服务器上删除 Pod 的操作。该 Pod 从 API 服务器中消失，并且在客户端中不再可见。

默认情况下，所有删除操作宽限期是 30 秒。`kubectl delete` 命令支持 `--grace-period=<seconds>` 选项，允许用户覆盖默认值并声明他们自己的宽限期。设置为 `0` 会[强制删除](https://kubernetes.io/docs/concepts/workloads/pods/pod/#force-deletion-of-pods) Pod。您必须指定一个附加标志 `--force` 和 `--grace-period=0` 才能执行强制删除操作。

### Pod 的强制删除

强制删除 Pod 被定义为从集群状态与 etcd 中立即删除 Pod。当执行强制删除时，API 服务器并不会等待 kubelet 的确认信息，该 Pod 已在所运行的节点上被终止了。强制执行删除操作会从 API 服务器中立即清除 Pod， 因此可以用相同的名称创建一个新的 Pod。在节点上，设置为立即终止的 Pod 还是会在被强制删除前设置一个小的宽限期。

强制删除对某些 Pod 可能具有潜在危险，因此应该谨慎地执行。对于 StatefulSet 管理的 Pod，请参考 [从 StatefulSet 中删除 Pod](https://kubernetes.io/docs/tasks/run-application/force-delete-stateful-set-pod/) 的任务文档。

## Pod 容器的特权模式

Pod 中的任何容器都可以使用容器规范 [security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) 上的 `privileged` 参数启用特权模式。这对于想要使用 Linux 功能（如操纵网络堆栈和访问设备）的容器很有用。容器内的进程几乎可以获得与容器外的进程相同的特权。使用特权模式，将网络和卷插件编写为不需要编译到 kubelet 中的独立的 Pod 应该更容易。

> **说明：** 您的容器运行时必须支持特权容器模式才能使用此设置。

## API 对象

Pod 是 Kubernetes REST API 中的顶级资源。 [Pod API 对象](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#pod-v1-core)定义详细描述了该 Pod 对象。为 Pod 对象创建清单时，请确保指定的名称是有效的 [DNS 子域名](https://kubernetes.io/docs/concepts/overview/working-with-objects/names#dns-subdomain-names)。

