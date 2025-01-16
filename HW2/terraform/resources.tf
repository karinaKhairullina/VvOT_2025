
# Создание сервисного аккаунта
resource "yandex_iam_service_account" "sa" {
  name = "vvot44-service-account"
}

# Создание бакетов для фотографий
resource "yandex_storage_bucket" "photos_bucket" {
  bucket               = var.photos_bucket
  acl                  = "private"
  default_storage_class = "standard"
  max_size             = 5368709120  
}

resource "yandex_storage_bucket" "faces_bucket" {
  bucket               = var.faces_bucket
  acl                  = "private"
  default_storage_class = "standard"
  max_size             = 1073741824 
}

# Очередь сообщений для задач
resource "yandex_message_queue" "tasks_queue" {
  name        = var.queue_name
  access_key  = var.service_account_key_id  
  secret_key  = var.service_account_secret  
}


# Создание Yandex Database (serverless)
resource "yandex_ydb_database_serverless" "database" {
  name        = "vvot44-ydb-serverless"
  folder_id   = var.folder_id  

  # Включение защиты от удаления
  deletion_protection = true
}

# Создание функции для обнаружения лиц
resource "yandex_function" "face_detection" {
  name               = "vvot44-face-detection"
  entrypoint         = "index.handler"
  memory             = "256"
  runtime            = "python312"
  service_account_id = yandex_iam_service_account.sa.id
  user_hash          = "face-detection-user" 
  content {
    zip_filename = data.archive_file.bot_source.output_path
  }
}

# Триггер для обнаружения лиц
resource "yandex_function_trigger" "photo_trigger" {
  name        = "vvot44-photo-trigger"
  description = "Trigger for photo upload in photos bucket"
  
  function {
    id                 = yandex_function.face_detection.id
    service_account_id = yandex_iam_service_account.sa.id
    retry_attempts     = 3
    retry_interval     = 30
  }

  object_storage {
    bucket_id = yandex_storage_bucket.photos_bucket.id
    suffix    = ".jpg"  
    create    = true
  }
}

# Создание обработчика для нарезки лиц
resource "yandex_function" "face_cut" {
  name               = "vvot44-face-cut"
  entrypoint         = "index.handler"
  memory             = "256"
  runtime            = "python312"
  service_account_id = yandex_iam_service_account.sa.id
  user_hash          = "face-cut-user"  
  content {
    zip_filename = data.archive_file.bot_source.output_path
  }
}

# Триггер для задач
resource "yandex_function_trigger" "task_trigger" {
  name        = "vvot44-task-trigger"
  description = "Trigger for task queue"
  
  function {
    id                 = yandex_function.face_cut.id
    service_account_id = yandex_iam_service_account.sa.id
    retry_attempts     = 3
    retry_interval     = 30
  }

  message_queue {
    queue_id           = yandex_message_queue.tasks_queue.id
    service_account_id = yandex_iam_service_account.sa.id
    batch_cutoff       = 100  
  }
}


# Создание Telegram бота
resource "yandex_function" "bot" {
  name               = "vvot44-bot"
  entrypoint         = "index.handler"
  memory             = "128"
  runtime            = "python312"
  service_account_id = yandex_iam_service_account.sa.id
  user_hash          = "bot-user" 
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
  name = "vvot44-apigw"
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
        service_account_id: ${yandex_iam_service_account.sa.id}
EOT
}

# Ресурс для создания архива с кодом
data "archive_file" "bot_source" {
  type        = "zip"
  source_dir  = "../src/bot"
  output_path = "../build/bot.zip"
}
