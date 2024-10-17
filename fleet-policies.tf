# This is generated dynamically in our code, but have simplified here
locals {
  agent_integration_policies = {
    "TestAWS EKS/EKS" = {
      agent_policy     = "Test AWS EKS"
      description      = <<-EOT
                Kubernetes integration for capturing logs and metrics from Test EKS cluster
            EOT
      integration      = "EKS"
      integration_name = "Test AWS EKS/EKS"
      integration_type = "kubernetes"
      namespace        = "test"
    }
  }

  fleet_agent_policies_map = {
    "Test AWS EKS" = {
      integrations = [
        {
          description = <<-EOT
                        Kubernetes integration for capturing logs and metrics from Test EKS cluster
                    EOT
          name        = "EKS"
          type        = "kubernetes"
        },
      ]
      name      = "Test AWS EKS"
      namespace = "test"
    }
  }
}

# Integrations
data "elasticstack_fleet_integration" "integrations" {
  for_each = toset(["kubernetes"])
  name = each.key
}

# Create an agent policy per environment
resource "elasticstack_fleet_agent_policy" "agent_policies" {
  for_each = local.fleet_agent_policies_map

  name            = format("%s Agent Policy", title(each.key))
  namespace       = try(each.value.namespace, "default")
  description     = try(each.value.description, null)
  monitor_logs    = try(each.value.monitor_logs, true)
  monitor_metrics = try(each.value.monitor_metrics, true)
  skip_destroy    = try(each.value.skip_destroy, false)
}

# Create agent integration policy
resource "elasticstack_fleet_integration_policy" "agent_integration_policies" {
  for_each = local.agent_integration_policies

  name                = each.value.integration_name
  namespace           = each.value.namespace
  description         = each.value.description
  agent_policy_id     = elasticstack_fleet_agent_policy.agent_policies[each.value.agent_policy].policy_id
  integration_name    = data.elasticstack_fleet_integration.integrations[each.value.integration_type].name
  integration_version = data.elasticstack_fleet_integration.integrations[each.value.integration_type].version

  dynamic "input" {
    for_each = yamldecode(file(format("config/policies/integrations/%s/policy.yaml", each.value.integration_type))).inputs

    content {
      input_id     = input.key
      streams_json = jsonencode(input.value.streams)
    }
  }
}
