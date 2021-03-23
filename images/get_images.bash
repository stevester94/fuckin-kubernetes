#! /usr/bin/bash
docker pull k8s.gcr.io/kube-proxy:v1.20.5
docker pull k8s.gcr.io/kube-scheduler:v1.20.5
docker pull k8s.gcr.io/kube-apiserver:v1.20.5
docker pull k8s.gcr.io/kube-controller-manager:v1.20.5
docker pull weaveworks/weave-npc:2.8.1
docker pull weaveworks/weave-kube:2.8.1
docker pull k8s.gcr.io/etcd:3.4.13-0
docker pull k8s.gcr.io/coredns:1.7.0
docker pull k8s.gcr.io/pause:3.2

docker save k8s.gcr.io/kube-proxy:v1.20.5               > kube-proxy:v1.20.5.cimage
docker save k8s.gcr.io/kube-scheduler:v1.20.5           > kube-scheduler:v1.20.5.cimage
docker save k8s.gcr.io/kube-apiserver:v1.20.5           > kube-apiserver:v1.20.5.cimage
docker save k8s.gcr.io/kube-controller-manager:v1.20.5  > kube-controller-manager:v1.20.5.cimage
docker save k8s.gcr.io/etcd:3.4.13-0                    > etcd:3.4.13-0.cimage
docker save k8s.gcr.io/coredns:1.7.0                    > coredns:1.7.0.cimage
docker save k8s.gcr.io/pause:3.2                        > pause:3.2.cimage
docker save weaveworks/weave-npc:2.8.1                  > weave-npc:2.8.1.cimage
docker save weaveworks/weave-kube:2.8.1                 > weave-kube:2.8.1.cimage
