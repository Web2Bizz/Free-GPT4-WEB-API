# Production Deployment Guide

## GitHub Secrets Configuration

Для работы workflow деплоя необходимо настроить следующие секреты в GitHub:

### Обязательные секреты:

1. **SSH_PRIVATE_KEY** - приватный SSH ключ для подключения к серверу
2. **PROD_HOST** - IP адрес или домен production сервера
3. **PROD_USERNAME** - имя пользователя для SSH подключения

### Опциональные секреты:

4. **PROD_PORT** - SSH порт (по умолчанию 22)
5. **PROD_APP_PATH** - путь к приложению на сервере (по умолчанию /opt/freegpt4)

## Настройка сервера

### 1. Подготовка сервера

```bash
# Создать директорию для приложения
sudo mkdir -p /opt/freegpt4
sudo chown $USER:$USER /opt/freegpt4

# Установить Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Установить Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Настройка SSH ключей

```bash
# На локальной машине сгенерировать SSH ключ
ssh-keygen -t rsa -b 4096 -C "github-actions@yourdomain.com"

# Скопировать публичный ключ на сервер
ssh-copy-id -i ~/.ssh/id_rsa.pub user@your-server-ip

# Добавить приватный ключ в GitHub Secrets как SSH_PRIVATE_KEY
cat ~/.ssh/id_rsa
```

### 3. Клонирование репозитория на сервер

```bash
# Клонировать репозиторий на сервер
git clone https://github.com/your-username/Free-GPT4-WEB-API.git /opt/freegpt4
cd /opt/freegpt4

# Создать необходимые директории
mkdir -p src/data logs

# Настроить права доступа
chmod -R 755 /opt/freegpt4
```

### 4. Создание Docker сети

```bash
# На сервере создать внешнюю сеть
docker network create app_net
```

## Настройка GitHub Secrets

1. Перейдите в Settings → Secrets and variables → Actions
2. Нажмите "New repository secret"
3. Добавьте каждый секрет:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| SSH_PRIVATE_KEY | Private SSH key | -----BEGIN OPENSSH PRIVATE KEY-----... |
| PROD_HOST | Server IP/domain | 192.168.1.100 |
| PROD_USERNAME | SSH username | ubuntu |
| PROD_PORT | SSH port (optional) | 22 |
| PROD_APP_PATH | App path (optional) | /opt/freegpt4 |

## Pipeline деплоя

Новый pipeline выполняет следующие шаги:

1. **Подключение к серверу** - SSH подключение к удалённой машине
2. **Pull репозитория** - получение последних изменений из Git
3. **Сборка Docker образа** - локальная сборка образа на сервере
4. **Очистка старых образов** - удаление неиспользуемых Docker образов
5. **Запуск контейнера** - запуск через docker-compose.prod.yml

## Запуск деплоя

### Автоматический деплой

Workflow запускается автоматически при:
- Push в ветку `main`
- Создании тега версии (v*)
- Ручном запуске через GitHub Actions

### Ручной запуск

1. Перейдите в Actions → Deploy to Production
2. Нажмите "Run workflow"
3. Выберите ветку и окружение
4. Нажмите "Run workflow"

## Мониторинг деплоя

### Логи

```bash
# Просмотр логов приложения
docker-compose -f /opt/freegpt4/docker-compose.prod.yml logs -f

# Просмотр логов конкретного контейнера
docker logs freegpt4-api
```

### Проверка статуса

```bash
# Статус контейнеров
docker-compose -f /opt/freegpt4/docker-compose.prod.yml ps

# Проверка здоровья
curl http://localhost:15432/models
```

## Откат (Rollback)

При неудачном деплое workflow автоматически откатится к предыдущей версии. Также можно выполнить ручной откат:

```bash
# Остановить текущие контейнеры
docker-compose -f /opt/freegpt4/docker-compose.prod.yml down

# Восстановить из бэкапа
cp -r /opt/freegpt4/backup /opt/freegpt4/current

# Запустить предыдущую версию
docker-compose -f /opt/freegpt4/docker-compose.prod.yml up -d
```

## Безопасность

- Используйте сильные SSH ключи
- Ограничьте доступ к серверу по IP
- Регулярно обновляйте Docker образы
- Мониторьте логи на предмет подозрительной активности
- Используйте HTTPS для внешнего доступа

## Troubleshooting

### Проблемы с SSH

```bash
# Проверить SSH подключение
ssh -i ~/.ssh/id_rsa user@your-server-ip

# Проверить права на ключ
chmod 600 ~/.ssh/id_rsa
```

### Проблемы с Docker

```bash
# Проверить статус Docker
sudo systemctl status docker

# Перезапустить Docker
sudo systemctl restart docker
```

### Проблемы с приложением

```bash
# Проверить логи
docker-compose -f /opt/freegpt4/docker-compose.prod.yml logs

# Проверить ресурсы
docker stats

# Проверить сеть
docker network ls
```
