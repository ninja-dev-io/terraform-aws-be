variable "sns" {
  type = list(object({
    name                        = string
    delivery_policy             = string
    kms_master_key_id           = string
    fifo_topic                  = bool
    content_based_deduplication = bool
  }))
}
