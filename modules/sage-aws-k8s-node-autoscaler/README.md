# Purpose
This module is responsible for deploying out an integration with Spot io to handle the
needs of scaling the nodes on the kubernetes cluster up and down. It installs a cluster
controller that watches the KubeAPI for changes and increases/decreases nodes based on
changes. It also deploys a metric collector to watch for resource usage on the nodes.

Further reading:
- <https://spot.io/blog/enhanced-spot-ocean-controller/>