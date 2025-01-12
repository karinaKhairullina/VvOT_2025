# Существующий сервисный аккаунт "adm"
data "yandex_iam_service_account" "adm" {
  name = "adm"
}

# Привязка прав для сервисного аккаунта adm
resource "yandex_resourcemanager_folder_iam_member" "adm_storage_editor_iam" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${data.yandex_iam_service_account.adm.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "adm_function_invoker_iam" {
  folder_id = var.folder_id
  role      = "functions.functionInvoker"
  member    = "serviceAccount:${data.yandex_iam_service_account.adm.id}"
}

# Создание бакетов для фотографий и лиц
resource "yandex_storage_bucket" "photos_bucket" {
  bucket = var.photos_bucket
  acl    = "private"
}

resource "yandex_storage_bucket" "faces_bucket" {
  bucket = var.faces_bucket
  acl    = "private"
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
  service_account_id = data.yandex_iam_service_account.adm.id
  user_hash          = "unique-user-hash"  # Уникальный хеш для вашего проекта
  environment = {
    TELEGRAM_BOT_TOKEN = var.tg_bot_key
    API_GATEWAY_URL    = "https://${yandex_api_gateway.api_gw.domain}"
  }
  content {
    zip_filename = data.archive_file.bot_source.output_path
  }

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
        service_account_id: ${data.yandex_iam_service_account.adm.id}
EOT
}

# Архив с кодом для Telegram Bot
data "archive_file" "bot_source" {
  type        = "zip"
  source_dir  = "../src/bot"
  output_path = "../build/bot.zip"
}
