import cv2
import json
import os
import random
import string
import requests


def handler(event, context):
    # Извлекаем задание
    object_key = event['object_key']
    face_coordinates = event['face_coordinates']

    # Скачиваем оригинальное фото
    bucket_name = os.getenv('PHOTOS_MOUNT_POINT')
    object_url = f"https://storage.yandexcloud.net/{bucket_name}/{object_key}"
    image = download_image(object_url)

    # Обрезаем лицо
    x, y, w, h = face_coordinates
    face_image = image[y:y + h, x:x + w]

    # Генерируем случайный ключ для фотографии лица
    face_key = ''.join(random.choices(string.ascii_letters + string.digits, k=16)) + ".jpg"

    # Сохраняем лицо в другой бакет
    faces_bucket = os.getenv('FACES_BUCKET')
    upload_face_image(faces_bucket, face_key, face_image)

    return {"status": "success"}


def download_image(url):
    # Скачиваем изображение
    response = requests.get(url)
    image = cv2.imdecode(np.frombuffer(response.content, np.uint8), cv2.IMREAD_COLOR)
    return image


def upload_face_image(bucket, key, image):
    # Загружаем обрезанное лицо в бакет
    _, img_encoded = cv2.imencode('.jpg', image)
    img_bytes = img_encoded.tobytes()

    # Загружаем в Yandex Cloud Storage
    storage_url = f"https://storage.yandexcloud.net/{bucket}/{key}"
    response = requests.put(storage_url, data=img_bytes)
    if response.status_code != 200:
        raise Exception(f"Failed to upload face image: {response.text}")
