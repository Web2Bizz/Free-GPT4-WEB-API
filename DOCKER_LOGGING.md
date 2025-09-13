# Docker Logging для FreeGPT4 API

## Обзор

Настроена полная система логирования для Docker контейнеров с поддержкой различных уровней логирования и ротации файлов.

## Файлы конфигурации

### Основные файлы
- `docker-compose.yml` - базовая конфигурация с INFO уровнем
- `docker-compose.dev.yml` - конфигурация для разработки с DEBUG уровнем
- `docker-compose.prod.yml` - продакшен конфигурация с WARNING уровнем

### Скрипты управления логами
- `scripts/logs.sh` - Linux/macOS скрипт
- `scripts/logs.bat` - Windows скрипт

## Быстрый старт

### 1. Запуск с базовым логированием
```bash
docker-compose up -d
```

### 2. Запуск с детальным логированием (разработка)
```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 3. Запуск продакшен версии
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Управление логами

### Просмотр логов

#### Через Docker Compose
```bash
# Просмотр последних 50 строк
docker-compose logs api

# Следить за логами в реальном времени
docker-compose logs -f api

# Последние 100 строк
docker-compose logs --tail=100 api
```

#### Через скрипты

**Linux/macOS:**
```bash
# Сделать скрипт исполняемым
chmod +x scripts/logs.sh

# Просмотр логов
./scripts/logs.sh

# Следить за логами
./scripts/logs.sh -f

# Фильтр по уровню
./scripts/logs.sh --level ERROR

# Статистика логов
./scripts/logs.sh --stats
```

**Windows:**
```cmd
# Просмотр логов
scripts\logs.bat

# Следить за логами
scripts\logs.bat -f

# Фильтр по уровню
scripts\logs.bat --level ERROR

# Статистика логов
scripts\logs.bat --stats
```

### Очистка логов
```bash
# Linux/macOS
./scripts/logs.sh --clean

# Windows
scripts\logs.bat --clean
```

## Конфигурация логирования

### Переменные окружения
```yaml
environment:
  - LOG_LEVEL=INFO          # Уровень логирования
  - LOG_FILE=/app/logs/freegpt4.log  # Путь к файлу логов
```

### Аргументы командной строки
```yaml
command: 
  - --log-level INFO                    # Уровень логирования
  - --log-file /app/logs/freegpt4.log  # Файл логов
  - --enable-request-logging           # Детальное логирование запросов
```

## Структура логов

### Директории
```
logs/
├── freegpt4.log          # Основной лог файл
├── freegpt4.log.1        # Резервная копия 1
├── freegpt4.log.2        # Резервная копия 2
├── freegpt4-dev.log      # Лог разработки
└── freegpt4-prod.log     # Продакшен лог
```

### Формат логов
```
[2024-01-15 10:30:15,123] INFO in freegpt4: FreeGPT4 Web API - Starting server...
[2024-01-15 10:30:15,124] INFO in freegpt4: Logging configured - Level: INFO
[2024-01-15 10:30:15,125] INFO in freegpt4: Logging to file: /app/logs/freegpt4.log
[2024-01-15 10:35:20,456] INFO in freegpt4: Request: POST / from 192.168.1.100
[2024-01-15 10:35:20,457] DEBUG in freegpt4: User-Agent: Mozilla/5.0...
```

## Мониторинг

### Проверка статуса контейнера
```bash
docker-compose ps
```

### Проверка использования ресурсов
```bash
docker stats
```

### Проверка размера логов
```bash
# Linux/macOS
du -sh logs/

# Windows
dir logs\ /s
```

## Troubleshooting

### Проблема: Логи не создаются
**Решение:**
1. Проверьте права доступа к директории logs
2. Убедитесь, что контейнер запущен
3. Проверьте переменные окружения

```bash
# Проверка прав доступа
ls -la logs/

# Проверка переменных окружения
docker-compose exec api env | grep LOG
```

### Проблема: Логи занимают много места
**Решение:**
1. Настройте ротацию логов
2. Используйте более высокий уровень логирования
3. Регулярно очищайте старые логи

```bash
# Очистка логов
./scripts/logs.sh --clean

# Изменение уровня логирования
docker-compose down
docker-compose -f docker-compose.prod.yml up -d
```

### Проблема: Не видно логи в реальном времени
**Решение:**
```bash
# Следить за Docker логами
docker-compose logs -f api

# Следить за файлом логов
tail -f logs/freegpt4.log
```

## Продвинутые настройки

### Кастомная конфигурация
Создайте свой docker-compose файл:

```yaml
version: "3.9"
services:
  api:
    build: .
    environment:
      - LOG_LEVEL=DEBUG
      - LOG_FILE=/app/logs/custom.log
    command: 
      - --log-level DEBUG
      - --log-file /app/logs/custom.log
      - --enable-request-logging
      - --log-format "[%(asctime)s] %(levelname)s: %(message)s"
```

### Интеграция с внешними системами
```yaml
# Отправка логов в внешнюю систему
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Мониторинг через Prometheus
```yaml
# Добавьте метрики в docker-compose
services:
  api:
    # ... existing config
    labels:
      - "prometheus.scrape=true"
      - "prometheus.port=5500"
```
