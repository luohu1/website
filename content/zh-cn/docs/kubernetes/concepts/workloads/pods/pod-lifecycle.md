
---
title: "Pod Lifecycle"
date: 2020-07-23T16:43:26+08:00
weight: 11413
---

该页面将描述 Pod 的生命周期。

## Pod phase

Pod 的 `status` 定义在 [PodStatus](https://kubernetes.io/docs/resources-reference/v1.7/#podstatus-v1-core) 对象中，其中有一个 `phase` 字段。

Pod 的运行阶段（phase）是 Pod 在其生命周期中的简单宏观概述。该阶段并不是对容器或 Pod 的综合汇总，也不是为了做为综合状态机。

Pod 运行阶段值的数量和含义是严格指定的。除了本文档中列举的内容外，不应该再假定 Pod 有其他的 `phase` 值。

下面是 `phase` 可能的值：

- 挂起（Pending）：Pod 已被 Kubernetes 系统接受，但有一个或者多个容器镜像尚未创建。等待时间包括调度 Pod 的时间和通过网络下载镜像的时间，这可能需要花点时间。
- 运行中（Running）：该 Pod 已经绑定到了一个节点上，Pod 中所有的容器都已被创建。至少有一个容器正在运行，或者正处于启动或重启状态。
- 成功（Succeeded）：Pod 中的所有容器都被成功终止，并且不会再重启。
- 失败（Failed）：Pod 中的所有容器都已终止了，并且至少有一个容器是因为失败终止。也就是说，容器以非 0 状态退出或者被系统终止。
- 未知（Unknown）：因为某些原因无法取得 Pod 的状态，通常是因为与 Pod 所在主机通信失败。

## Pod conditions

Pod 有一个 PodStatus 对象，其中包含一个 [PodCondition](https://kubernetes.io/docs/resources-reference/v1.7/#podcondition-v1-core) 数组。 PodCondition 数组的每个元素都有六个可能的字段：

- `lastProbeTime` 字段提供最后一次探测 Pod condition 的时间戳。
- `lastTransitionTime` 字段提供 Pod 最后一次从一种状态过渡到另一种状态的时间戳。
- `message` 字段是人类可读的消息，指示有关过渡的详细信息。
- `reason` 字段是 condition 最后一次过渡的原因，该原因用唯一的、驼峰式的、一个词表示。
- `status` 字段是一个字符串，可能的值有 "`True`"、"`False`" 和 "`Unknown`"。
- `type` 字段是一个字符串，具有以下可能的值：
  - `PodScheduled`：已将Pod调度到一个节点；
  - `Ready`：该 Pod 能够处理请求，应将其添加到所有匹配服务的负载均衡池中；
  - `Initialized`：所有[初始化容器](https://kubernetes.io/docs/concepts/workloads/pods/init-containers)已成功启动；
  - `ContainersReady`：Pod 中的所有容器均已准备就绪。

## 容器探针

[探针](https://kubernetes.io/docs/resources-reference/v1.7/#probe-v1-core) 是由 [kubelet](https://kubernetes.io/docs/admin/kubelet/) 对容器执行的定期诊断。要执行诊断，kubelet 调用由容器实现的 [Handler](https://godoc.org/k8s.io/kubernetes/pkg/api/v1#Handler)。有三种类型的处理程序：

- [ExecAction](https://kubernetes.io/docs/resources-reference/v1.7/#execaction-v1-core)：在容器内执行指定命令。如果命令退出时状态码为 0 则认为诊断成功。
- [TCPSocketAction](https://kubernetes.io/docs/resources-reference/v1.7/#tcpsocketaction-v1-core)：对容器 IP 地址上指定的端口进行 TCP 检查。如果端口是开放的，则诊断被认为是成功的。
- [HTTPGetAction](https://kubernetes.io/docs/resources-reference/v1.7/#httpgetaction-v1-core)：对容器的 IP 地址上指定的端口和路径执行 HTTP Get 请求。如果响应的状态码大于等于200 且小于 400，则诊断被认为是成功的。

每次探测都将获得以下三种结果之一：

- 成功（Success）：容器通过了诊断。
- 失败（Failure）：容器未通过诊断。
- 未知（Unknown）：诊断失败，因此不会采取任何行动。

kubelet 可以选择对正在运行的 Container 进行三种探针的执行并对其做出反应：

- `livenessProbe`：指示容器是否正在运行。如果存活探测失败，则 kubelet 会杀死容器，并且容器将受到其 [重启策略](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restart-policy) 的影响。如果容器不提供存活探针，则默认状态为 `Success`。
- `readinessProbe`：指示容器是否准备好服务请求。如果就绪探测失败，端点控制器将从与 Pod 匹配的所有 Service 的端点中删除该 Pod 的 IP 地址。初始延迟之前的就绪状态默认为 `Failure`。如果容器不提供就绪探针，则默认状态为 `Success`。
- `startupProbe`: 指示容器中的应用是否已经启动。如果提供了启动探测（startup probe），则禁用所有其他探测，直到它成功为止。如果启动探测失败，kubelet 将杀死容器，容器服从其重启策略进行重启。如果容器没有提供启动探测，则默认状态为成功`Success`。

### 什么时候应该使用存活探针（livenessProbe）？

**功能状态：**`Kubernetes v1.0 [stable]`

如果容器中的进程能够在遇到问题或不健康的情况下能够自行崩溃，则不一定需要存活探针; kubelet 将根据 Pod 的`restartPolicy` 自动执行正确的操作。

如果您希望容器在探测失败时被杀死并重新启动，那么请指定一个存活探针，并指定`restartPolicy` 为 Always 或 OnFailure。

### 什么时候应该使用就绪探针（readinessProbe）？

**功能状态：**`Kubernetes v1.0 [stable]`

如果您希望仅在探测成功时才开始向 Pod 发送流量，请指定就绪探针。在这种情况下，就绪探针可能与存活探针相同，但是 spec 中的就绪探针的存在意味着 Pod 将在没有接收到任何流量的情况下启动，并且只有在探针探测成功后才开始接收流量。如果您的容器需要在启动过程中加载大型数据、配置文件或迁移，请指定就绪探针。

如果您希望容器能够自行维护，您可以指定一个就绪探针，该探针检查与存活探针不同的端点。

请注意，如果您只是想在 Pod 被删除后能够排除请求，则不一定需要使用就绪探针；在删除 Pod 后，无论就绪探针是否存在，Pod 都会自动将自身置于未就绪状态。当等待 Pod 中的容器停止时，Pod 仍处于未完成状态。

### 什么时候应该使用就绪探针（startupProbe）？

**功能状态：**`Kubernetes v1.16 [stable]`

如果您的容器通常在超过 `initialDelaySeconds + failureThreshold × periodSeconds` 的时间内启动，则应指定一个启动探针，该探针检查与存活探针相同的端点。`periodSeconds` 的默认值为 30s。然后，应将其 `failureThreshold` 设置得足够高，以允许 Container 启动，而不更改存活探针的默认值。这有助于防止死锁。

## Pod 和容器状态

有关 Pod 容器状态的详细信息，请参阅 [PodStatus](https://kubernetes.io/docs/resources-reference/v1.7/#podstatus-v1-core) 和 [ContainerStatus](https://kubernetes.io/docs/resources-reference/v1.7/#containerstatus-v1-core)。请注意，报告的 Pod 状态信息取决于当前的 [ContainerState](https://kubernetes.io/docs/resources-reference/v1.7/#containerstatus-v1-core)。

## 容器状态

一旦 Pod 被调度器分配到节点后，kubelet 将开始使用容器运行时来创建容器。容器有三种可能的状态：Waiting、Running 和 Terminated。您可以使用 `kubectl describe pod [POD_NAME]` 来检查容器的状态。Pod 中每个容器的状态将会被显示。

- `Waiting`: 容器的默认状态。如果容器未处于 Running 或 Terminated 状态，则处于 Waiting 状态。处于 Waiting 状态的容器仍会运行其所需的操作，例如拉取镜像，应用秘密等。关于该状态的消息和原因会伴随着该状态显示，以提供更多的信息。

  ```yaml
  ...
    State:          Waiting
     Reason:       ErrImagePull
  ...
  ```

- `Running`: 表示容器正在执行，没有问题。 `postStart` 钩子（如果有）在容器进入 Running 状态之前执行。此状态还显示容器进入 Running 状态的时间。

  ```yaml
  ...
     State:          Running
      Started:      Wed, 30 Jan 2019 16:46:38 +0530
  ...
  ```

- `Terminated`: 表示容器已完成其执行并已停止运行。当容器成功完成执行或由于某种原因失败时，容器就会进入该容器。无论如何，都会显示原因和退出代码，以及容器的开始和结束时间。在容器进入 Terminated 之前，执行 `preStop` 挂钩（如果有）。

  ```yaml
  ...
     State:          Terminated
       Reason:       Completed
       Exit Code:    0
       Started:      Wed, 30 Jan 2019 11:45:26 +0530
       Finished:     Wed, 30 Jan 2019 11:45:26 +0530
   ...
  ```

## Pod 就绪

**功能状态：**`Kubernetes v1.14 [stable]`

您的应用程序可以向 PodStatus 注入额外的反馈或信号：_Pod readiness_。要使用此功能，请在 PodSpec 中设置 `readinessGates` 以指定 kubelet 为 Pod 就绪评估的其他条件列表。

Readiness gates 由 Pod 的 `status.condition` 字段的当前状态决定。如果 Kubernetes 在 Pod 的 `status.conditions` 字段中找不到这样的条件，则该条件的状态默认为“`False`”。

这是一个例子：

```yaml
kind: Pod
...
spec:
  readinessGates:
    - conditionType: "www.example.com/feature-1"
status:
  conditions:
    - type: Ready                              # a built in PodCondition
      status: "False"
      lastProbeTime: null
      lastTransitionTime: 2018-01-01T00:00:00Z
    - type: "www.example.com/feature-1"        # an extra PodCondition
      status: "False"
      lastProbeTime: null
      lastTransitionTime: 2018-01-01T00:00:00Z
  containerStatuses:
    - containerID: docker://abcd...
      ready: true
...
```

您添加的 Pod 条件必须具有符合Kubernetes [label key format](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set) 的名称。

### Pod 就绪状态

`kubectl patch` 命令不支持修补对象状态。要为 Pod 设置这些 `status.conditions`，应用程序和 [操作员](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) 应使用 `PATCH` 操作。您可以使用 [Kubernetes client library](https://kubernetes.io/docs/reference/using-api/client-libraries/) 编写代码，来为 Pod 就绪设置自定义 Pod 条件。

对于使用自定义条件的 Pod，仅当以下两个声明均适用时，该 Pod 才被评估为就绪：

- Pod 中的所有容器均已准备就绪。
- `ReadinessGates` 中指定的所有条件均为 `True`。

当 Pod 的容器准备就绪但至少一个自定义条件是缺失的或 `False` 时，kubelet 将 Pod 的条件设置为 `ContainersReady`。

## 重启策略

PodSpec 中有一个 `restartPolicy` 字段，可能的值为 Always、OnFailure 和 Never。默认为 Always。 `restartPolicy` 适用于 Pod 中的所有容器。`restartPolicy` 仅指通过同一节点上的 kubelet 重新启动容器。失败的容器由 kubelet 以五分钟为上限的指数退避延迟（10秒，20秒，40秒...）重新启动，并在成功执行十分钟后重置。如 [Pod 文档](https://kubernetes.io/docs/user-guide/pods/#durability-of-pods-or-lack-thereof) 中所述，一旦绑定到一个节点，Pod 将永远不会重新绑定到另一个节点。

## Pod 的生命

一般来说，Pod 会一直保留，直到人为或 [控制器](https://kubernetes.io/docs/concepts/architecture/controller/) 进程明确地销毁他们。当 Pod 的数量超过配置的阈值（取决于 kube-controller-manager 中的 `terminate-pod-gc-threshold`）时，控制平面将清理终止的 Pod（阶段为成功或失败）。这样可以避免在创建和终止 Pod 时资源泄漏。

有多种创建Pod的资源：

- 对不希望终止的 Pod 使用 [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)、[ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) 或 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)，例如 Web 服务器。
- 对希望在工作完成后终止的 Pod 使用 [Job](https://kubernetes.io/docs/concepts/jobs/run-to-completion-finite-workloads/)，例如批量计算。Job 仅适用于 `restartPolicy` 为 `OnFailure` 或 `Never` 的 Pod。
- 对需要在每个合格节点上运行一个的 Pod 使用 [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)。

所有工作负载资源都包含一个 PodSpec。建议创建适当的工作负载资源，并让资源的控制器为您创建Pod，而不是自己直接创建Pods。

如果某个节点死亡或与集群的其余部分断开连接，则 Kubernetes 将应用一个策略将丢失节点上的所有 Pod 的 `phase` 设置为 Failed。

## 示例

### 高级 liveness 探针示例

存活探针由 kubelet 来执行，因此所有的请求都在 kubelet 的网络命名空间中进行。

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - args:
    - /server
    image: k8s.gcr.io/liveness
    livenessProbe:
      httpGet:
        # 当没有定义 "host" 时，使用 "PodIP"
        # host: my-host
        # 当没有定义 "scheme" 时，使用 "HTTP" scheme 只允许 "HTTP" 和 "HTTPS"
        # scheme: HTTPS
        path: /healthz
        port: 8080
        httpHeaders:
        - name: X-Custom-Header
          value: Awesome
      initialDelaySeconds: 15
      timeoutSeconds: 1
    name: liveness
```

### 状态示例

- Pod 中只有一个容器并且正在运行。容器成功退出。

  - 记录完成事件。

  - 如果 `restartPolicy` 为：

    - Always：重启容器；Pod `phase` 仍为 Running。
- OnFailure：Pod `phase` 变成 Succeeded。
    - Never：Pod `phase` 变成 Succeeded。
  
- Pod 中只有一个容器并且正在运行。容器退出失败。

  - 记录失败事件。

  - 如果 `restartPolicy` 为：

    - Always：重启容器；Pod `phase` 仍为 Running。
- OnFailure：重启容器；Pod `phase` 仍为 Running。
    - Never：Pod `phase` 变成 Failed。
  
- Pod 中有两个容器并且正在运行。容器 1 退出失败。

  - 记录失败事件。

  - 如果 `restartPolicy` 为：

    - Always：重启容器；Pod `phase` 仍为 Running。
    - OnFailure：重启容器；Pod `phase` 仍为 Running。
    - Never：不重启容器；Pod `phase` 仍为 Running。

  - 如果容器 1 没有处于运行状态，并且容器 2 退出：

    - 记录失败事件。

    - 如果 `restartPolicy` 为：

      - Always：重启容器；Pod `phase` 仍为 Running。
- OnFailure：重启容器；Pod `phase` 仍为 Running。
      - Never：Pod `phase` 变成 Failed。
  
- Pod 中只有一个容器并处于运行状态。容器运行时内存超出限制：

  - 容器以失败状态终止。

  - 记录 OOM 事件。

  - 如果 `restartPolicy` 为：

    - Always：重启容器；Pod `phase` 仍为 Running。
- OnFailure：重启容器；Pod `phase` 仍为 Running。
    - Never: 记录失败事件；Pod `phase` 变成 Failed。
  
- Pod 正在运行，磁盘故障：

  - 杀掉所有容器。
  - 记录适当事件。
  - Pod `phase` 变成 Failed。
  - 如果使用控制器来运行，Pod 将在别处重建。

- Pod 正在运行，其节点分段退出。

  - 节点控制器等待直到超时。
  - 节点控制器将 Pod `phase` 设置为 Failed。
  - 如果是用控制器来运行，Pod 将在别处重建。

