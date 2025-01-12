import logging
import os
import requests
from telegram import Update
from telegram.ext import Updater, CommandHandler, CallbackContext

# Настройка логирования
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# API Gateway URL
API_GATEWAY_URL = os.getenv("API_GATEWAY_URL")


# Команда для получения фотографии лица
def get_face(update: Update, context: CallbackContext) -> None:
    # Получаем фотографию лица с API
    response = requests.get(f"{API_GATEWAY_URL}/?face=random_face_key")
    if response.status_code == 200:
        update.message.reply_photo(photo=response.content)
    else:
        update.message.reply_text("Ошибка при получении фотографии.")


# Команда для поиска фотографий по имени
def find_face(update: Update, context: CallbackContext) -> None:
    name = context.args[0] if context.args else None
    if not name:
        update.message.reply_text("Укажите имя.")
        return

    # Поиск фотографий по имени
    response = requests.get(f"{API_GATEWAY_URL}/find?name={name}")
    if response.status_code == 200:
        photos = response.json()
        if photos:
            for photo in photos:
                update.message.reply_photo(photo=photo['url'])
        else:
            update.message.reply_text(f"Фотографии с именем {name} не найдены.")
    else:
        update.message.reply_text("Ошибка при поиске фотографий.")


# Основная функция для запуска бота
def main() -> None:
    TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")

    updater = Updater(TELEGRAM_BOT_TOKEN)
    dispatcher = updater.dispatcher

    dispatcher.add_handler(CommandHandler("getface", get_face))
    dispatcher.add_handler(CommandHandler("find", find_face))

    updater.start_polling()
    updater.idle()


if __name__ == '__main__':
    main()
