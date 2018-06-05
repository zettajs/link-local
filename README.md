# Link Local

Run Link deployment locally on host or in docker containers.

## Start Link In Docker

```
λ: ./docker-run.sh -h
Usage:
 -h: Show help
 -t <n>: Number of targets to start
 -v: Output stdout of link containers
```

1. `https://github.com/apigee-internal/link-local`
1. `cd link-local`
1. Link `link-router` folder to source. `ln -s <path to link-router src> link-router`
1. Link `link-zetta-target` folder to source. `ln -s <path to target src> link-zetta-target`
1. Link `link-tenant-mgmt-api` folder to source. `ln -s <path to tenant mgmt link-tenant-mgmt-api`
1. Run `./docker-run.sh`

```
Building Containers
   - Building link-router
   - Building link-zetta-target
   - Building target-wrapper
   - Building link-tenant-mgmt-api

Starting Services
  - Etcd
  - Target 1 of 1 on port 3001
  - Link Router
  - Tenant Management Api


Link Router Running at http://localhost:3000
Tenant Mgmt Api Running at http://localhost:2000
```

## Disclaimer

This is not an officially supported Google product.