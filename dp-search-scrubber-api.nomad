job "dp-search-scrubber-api" {
  datacenters = ["eu-west-2"]
  region      = "eu"
  type        = "service"

  update {
    stagger          = "60s"
    min_healthy_time = "30s"
    healthy_deadline = "2m"
    max_parallel     = 1
    auto_revert      = true
  }

  group "web" {
    count = "{{WEB_TASK_COUNT}}"

    spread {
      attribute = "${node.unique.id}"
      weight    = 100
      # with `target` omitted, Nomad will spread allocations evenly across all values of the attribute.
    }
    spread {
      attribute = "${attr.platform.aws.placement.availability-zone}"
      weight    = 100
      # with `target` omitted, Nomad will spread allocations evenly across all values of the attribute.
    }

    constraint {
      attribute = "${node.class}"
      value     = "web"
    }

    restart {
      attempts = 3
      delay    = "15s"
      interval = "1m"
      mode     = "delay"
    }

    task "dp-search-scrubber-api-web" {
      driver = "docker"

      artifact {
        source = "s3::https://s3-eu-west-2.amazonaws.com/{{DEPLOYMENT_BUCKET}}/dp-search-scrubber-api/{{PROFILE}}/{{RELEASE}}.tar.gz"
      }

      config {
        command = "${NOMAD_TASK_DIR}/start-task"

        args = ["./dp-search-scrubber-api"]

        image = "{{ECR_URL}}:concourse-{{REVISION}}"

      }

      service {
        name = "dp-search-scrubber-api"
        port = "http"
        tags = ["web"]

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = "{{WEB_RESOURCE_CPU}}"
        memory = "{{WEB_RESOURCE_MEM}}"

        network {
          port "http" {}
        }
      }

      template {
        source      = "${NOMAD_TASK_DIR}/vars-template"
        destination = "${NOMAD_TASK_DIR}/vars"
      }

      vault {
        policies = ["dp-search-scrubber-api-web"]
      }
    }
  }

  group "publishing" {
    count = "{{PUBLISHING_TASK_COUNT}}"

    spread {
      attribute = "${node.unique.id}"
      weight    = 100
      # with `target` omitted, Nomad will spread allocations evenly across all values of the attribute.
    }
    spread {
      attribute = "${attr.platform.aws.placement.availability-zone}"
      weight    = 100
      # with `target` omitted, Nomad will spread allocations evenly across all values of the attribute.
    }
    
    constraint {
      attribute = "${node.class}"
      value     = "publishing"
    }

    restart {
      attempts = 3
      delay    = "15s"
      interval = "1m"
      mode     = "delay"
    }

    task "dp-search-scrubber-api-publishing" {
      driver = "docker"

      artifact {
        source = "s3::https://s3-eu-west-2.amazonaws.com/{{DEPLOYMENT_BUCKET}}/dp-search-scrubber-api/{{PROFILE}}/{{RELEASE}}.tar.gz"
      }

      config {
        command = "${NOMAD_TASK_DIR}/start-task"

        args = ["./dp-search-scrubber-api"]

        image = "{{ECR_URL}}:concourse-{{REVISION}}"
      }

      service {
        name = "dp-search-scrubber-api"
        port = "http"
        tags = ["publishing"]

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = "{{PUBLISHING_RESOURCE_CPU}}"
        memory = "{{PUBLISHING_RESOURCE_MEM}}"

        network {
          port "http" {}
        }
      }

      template {
        source      = "${NOMAD_TASK_DIR}/vars-template"
        destination = "${NOMAD_TASK_DIR}/vars"
      }

      vault {
        policies = ["dp-search-scrubber-api-publishing"]
      }
    }
  }
}
