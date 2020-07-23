---
title: "Kubernetes Components"
date: 2020-07-23T16:43:26+08:00
---

当你部署完 Kubernetes, 你就有了一个集群

Kubernetes 集群由一组工作机器组成, 这些工作机器称为节点 nodes, 运行容器化应用程序. 每个集群至少有一个工作节点.

工作节点托管 Pods. 控制平面管理集群中的工作节点和 Pods.

Kubernetes 集群示意图

![components-of-kubernetes](https://d33wubrfki0l68.cloudfront.net/7016517375d10c702489167e704dcb99e570df85/7bb53/images/docs/components-of-kubernetes.png)

## 控制平面组件(Control Plane Components)

控制平面组件可以运行在集群中的任何机器上. 然而, 为了简单, 设置脚本通常在同一台计算机上启动所有控制平面组件, 并且不在该计算机上运行用户容器.

### kube-apiserver

暴露 Kubernetes API

### etcd

所有集群数据的后端存储

### kube-scheduler

监视新创建的还没有分配节点的Pod, 并选择一个节点使其运行

调度决策要考虑的因素包括: 个人和集体资源需求, 硬件/软件/策略约束, 亲和力和反亲和力规范, 数据局限性, 工作负载之间的干扰以及期限.

### kube-controller-manager

运行控制器进程的控制平面组件

从逻辑上讲, 每个控制器是一个单独的进程, 但是为了降低复杂性, 它们都被编译为单个二进制文件并在单个进程中运行.

- Node 控制器: 负责节点发生故障时的通知和响应
- Replication 控制器: 负责为系统中的每个 replication 控制器对象维护正确数量的 Pods
- Endpoints 控制器: 填充 Endpoints 对象(加入 Services & Pods)
- Service Account & Token 控制器: 为新的名称空间创建默认账户和API访问令牌

### cloud-controller-manager 

## Node Components

### kubelet

kubelet 获取一组 PodSpecs, 并确保这些 PodSpecs 中描述的容器是运行中和健康的

### kube-proxy

kube-proxy 维护节点上的网络规则. 这些网络规则允许从集群内部或外部的网络会话于 Pod 进行网络通信

如果有一个操作系统数据包过滤层可用, kube-proxy 使用操作系统数据包过滤层, 否则, kube-proxy 自己转发流量.

### Container runtime

Docker, containerd, CRI-O, 和 Kubernetes CRI 的任何实现

## 插件(Addons)

插件使用 Kubernetes 资源实现集群功能. 因为它们提供集群级别的功能, 所以插件的命名空间资源属于`kube-system` 命名空间

可用插件的扩展列表, 请参见[插件(Addons)](https://kubernetes.io/docs/concepts/cluster-administration/addons/)

### DNS

为 Kubernetes 服务提供 DNS 记录

### Web UI (Dashboard)

Dashboard 是 Kubernetes 集群的通用基于 Web 的 UI. 它使用户可以管理集群中运行的应用程序以及集群本身并进行故障排除.

### Containner Resource Monitoring

容器资源监控将关于容器的一些常见的时间序列度量值保存到一个集中的数据库中, 并提供用于浏览这些数据的界面

### Cluster-level Logging

 集群层面日志机制负责将容器的日志数据保存到一个集中的日志存储中, 该存储能够提供搜索和浏览接口.