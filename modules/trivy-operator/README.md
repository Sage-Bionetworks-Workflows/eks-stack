# Purpose
This module is used to deploy the trivy operator k8s helm chart.

The Trivy Operator leverages Trivy to continuously scan your Kubernetes cluster for 
security issues. The scans are summarised in security reports as Kubernetes Custom 
Resource Definitions, which become accessible through the Kubernetes API. The Operator 
does this by watching Kubernetes for state changes and automatically triggering 
security scans in response. For example, a vulnerability scan is initiated when a new 
Pod is created. This way, users can find and view the risks that relate to different 
resources in a Kubernetes-native way.


## Getting an overview of trivy results
Results are provided in a grafana dashbaord that is scraped from the operator `/metrics`
endpoint. The dashboard looks like:

![trivy operator dashboard](./trivy-operator-dashboard.png)


## Viewing the vulnerabilities
