---
title: "Log Pilot"
date: 2022-06-13T17:08:53+08:00
---

elastalert

dingtalk 插件开发

Python 3.8.10

```shell
gh repo clone luohu1/elastalert-dingtalk-plugin
code elastalert-dingtalk-plugin

cd elastalert-dingtalk-plugin
python3 -m venv --copies venv
source venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install "setuptools>=11.3"
python3 -m pip install "elasticsearch>=5.0.0"
python3 -m pip install "elastalert==0.2.4"
pip freeze > requirements.txt

mkdir elastalert_modules
cd elastalert_modules
touch __init__.py
touch my_alerts.py

# k8s 启动 elasticsearch&kibana
$ kubectl port-forward svc/elasticsearch 9200:9200
$ kubectl port-forward svc/kibana 15601:5601

$ elastalert-create-index
Elastic Version: 7.7.1
Reading Elastic 6 index mappings:
Reading index mapping 'es_mappings/6/silence.json'
Reading index mapping 'es_mappings/6/elastalert_status.json'
Reading index mapping 'es_mappings/6/elastalert.json'
Reading index mapping 'es_mappings/6/past_elastalert.json'
Reading index mapping 'es_mappings/6/elastalert_error.json'
New index elastalert_status created
Done!

$ elastalert-test-rule --config <path-to-config-file> example_rules/example_frequency.yaml

$ python -m elastalert.elastalert --verbose
0 rules loaded
INFO:elastalert:Starting up
INFO:elastalert:Disabled rules are: []
INFO:elastalert:Sleeping for 59.999748 seconds

# 开发 DingtalkAlerter 代码
```



Dockerfile

```
docker run -it -d --name es alpine:3.14
```





```shell
$ kubectl exec -it -n monitoring elastalert-68cdf7fdc7-tjbvm -- sh
```

alpine 1.14 内置 python 3.9 elastalert 不兼容



查询索引列表

## 示例文件

使用 configmap

```
kubectl create configmap elastalert-config --from-file=config.yaml
```

elasticsearch deploy.yaml

```shell
kubectl port-forward svc/elasticsearch 9200:9200
kubectl port-forward svc/kibana 15601:5601
```

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  labels:
    app: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
        - name: elasticsearch
          image: elasticsearch:7.7.1
          ports:
            - containerPort: 9200
          env:
            - name: "discovery.type"
              value: "single-node"
            - name: "bootstrap.memory_lock"
              value: "true"
          resources: {}
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
spec:
  type: ClusterIP
  ports:
    - port: 9200
      protocol: TCP
      name: http
      targetPort: 9200
  selector:
    app: elasticsearch
```

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  labels:
    app: kibana
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      automountServiceAccountToken: true
      securityContext:
        fsGroup: 1000
      containers:
        - name: kibana
          securityContext:
            capabilities:
              drop:
                - ALL
            runAsNonRoot: true
            runAsUser: 1000
          image: "kibana:7.7.1"
          imagePullPolicy: "IfNotPresent"
          env:
            - name: ELASTICSEARCH_HOSTS
              value: "http://elasticsearch:9200"
            - name: SERVER_HOST
              value: "0.0.0.0"
            - name: NODE_OPTIONS
              value: --max-old-space-size=1800
          ports:
            - containerPort: 5601
          resources:
            limits:
              cpu: 1000m
              memory: 2Gi
            requests:
              cpu: 1000m
              memory: 2Gi
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
spec:
  type: ClusterIP
  ports:
    - port: 5601
      protocol: TCP
      name: http
      targetPort: 5601
  selector:
    app: kibana
```



## 参考链接

- https://github.com/Yelp/elastalert.git
- https://elastalert.readthedocs.io/en/latest/
- https://github.com/xuyaoqiang/elastalert-dingtalk-plugin.git
- https://zhuanlan.zhihu.com/p/386722918
- https://open.dingtalk.com/document/robots/custom-robot-access