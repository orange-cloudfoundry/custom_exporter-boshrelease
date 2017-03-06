# WIP custom_exporter-boshrelease
A bosh release that implements custom_exporter. custom_exporter project can be found here : https://github.com/orange-cloudfoundry/custom_exporter

## Intro
This project is aimed to create a bosh job to implement prometheus custom exporter. Final goal is to implement this job inside prometheus bosh release

## Job configuration
* Use the release in your manifest :
```yaml
releases:
- name: custom_exporter-boshrelease
  version: latest
```
* Call the job in one or multipe instances :
```yaml
- instances: 1
  name: just_a_test
  networks:
  - name: network1
  persistent_disk: 0
  resource_pool: small
  templates:
  - name: custom_exporter
    release: custom_exporter-boshrelease
```

* Configure metric collection (complete documentation can be found here https://github.com/orange-cloudfoundry/custom_exporter/blob/master/README.md#manifest--result-examples) :
```yaml
custom_exporter:
  credentials:
  - name: mysql_connector
    type: mysql 
    dsn: mysql://monitoring:m0nit0ring4zew1n@127.0.0.1:3306/mysql_broker
  - name: shell_root
    type: bash
    user: root
  metrics:
  - name: node_database_size_bytes
    commands:
    - find /var/vcap/store/mysql/ -type d -name cf* -exec du -sb {} \;| sed -ne 's/^\([0-9]\+\)\t\(\/var\/vcap\/store\/mysql\/\)\(.*\)$/\3 \1/p'
    credential: shell_root
    mapping:
    - database
    separator: ' '
    value_type: UNTYPED
  - name: node_database_provisioning_bytes
    commands:
    - select db_name,max_storage_mb*1024*1024 FROM mysql_broker.service_instances;
    credential: mysql_connector
    mapping:
    - database
    value_type: UNTYPED
```
