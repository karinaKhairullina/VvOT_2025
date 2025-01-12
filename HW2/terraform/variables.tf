variable "cloud_id" {
  description = "ID облака в Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID папки в Yandex Cloud"
  type        = string
}

variable "service_account_key_id" {
  description = "ID статического ключа сервисного аккаунта"
  type        = string
  sensitive   = true
}

variable "service_account_secret" {
  description = "Статический ключ сервисного аккаунта"
  type        = string
  sensitive   = true
}

variable "photos_bucket" {
  description = "Название бакета для оригинальных фотографий"
  type        = string
}

variable "faces_bucket" {
  description = "Название бакета для фотографий лиц"
  type        = string
}

variable "queue_name" {
  description = "Название очереди сообщений"
  type        = string
}

variable "bot_function" {
  description = "Название функции для Telegram бота"
  type        = string
}

variable "tg_bot_key" {
  description = "Telegram Bot Token"
  type        = string
  sensitive   = true
}

variable "api_gateway" {
  description = "Название API Gateway"
  type        = string
}

variable "registry_name" {
  description = "Название реестра для Docker образов"
  type        = string
}

variable "db_name" {
  description = "Название базы данных для фотографий"
  type        = string
}

variable "key_file_path" {
  type        = string
  description = "Ключ сервисного аккаунта"
  default     = "~/.yc-keys/key.json"
}