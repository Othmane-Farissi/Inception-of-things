# Inception of Things

## Overview
The Inception of Things project is focused on learning and implementing Kubernetes and K3s concepts. This project aims to provide a comprehensive understanding of container orchestration using Kubernetes, specifically optimized for lightweight environments with K3s.

## Introduction
This repository serves as a learning platform for Kubernetes and K3s. K3s is a lightweight Kubernetes distribution designed for resource-constrained environments. Through this project, users will learn how to deploy, manage, and scale applications in Kubernetes.

## Prerequisites
- Basic understanding of containers and Kubernetes concepts.
- A working installation of Docker.
- Access to a terminal or command-line interface.

## Installation
### 1. Install K3s following the official documentation:
   - Visit [K3s Installation Guide](https://rancher.com/docs/k3s/latest/en/)

### 2. Verify the installation:
```bash
   kubectl get nodes
```
## Usage
**To deploy an application:**

### Create a deployment:

```bash
kubectl create deployment my-app --image=my-app-image
```
**Expose the deployment:**

```bash
kubectl expose deployment my-app --type=LoadBalancer --port=80
```
Access the application via the service's external IP.

**Features**
- Easy installation and configuration of Kubernetes.
- Lightweight and highly available.
- Designed for resource-constrained devices.
