resource "aws_sns_topic" "sns_topic" {
  for_each                    = { for topic in var.sns : topic.name => topic }
  name                        = each.value.fifo_topic ? "${each.key}-${var.env}.fifo" : "${each.key}-${var.env}"
  delivery_policy             = each.value.delivery_policy
  kms_master_key_id           = each.value.kms_master_key_id
  fifo_topic                  = each.value.fifo_topic
  content_based_deduplication = each.value.content_based_deduplication
}
