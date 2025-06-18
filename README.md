# WordPress – just another Docker image

This WordPress Docker image is meant to ease the usage of WordPress by using a more conrfigurable Apache beneath the web application. For that, the [DevOps Ansible DE Apache Docker image](https://github.com/devops-ansible/apache) is used to apply the official WordPress installation.

## Configuration

First of all, the default behaviour of this container image disables the default behaviour of WP Cron – which is that cron tasks are only executed on a visitor accessing the page.

If you want this behaviour back, please see below list of environmental variables.

All possible WordPress configurations that may be set through Constants can be set by using environmental variables `WORDPRESS_<constant_name>`.

### Environmental Variables

| env                   | default               | change recommended | description |
| --------------------- | --------------------- |:------------------:| ----------- |
| `WORDPRESS_DEBUG`     | `false`               | not in prod        | enable debugging – **ATTENTION** this variable is differently named then the others ... regular name schema would be `WORDPRESS_WP_DEBUG`, but it's just `WORDPRESS_DEBUG`! |
| `WORDPRESS_WP_DEBUG_DISPLAY` | `false`        | not in prod        | show debugging in frontend |
| `WORDPRESS_WP_DEBUG_LOG` | `WORDPRESS_DEBUG`  | `¯\_(ツ)_/¯`       | write logs into log file |
| `WORDPRESS_DISABLE_WP_CRON` | `true`          | no, unless you set `START_CRON` to `0` as well | changing it would enable WP Cron behaviour: only when visitors access the instance, the cron tasks would be executed. Could raise performance problems! |


## Contribution guidelines

This Repository is Creative Commons non Commercial - You can contribute by forking and using pull requests. The team will review them asap.

## last built

2025-06-18 04:04:43
