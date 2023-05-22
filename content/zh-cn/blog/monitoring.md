---
title: "Monitoring"
description: ""
date: 2022-06-22T16:22:17+08:00
author: LuoHui
---



## 运行环境

- CentOS 7.9.2009
- Docker 19.03.15



## 命令片段

运行环境

```shell
docker run -it -d --privileged --name monitoring centos:7 /usr/sbin/init
docker exec -it monitoring bash
yum install -y bash-completion git vim-enhanced curl wget
```



```
mkdir /data

wget https://objects.githubusercontent.com/github-production-release-asset-2e65be/6838921/85b84831-f125-4491-bf9b-5928b5edae01?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20220622%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20220622T083108Z&X-Amz-Expires=300&X-Amz-Signature=272353bb4e9e85227018b4cbb4511b36a4767948e5fe5d894bce2cb59d15cafd&X-Amz-SignedHeaders=host&actor_id=15220555&key_id=0&repo_id=6838921&response-content-disposition=attachment%3B%20filename%3Dprometheus-2.36.2.linux-amd64.tar.gz&response-content-type=application%2Foctet-stream

https://github.com/prometheus/prometheus/releases/download/v2.36.2/prometheus-2.36.2.linux-amd64.tar.gz
```

