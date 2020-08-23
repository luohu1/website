---
title: "What is Envoy"
data: 2020-08-14T12:40:28+08:00
weight: 1
---

Envoy 是 L7 代理和通信总线，专为面向大型现代服务的体系结构而设计。该项目是基于以下信念而诞生的：

> 网络对应用程序应该是透明的。当确实发生网络和应用程序问题时，应该容易确定问题的根源。

实际上，实现上述目标非常困难。 Envoy 尝试通过提供以下高级功能来做到这一点：

**进程外架构：**Envoy 是一个自包含的进程，被设计为与每个应用程序服务器一起运行。所有的 Envoy 组成一个透明的通信网格，每个应用程序在其中都与 localhost 之间发送和接收消息，并且不知道网络拓扑。与传统的库实现服务到服务通信方法相比，进程外架构具有两个实质性的好处：

- Envoy 可与任何应用程序语言一起工作。单个 Envoy 部署可以在 Java、C ++、Go、PHP、Python 等之间形成网格。面向服务的架构（SOA）使用多种应用程序框架和语言变得越来越普遍。Envoy 透明地弥合了其中的差距。
- 任何使用大型面向服务的架构的人都知道，部署库升级可能会非常痛苦。Envoy 可以透明地在整个基础架构中快速部署和升级。

**Modern C++11 code base:** Envoy 用 C++11 编写。选择原生代码是因为我们认为应尽可能避免使用 Envoy 之类的架构组件。现代应用开发人员已经处理了因共享云环境中的部署而难以推理的尾部延迟，以及使用效率很高但性能不是很好的语言，例如 PHP、Python、Ruby、Scala 等。原生代码通常提供出色的延迟属性，不会给已经令人困惑的情况带来额外的混乱。与其他用 C 编写的原生代码代理解决方案不同，C++11 提供了出色的开发人员生产力和性能。

**L3/L4 过滤器架构：**Envoy 的核心是 L3/L4网络代理。可插拔的 [过滤器](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/listeners/network_filters#arch-overview-network-filters) 链机制允许写入过滤器以执行不同的 TCP 代理任务，并将其插入主服务器。已经写好了过滤器来支持各种任务，例如原始 [TCP 代理](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/listeners/tcp_proxy#arch-overview-tcp-proxy)、[HTTP 代理](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_connection_management#arch-overview-http-conn-man)、[TLS 客户端证书认证](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ssl#arch-overview-ssl-auth-filter)等。

**HTTP L7 过滤器架构：** HTTP 是现代应用架构的关键组件，Envoy [支持](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_filters#arch-overview-http-filters)额外的 HTTP L7 过滤器层。HTTP 过滤器可以插入 HTTP 连接管理子系统中，该子系统执行不同的任务，例如[缓冲](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/buffer_filter#config-http-filters-buffer)、[速率限制](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting#arch-overview-global-rate-limit)、[路由/转发](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_routing#arch-overview-http-routing)、嗅探 Amazon 的 [DynamoDB](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_protocols/dynamo#arch-overview-dynamo) 等。

**一流的 HTTP/2 支持：**在 HTTP 模式下运行时，Envoy 支持 HTTP/1.1 和 HTTP/2。Envoy 可以在两个方向上充当透明的 HTTP/1.1 到 HTTP/2 代理。这意味着可以桥接 HTTP/1.1 和 HTTP/2 客户端与目标服务器的任何组合。推荐的服务到服务配置是在所有 Envoy 之间使用 HTTP/2 来创建持久连接的网格，该请求和响应可以多路复用。由于 SPDY 协议正在逐步淘汰，Envoy 不支持 SPDY。

**HTTP L7 路由：**在 HTTP 模式下运行时，Envoy 支持[路由](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_routing#arch-overview-http-routing)子系统，该子系统能够基于路径、权限、内容类型、[运行时](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/runtime#arch-overview-runtime)值等来路由和重定向请求。当使用 Envoy 作为前端/边缘代理时，此功能最有用，但在构建服务到服务网格的服务时也可以利用此功能。

**gRPC 支持：**[gRPC](https://www.grpc.io/) 是 Google 的 RPC框架，使用 HTTP/2 作为基础的多路复用传输。Envoy [支持](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_protocols/grpc#arch-overview-grpc)所有 HTTP/2 功能，这些功能必须用作 gRPC 请求和响应的路由和负载平衡基础。这两个系统是非常互补的。

**MongoDB L7 支持：**[MongoDB](https://www.mongodb.com/) 是在现代 Web 应用程序中使用的流行数据库。Envoy [支持](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_protocols/mongo#arch-overview-mongo) L7 嗅探，统计信息生成和 MongoDB 连接的日志记录。

**DynamoDB L7支持：**[DynamoDB](https://aws.amazon.com/dynamodb/) 是 Amazon 托管的键/值 NOSQL 数据存储。 Envoy [支持](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_protocols/dynamo#arch-overview-dynamo) DynamoDB 连接的 L7 嗅探和统计信息生成。

**服务发现和动态配置：**Envoy 可选地使用一组分层的[动态配置 API](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/dynamic_configuration#arch-overview-dynamic-config) 进行集中管理。这些层为 Envoy 提供有关以下方面的动态更新：后端集群中的主机，后端集群本身，HTTP 路由，侦听套接字和加密材料。对于更简单的部署，后端主机发现可以[通过 DNS 解析](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-types-strict-dns)（甚至[完全跳过](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-types-static)）来完成，而将其他层替换为静态配置文件。

**健康检查：**构建 Envoy 网格的[推荐](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/service_discovery#arch-overview-service-discovery-eventually-consistent)方法是将服务发现视为最终一致的过程。Envoy 包括[健康检查](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/health_checking#arch-overview-health-checking)子系统，该子系统可以有选择地对上游服务集群执行主动健康检查。然后，Envoy 使用服务发现和健康检查信息的结合来确定健康的负载均衡目标。Envoy 还通过[异常值检测](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/outlier#arch-overview-outlier-detection)子系统支持被动健康检查。

**高级负载均衡：**分布式系统中不同组件之间的[负载均衡](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/overview#arch-overview-load-balancing)是一个复杂的问题。因为 Envoy 是一个自包含的代理而不是一个库，所以它能够在一个地方实现高级负载均衡技术，并使任何应用程序都可以访问它们。目前，Envoy 包括对[自动重试](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_routing#arch-overview-http-routing-retry)、[断路](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking#arch-overview-circuit-break)、通过外部速率限制服务进行[全局速率限制](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting#arch-overview-global-rate-limit)、[请求屏蔽](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-routeaction-requestmirrorpolicy)和[异常检测](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/outlier#arch-overview-outlier-detection)的支持。计划为请求竞赛提供未来的支持。

**前端/边缘代理支持：**尽管 Envoy 最初主要被设计为服务到服务的通信系统，但在边缘使用相同的软件会有所帮助（可观察性，管理，相同的服务发现和负载平衡算法等）。Envoy 包含足够的功能，使其可以用作大多数现代 Web 应用程序用例的边缘代理。这包括 [TLS](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/ssl#arch-overview-ssl) 终止，HTTP/1.1 和 HTTP/2 [支持](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_connection_management#arch-overview-http-protocols)以及 HTTP L7 路由。

**一流的可观察性：**如上所述，Envoy 的主要目标是使网络透明。但是，在网络级别和应用程序级别都会发生问题。 Envoy 包括对所有子系统的强大的[统计](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/statistics#arch-overview-statistics)支持。[statsd](https://github.com/etsy/statsd)（和兼容的提供程序）是当前受支持的统计接收器，尽管插入另一个并不困难。可以通过[管理](https://www.envoyproxy.io/docs/envoy/latest/operations/admin#operations-admin-interface)端口查看统计信息。 Envoy 还支持通过第三方提供商进行分布式跟踪。

## 设计目标

关于代码本身的设计目标的简短说明：尽管Envoy绝不慢（我们花了很多时间来优化某些快速路径），但是代码的编写是模块化的，易于测试，而不是追求最大的绝对性能。我们认为，这是一种更有效的时间利用方式，因为典型的部署将与语言和运行时同时出现，速度降低许多倍，而内存使用却增加许多倍。

