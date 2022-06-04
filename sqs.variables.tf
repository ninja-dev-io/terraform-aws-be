variable "sqs" {
  type = list(object({
    name                              = string
    fifo_queue                        = bool
    content_based_deduplication       = bool
    kms_master_key_id                 = string
    kms_data_key_reuse_period_seconds = number
    topics                            = list(string)
  }))
}
