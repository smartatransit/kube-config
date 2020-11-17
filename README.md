[![Build Status](https://infra.kube-test.smartatransit.com/api/badges/smartatransit/kube-system/status.svg)](https://infra.kube-test.smartatransit.com/smartatransit/kube-system)

kube-system
===========

This repo contains Kubernetes config for SMARTA team core services. This includes:

- Postgres
- Traefik (HTTP load-balancing and routing)
- Drone (for in-cluster Terraform builds)
- The [SMARTA API gateway](https://github.com/smartatransit/api-gateway)

Building from scratch
=====================

When provisioning a new cluster, start by configuring your local kubeconfig to point to the new cluster. Then run:

```
./scripts/create-tf-service
```

This will provision a new kubernetes service account for Terraform, and then spit out three values that should be supplied to the Terraform Cloud workspace as variables. In addition to these three, you should include the following variables:

`logzio_url` and `logzio_token` - URL and token for the logzio API
`drone_github_client_id` and `drone_github_client_secret`  - OAuth credentials for the Github Drone App. You should provision a new Github App for this purpose through the Github UI.
`drone_initial_admin_github_username` - the username of the initial drone admin who can activate new repositories and grant admin privileges to others
`lets_encrypt_email` - the team email account

After applying the repository and deploying the core services to the cluster, we'll need to provision an administrative postgres user for the `kube-services` repo to use. To do this, go into the "State" tab in Terraform Cloud and select the most recent state. Search for `postgres_root_password`, and then copy the value in the `result` field below it. Use that value with the following command:

```
 ./scripts/create-postgres-admin <ROOT_PG_PASSWORD>
```

Note the password that this command outputs.

Deploying the Smarta services
=============================
Go to the Drone server you configured and (after it finishes syncing) look for the `kube-services` repo and activate it. Make it internal and trusted, and (along with the other required drone secrets) provide the value you just recorded as `postgres_admin_password`. Trigger a build of the main branch and cross your fingers.
