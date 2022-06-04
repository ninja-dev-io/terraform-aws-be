locals {
  subscriptions = flatten([for queue in var.sqs : [for topic in queue.topics : { "topic" : topic, "queue" : queue.name }]])
}

resource "aws_sqs_queue" "sqs_queue" {
  for_each                          = { for queue in var.sqs : queue.name => queue }
  name                              = each.value.fifo_queue ? "${each.key}-${var.env}.fifo" : "${each.key}-${var.env}"
  fifo_queue                        = each.value.fifo_queue
  content_based_deduplication       = each.value.content_based_deduplication
  kms_master_key_id                 = each.value.kms_master_key_id
  kms_data_key_reuse_period_seconds = each.value.kms_data_key_reuse_period_seconds
}

resource "aws_sns_topic_subscription" "sqs_target" {
  for_each   = { for index, subscription in local.subscriptions : tostring(index) => subscription }
  topic_arn  = lookup(aws_sns_topic.sns_topic, each.value.topic).arn
  protocol   = "sqs"
  endpoint   = lookup(aws_sqs_queue.sqs_queue, each.value.queue).arn
  depends_on = [aws_sns_topic.sns_topic, aws_sqs_queue.sqs_queue]
}

data "aws_iam_policy_document" "iam_policy_document" {
  for_each = { for queue in var.sqs : queue.name => queue }
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [
      lookup(aws_sqs_queue.sqs_queue, each.key).arn
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnLike"
      values   = [for topic in each.value.topics : lookup(aws_sns_topic.sns_topic, topic).arn]
      variable = "aws:SourceArn"
    }
  }
  depends_on = [aws_sns_topic.sns_topic, aws_sqs_queue.sqs_queue]
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  for_each   = { for queue in var.sqs : queue.name => queue }
  queue_url  = lookup(aws_sqs_queue.sqs_queue, each.key).id
  policy     = lookup(data.aws_iam_policy_document.iam_policy_document, each.key).json
  depends_on = [aws_sqs_queue.sqs_queue]
}
