
variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога Yandex Cloud"
  type        = string
}

variable "tg_bot_key" {
  description = "Токен для доступа к Telegram Bot API"
  type        = string
}

variable "bucket_name" {
  description = "Имя bucket для хранения объектов"
  type        = string
  default     = "shpargalkabucket"
}

variable "bucket_object_key" {
  description = "Ключ объекта, который будет храниться в bucket"
  type        = string
  default     = "instruction.txt"
}

variable "mount_point" {
  default = "/function/storage/bucketBot"
}


variable "source_dir" {
  type        = string
  description = "Путь к директории для архивации"
  default     = "/Users/karina/Desktop/VvOT/src"
}

variable "key_file_path" {
  type        = string
  description = "Ключ сервисного аккаунта"
  default     = "~/.yc-keys/key.json"
}