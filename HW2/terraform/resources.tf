
// Создание сервисного аккаунта
resource "yandex_iam_service_account" "sa" {
  name = "vvot00-service-account"
}

// Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for object storage"
}

// Создание бакета для фотографий
resource "yandex_storage_bucket" "photos_bucket" {
  bucket = var.photos_bucket
  access_key            = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  acl                   = "private"
  default_storage_class = "standard"
  max_size              = 5368709120 # 5GB

}

// Создание бакета для лиц
resource "yandex_storage_bucket" "faces_bucket" {
  bucket = var.faces_bucket
  access_key            = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  acl                   = "private"
  default_storage_class = "standard"
  max_size              = 1073741824 # 1GB
}

# Создание очереди сообщений для задач
resource "yandex_message_queue" "tasks_queue" {
  name = var.queue_name
}

# Создание функции для Telegram Bot
resource "yandex_function" "bot" {
  name               = "vvot44-boot"
  entrypoint         = "index.handler"
  memory             = "128"
  runtime            = "python312"
  service_account_id = yandex_iam_service_account.sa.id  # Исправлено на sa.id
  user_hash          = "unique-user-hash"  # Уникальный хеш для вашего проекта
  environment = {
    TELEGRAM_BOT_TOKEN = var.tg_bot_key
    API_GATEWAY_URL    = "https://${yandex_api_gateway.api_gw.domain}"
  }
  content {
    zip_filename = data.archive_file.bot_source.output_path
  }
}

# Настройка API Gateway для работы с фотографиями лиц
resource "yandex_api_gateway" "api_gw" {
  name = var.api_gateway
  spec = <<-EOT
openapi: "3.0.0"
info:
  version: 1.0.0
  title: Photo Face Detector API
paths:
  /:
    get:
      summary: Serve face images from Yandex Cloud Object Storage
      parameters:
        - name: face
          in: query
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${yandex_storage_bucket.faces_bucket.bucket}
        object: "{face}"
        service_account_id: ${yandex_iam_service_account.sa.id}  # Исправлено на sa.id
EOT
}



# Привязка прав для функции бота
resource "yandex_function_iam_binding" "bot_iam" {
  function_id = yandex_function.bot.id
  role        = "functions.functionInvoker"
  members = [
    "system:allUsers",
  ]
}

# Настройка Webhook для Telegram Bot
resource "telegram_bot_webhook" "bot_webhook" {
  url = "https://functions.yandexcloud.net/${yandex_function.bot.id}"
}



# Архив с кодом для Telegram Bot
data "archive_file" "bot_source" {
  type        = "zip"
  source_dir  = "../src/bot"
  output_path = "../build/bot.zip"
}
