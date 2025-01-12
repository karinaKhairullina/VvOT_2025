import cv2
import os
import requests
from yandexcloud.exceptions import YandexCloudError


def handler(event, context):
    # Параметры для Yandex Cloud Storage
    bucket_name = os.getenv('PHOTOS_MOUNT_POINT')

    # Скачиваем изображение с оригинальной фотографии
    object_key = event['object_key']
    object_url = f"https://storage.yandexcloud.net/{bucket_name}/{object_key}"
    image = download_image(object_url)

    # Детектируем лица
    faces = detect_faces(image)

    # Создаем задания в очереди
    queue_url = os.getenv('TASK_QUEUE_URL')
    for face in faces:
        task = {
            'object_key': object_key,
            'face_coordinates': face
        }
        create_task_in_queue(queue_url, task)

    return {"status": "success"}


def download_image(url):
    # Скачиваем изображение
    response = requests.get(url)
    image = cv2.imdecode(np.frombuffer(response.content, np.uint8), cv2.IMREAD_COLOR)
    return image


def detect_faces(image):
    # Используем OpenCV для обнаружения лиц
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
    return faces


def create_task_in_queue(queue_url, task):
    # Отправляем задание в очередь
    headers = {'Content-Type': 'application/json'}
    response = requests.post(queue_url, json=task, headers=headers)
    if response.status_code != 200:
        raise YandexCloudError(f"Failed to create task: {response.text}")
