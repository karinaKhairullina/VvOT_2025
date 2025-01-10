# Использование существующего сервисного аккаунта
data "yandex_iam_service_account" "sa_adm_tg_bot" {
  service_account_id = "aje3kqeap9j3mpbaijtn"
}

# Статический ключ для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = data.yandex_iam_service_account.sa_adm_tg_bot.id
  description        = "Static access key for Object Storage"
}




# Архивация директории с кодом функции
data "archive_file" "content" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "./build/hash.zip"
}

# Файл с хэшем
resource "local_file" "user_hash_file" {
  content  = data.archive_file.content.output_sha512
  filename = "../src/build/hash/user_hash.txt"
}

# Ресурс для функции bot
resource "yandex_function" "bot" {
  name               = "bot"
  description        = "Функция для обработки сообщений от Telegram бота"
  entrypoint         = "index.handler"
  memory             = "128"
  runtime            = "python312"
  service_account_id = data.yandex_iam_service_account.sa_adm_tg_bot.id
  user_hash          = data.archive_file.content.output_sha512
  execution_timeout  = "30"
  environment = {
    TELEGRAM_BOT_TOKEN = var.tg_bot_key
    FOLDER_ID          = var.folder_id
  }
  content {
    zip_filename = data.archive_file.content.output_path
  }
}

# Регистрация webhook
resource "null_resource" "register_webhook" {
  triggers = {
    function_id = yandex_function.bot.id
  }
  provisioner "local-exec" {
    command = <<EOT
      curl -s -X POST \
      "https://api.telegram.org/bot${var.tg_bot_key}/setWebhook" \
      -d "url=https://functions.yandexcloud.net/${yandex_function.bot.id}"
    EOT
  }
}

# Удаление webhook
resource "null_resource" "delete_webhook" {
  triggers = {
    tg_bot_key = var.tg_bot_key
  }

  provisioner "local-exec" {
    command = "curl -s -X POST https://api.telegram.org/bot${var.tg_bot_key}/deleteWebhook"
  }
}
