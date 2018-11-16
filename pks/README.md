# PKS Pipelines

Pipelines to manage PKS.  

1) A pipeline to create PKS clusters.

## Create Cluster

Uses this image: [harbor.homeoffice.wal-mart.com/library/oskoss/pks](https://hub.docker.com/r/harbor.homeoffice.wal-mart.com/library/oskoss/pks/)

Uses these parameters:

- pks_api_url:
- pks_api_username:
- pks_api_password:
- pks_cluster_prefix: 
- pks_cluster_plan:
- pks_cluster_hostname: 
- github_private_key:

Creates PKS clusters in a sequential naming sequence.  Start with
*PKS_CLUSTER_PREFIX*_0, then *PKS_CLUSTER_PREFIX*_1 and so-on.  Host names are *PKS_CLUSTER_PREFIX*_0-*PKS_CLUSTER_HOSTNAME*

### Example


    pks_cluster_prefix: dev
    pks_cluster_hostname: cluster.pks.example.com

results in

    pks create-cluster dev_0 --external-hostname dev_0-cluster.pks.example.com 


## Authors

* **Peter Blum** - [Oskoss](https://github.com/Oskoss)
* **Clinton Masters** - [clintonmasters](https://github.com/clintonmasters)
* [Contributors](https://github.com/your/project/contributors)

## Acknowledgments

* **PCF Pipelines Team** - [pcf-pipelines](https://github.com/pivotal-cf/pcf-pipelines)
