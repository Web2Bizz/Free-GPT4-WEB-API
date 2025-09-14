# FreeGPT4 API Cluster Architecture

## Обзор

Новая архитектура включает в себя:
- **Масштабируемые реплики Python API** (настраивается через `API_REPLICAS`, по умолчанию: 2)
- **Nginx reverse proxy** в двух сетях (external и internal)
- **Load balancing** между репликами API
- **Управление ресурсами** с лимитами памяти
- **Изоляция безопасности** - API недоступны извне

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    External Network                         │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Internet      │    │        Nginx                    │ │
│  │   Users         │◄───┤   (Reverse Proxy)               │ │
│  │                 │    │   Port: 15432                   │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Internal Network                         │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   LLM API       │◄───┤        Nginx                    │ │
│  │   (Scalable     │    │   (Load Balancer)               │ │
│  │    Replicas)    │    │   Round-robin                   │ │
│  │   Port: 5500    │    │   Auto-scaling                  │ │
│  │   (2+ instances)│    └─────────────────────────────────┘ │
│  └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

## Компоненты

### 1. Nginx Reverse Proxy
- **Сети**: external, internal
- **Порты**: 15432 (HTTP)
- **Функции**:
  - Load balancing между API репликами
  - Rate limiting
  - CORS поддержка
  - Health checks

### 2. LLM API Service Replicas
- **Сеть**: internal (изолированная)
- **Количество**: настраивается через `API_REPLICAS` (по умолчанию: 2)
- **Директория**: `llm-api-service/`
- **Порты**: 5500 (внутренние)
- **Функции**:
  - Обработка запросов к LLM
  - Health checks
  - Логирование
  - Управление настройками
  - Автоматическое масштабирование
- **Управление ресурсами**:
  - Лимиты памяти: `API_MEMORY_LIMIT` (по умолчанию: 512M)
  - Резервирование памяти: `API_MEMORY_RESERVATION` (по умолчанию: 256M)
  - Политика перезапуска при сбоях


## Сети

### External Network
- **Тип**: bridge
- **Доступ**: извне
- **Сервисы**: nginx

### Internal Network
- **Тип**: bridge, internal
- **Доступ**: только внутри Docker
- **Сервисы**: nginx, api replicas

## Load Balancing

### Алгоритм
- **Метод**: Round-robin
- **Health checks**: Включены
- **Failover**: Автоматический

### Конфигурация
```nginx
upstream freegpt4_api {
    server api:5500 max_fails=3 fail_timeout=60s;
    keepalive 32;
}
```

## Безопасность

### Изоляция сети
- API реплики недоступны извне
- Только nginx может обращаться к API
- Internal сеть изолирована

### Rate Limiting
- **API**: 10 запросов/секунду
- **Settings**: 5 запросов/минуту
- **Burst**: 20 запросов


## Мониторинг

### Health Checks
- **API**: `/models` endpoint
- **Nginx**: `/health` endpoint
- **Интервал**: 30 секунд

### Логирование
- **Nginx**: access.log, error.log
- **API**: Отдельные логи для каждой реплики
- **Ротация**: Автоматическая

## Запуск

### Базовый запуск
```bash
# Запуск кластера
chmod +x scripts/start-cluster.sh
./scripts/start-cluster.sh

# Мониторинг
chmod +x scripts/monitor-cluster.sh
./scripts/monitor-cluster.sh
```


## Конфигурация

### Environment Variables
```bash
# API настройки
LOG_LEVEL=INFO
ENABLE_REQUEST_LOGGING=false
PRIVATE_MODE=false
PROVIDER=You
REMOVE_SOURCES=true

# Масштабирование
API_REPLICAS=2                    # Количество реплик API (по умолчанию: 2)
API_MEMORY_LIMIT=512M            # Лимит памяти на реплику (по умолчанию: 512M)
API_MEMORY_RESERVATION=256M      # Резервирование памяти (по умолчанию: 256M)

```

### Docker Compose
```yaml
version: "3.9"
services:
  nginx:
    build:
      context: ./nginx
      dockerfile: Dockerfile
    ports:
      - "15432:15432"
    volumes:
      - "./logs/nginx:/var/log/nginx:rw"
      - "./nginx/nginx.conf:/etc/nginx/nginx.conf:ro"
    depends_on:
      - api
    networks:
      - external
      - internal
    restart: unless-stopped

  api:
    build:
      context: ./llm-api-service
      dockerfile: Dockerfile
    volumes:
      - "./llm-api-service/data:/app/data:rw"
      - "./logs:/app/logs:rw"
    networks:
      - internal
      - external
    environment:
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
      - PROVIDER=${PROVIDER:-You}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5500/models"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      replicas: ${API_REPLICAS:-2}
      resources:
        limits:
          memory: ${API_MEMORY_LIMIT:-512M}
        reservations:
          memory: ${API_MEMORY_RESERVATION:-256M}
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

networks:
  external:
    driver: bridge
  internal:
    driver: bridge
    internal: true
```

## Преимущества

### Высокая доступность
- 2 реплики API
- Автоматический failover
- Health checks

### Безопасность
- Изоляция API от внешнего мира
- Rate limiting

### Масштабируемость
- Легко добавить больше реплик
- Load balancing
- Мониторинг

### Производительность
- Round-robin распределение нагрузки
- Keepalive соединения
- Кэширование статических файлов

## Troubleshooting

### Проверка статуса
```bash
# Статус сервисов
docker-compose ps

# Логи
docker-compose logs -f

# Мониторинг
./scripts/monitor-cluster.sh
```

### Проблемы с сетью
```bash
# Проверка сетей
docker network ls
docker network inspect external
docker network inspect internal

# Проверка подключений
docker exec -it nginx_container ping api
```


## Масштабирование

### Настройка количества реплик
Количество реплик API настраивается через переменную окружения `API_REPLICAS`:

```bash
# Разработка - 1 реплика
export API_REPLICAS=1
docker-compose up -d

# Продакшн - 4 реплики
export API_REPLICAS=4
docker-compose up -d

# Высокая нагрузка - 8 реплик
export API_REPLICAS=8
docker-compose up -d
```

### Управление ресурсами
Каждая реплика может иметь ограничения по памяти:

```bash
# Установка лимитов памяти
export API_MEMORY_LIMIT=1G
export API_MEMORY_RESERVATION=512M
docker-compose up -d
```

### Мониторинг масштабирования
```bash
# Проверка количества запущенных реплик
docker-compose ps api

# Мониторинг использования ресурсов
docker stats

# Логи всех реплик
docker-compose logs -f api
```

### Автоматическое масштабирование
Docker Compose автоматически:
- Создает указанное количество реплик
- Распределяет нагрузку через Nginx
- Перезапускает упавшие реплики
- Управляет ресурсами согласно настройкам

### Горизонтальное масштабирование
- Добавить больше nginx инстансов
- Использовать внешний load balancer
- Настроить sticky sessions при необходимости
- Использовать Docker Swarm для кластерного развертывания
