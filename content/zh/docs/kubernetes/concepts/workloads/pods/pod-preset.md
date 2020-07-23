---
title: "Pod Preset"
date: 2020-07-23T16:43:26+08:00
weight: 11415
---

**功能状态：**`Kubernetes v1.6 [alpha]`

本文提供了 PodPreset 的概述。在 Pod 创建时，用户可以使用 PodPreset 对象将特定信息注入 Pod 中，这些信息可以包括 secret、卷、卷挂载和环境变量。

## 理解 Pod Preset

`Pod Preset` 是一种 API 资源，在 Pod 创建时，用户可以用它将额外的运行时需求信息注入 Pod。 使用[标签选择器（label selector）](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)来指定 Pod Preset 所适用的 Pod。

使用 Pod Preset 使得 Pod 模板编写者不必显式地为每个 Pod 设置所有信息。这样，使用特定服务的 Pod 模板编写者不需要了解该服务的所有细节。

了解更多的相关背景信息，请参考 [PodPreset 设计提案](https://git.k8s.io/community/contributors/design-proposals/service-catalog/pod-preset.md)。

## 在集群中启用 PodPreset

为了在集群中使用 Pod Preset，您必须确保以下几点：

1. 您已启用 API `settings.k8s.io/v1alpha1/podpreset` 类型。例如，可以通过在 API Server 的 `--runtime-config` 选项中包含 `settings.k8s.io/v1alpha1=true` 来实现。在使用 minikube 的情况下，在启动集群时添加此标志 `--extra-config=apiserver.runtime-config=settings.k8s.io/v1alpha1=true`。

2. 您已启用 `PodPreset` 准入控制器。一种方法是将 `PodPreset` 包含在为 API Server 指定的 `--enable-admission-plugins` 选项值中。在使用 minikube 的情况下，在启动集群时添加此标志 `--extra-config=apiserver.enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,PodPreset`。


## PodPreset 如何工作

Kubernetes 提供了准入控制器（`PodPreset`），该控制器被启用时，会将 Pod Preset 应用于传入的 Pod 创建请求中。 当出现 Pod 创建请求时，系统会执行以下操作：

1. 检索所有可用 `PodPresets` 。
2. 检查 `PodPreset` 的标签选择器与要创建的 Pod 的标签是否匹配。
3. 尝试将 `PodPreset` 中定义的各种资源合并到正在创建的 Pod 中。
4. 发生错误时，抛出一个事件用来记录在 Pod 上的合并错误，同时在 *不注入* 任何来自 `PodPreset` 的资源的情况下创建 Pod。
5. 为修改后的 Pod spec 添加注解，来表明它已被 `PodPreset` 修改。注解的格式为： `podpreset.admission.kubernetes.io/podpreset-<pod-preset name>": "<resource version>"`。

每个 Pod 可以匹配零个或多个 Pod Preset；并且每个 `PodPreset` 可以应用于零个或多个 Pod。当 `PodPreset` 应用于一个或多个 Pod 时，Kubernetes 会修改 Pod Spec。对于 `Env`、`EnvFrom` 和 `VolumeMounts` 的改动，Kubernetes 修改 Pod 中所有容器的规格；对于 `Volume` 的改动，Kubernetes 修改 Pod Spec。

> **说明：** 适当时候，Pod Preset 可以修改 Pod Spec 中的以下字段： - `.spec.containers` 字段 - `initContainers` 字段（需要 Kubernetes 1.14.0 或更高版本）。

### 为特定 Pod 禁用 Pod Preset

在某些情况下，您希望 Pod 不受任何 Pod Preset 变动的影响。这时，您可以在  Pod Spec 中添加如下格式 `podpreset.admission.kubernetes.io/exclude: "true"` 的注解。

