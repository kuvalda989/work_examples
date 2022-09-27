

variable "charts" {
  description = "Create IAM users with these names"
  type = list(object({
    name             = string
    repository       = string
    chart            = string
    version          = string
    values_file      = optional(string)
    namespace        = optional(string)
    create_namespace = optional(string)

    set = optional(list(object({
      name  = string
      value = string
    })))
  }))
}

resource "helm_release" "chart" {
  for_each         = { for chart in var.charts : chart.name => chart }
  name             = each.value.name
  repository       = each.value.repository
  chart            = each.value.chart
  version          = each.value.version
  namespace        = each.value.namespace
  create_namespace = each.value.create_namespace

  values = [
    "${each.value.values_file != null ? file(each.value.values_file) : ""}"
  ]

  dynamic "set" {
    for_each = each.value.set == null ? [{"name" = "fake_null_name", "value" = "fake_null_value"}] : each.value.set
    content {
      name  = set.value["name"]
      value = set.value["value"]
    }
  }
}
