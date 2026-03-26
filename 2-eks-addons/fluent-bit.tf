# ============================================================================
# FLUENT BIT FOR LOG FORWARDING
# Forwards container logs to CloudWatch Logs
# ============================================================================

# IAM Policy for Fluent Bit
data "aws_iam_policy_document" "fluent_bit_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:fluent-bit"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fluent_bit" {
  name               = "${var.project_name}-${var.environment}-fluent-bit"
  assume_role_policy = data.aws_iam_policy_document.fluent_bit_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-fluent-bit"
  })
}

data "aws_iam_policy_document" "fluent_bit_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "fluent_bit" {
  name        = "${var.project_name}-${var.environment}-fluent-bit"
  description = "Policy for Fluent Bit log forwarding"
  policy      = data.aws_iam_policy_document.fluent_bit_policy.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-fluent-bit"
  })
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  role       = aws_iam_role.fluent_bit.name
  policy_arn = aws_iam_policy.fluent_bit.arn
}

# ============================================================================
# FLUENT BIT DEPLOYMENT
# ============================================================================

# Create namespace for CloudWatch
resource "kubernetes_namespace" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      name = "amazon-cloudwatch"
    }
  }
}

# Service Account for Fluent Bit
resource "kubernetes_service_account" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit.arn
    }
  }

  depends_on = [aws_iam_role_policy_attachment.fluent_bit]
}

# ConfigMap for Fluent Bit
resource "kubernetes_config_map" "fluent_bit_config" {
  metadata {
    name      = "fluent-bit-config"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
    labels = {
      app = "fluent-bit"
    }
  }

  data = {
    "fluent-bit.conf" = <<-EOF
      [SERVICE]
          Flush                     5
          Log_Level                 info
          Daemon                    off
          Parsers_File              parsers.conf
          HTTP_Server               On
          HTTP_Listen               0.0.0.0
          HTTP_Port                 2020
          storage.path              /var/fluent-bit/state/flb-storage/
          storage.sync              normal
          storage.checksum          off
          storage.max_chunks_up     128
          storage.backlog.mem_limit 5M

      [INPUT]
          Name                tail
          Tag                 application.*
          Path                /var/log/containers/*.log
          Parser              docker
          DB                  /var/fluent-bit/state/flb_container.db
          Mem_Buf_Limit       50MB
          Skip_Long_Lines     On
          Refresh_Interval    10
          Read_from_Head      Off

      [INPUT]
          Name                tail
          Tag                 dataplane.systemd.*
          Path                /var/log/journal
          Parser              systemd
          DB                  /var/fluent-bit/state/flb_journal.db
          Mem_Buf_Limit       50MB
          Skip_Long_Lines     On
          Refresh_Interval    10
          Read_from_Head      Off

      [FILTER]
          Name                kubernetes
          Match               application.*
          Kube_URL            https://kubernetes.default.svc:443
          Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
          Kube_Tag_Prefix     application.var.log.containers.
          Merge_Log           On
          Keep_Log            On
          K8S-Logging.Parser  On
          K8S-Logging.Exclude On
          Buffer_Size         0

      [OUTPUT]
          Name                cloudwatch_logs
          Match               application.*
          region              ${var.aws_region}
          log_group_name      /aws/eks/${local.cluster_name}/application
          log_stream_prefix   fluentbit-
          auto_create_group   true
          retry_limit         2

      [OUTPUT]
          Name                cloudwatch_logs
          Match               dataplane.systemd.*
          region              ${var.aws_region}
          log_group_name      /aws/eks/${local.cluster_name}/dataplane
          log_stream_prefix   systemd-
          auto_create_group   true
          retry_limit         2

      [OUTPUT]
          Name                es
          Match               application.*
          Host                elasticsearch-master.monitoring.svc.cluster.local
          Port                9200
          Index               eks-application
          Type                _doc
          Logstash_Format     On
          Logstash_Prefix     eks-application
          Retry_Limit         2

      [OUTPUT]
          Name                es
          Match               dataplane.systemd.*
          Host                elasticsearch-master.monitoring.svc.cluster.local
          Port                9200
          Index               eks-dataplane
          Type                _doc
          Logstash_Format     On
          Logstash_Prefix     eks-dataplane
          Retry_Limit         2
    EOF

    "parsers.conf" = <<-EOF
      [PARSER]
          Name                docker
          Format              json
          Time_Key            time
          Time_Format         %Y-%m-%dT%H:%M:%S.%LZ
          Time_Keep           On

      [PARSER]
          Name                systemd
          Format              regex
          Regex               ^(?<time>[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$
          Time_Key            time
          Time_Format         %b %d %H:%M:%S
    EOF
  }
}

# DaemonSet for Fluent Bit
resource "kubernetes_daemonset" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.amazon_cloudwatch.metadata[0].name
    labels = {
      app                          = "fluent-bit"
      "app.kubernetes.io/name"     = "fluent-bit"
      "app.kubernetes.io/instance" = "fluent-bit"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          app = "fluent-bit"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluent_bit.metadata[0].name

        container {
          name  = "fluent-bit"
          image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:2.31.12"

          resources {
            limits = {
              memory = "200Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          volume_mount {
            name       = "fluentbitstate"
            mount_path = "/var/fluent-bit/state"
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
            read_only  = true
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }

          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc/"
          }

          volume_mount {
            name       = "runlogjournal"
            mount_path = "/run/log/journal"
            read_only  = true
          }

          volume_mount {
            name       = "dmesg"
            mount_path = "/var/log/dmesg"
            read_only  = true
          }
        }

        volume {
          name = "fluentbitstate"
          host_path {
            path = "/var/fluent-bit/state"
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config.metadata[0].name
          }
        }

        volume {
          name = "runlogjournal"
          host_path {
            path = "/run/log/journal"
          }
        }

        volume {
          name = "dmesg"
          host_path {
            path = "/var/log/dmesg"
          }
        }

        termination_grace_period_seconds = 10
      }
    }
  }

  depends_on = [
    kubernetes_service_account.fluent_bit,
    kubernetes_config_map.fluent_bit_config
  ]
}
