# FreeGPT4 API Cluster Architecture

## Обзор

Новая архитектура включает в себя:
- **2 реплики Python API** в изолированной внутренней сети
- **Nginx reverse proxy** в двух сетях (external и internal)
- **Load balancing** между репликами API
- **SSL/TLS поддержка** с Let's Encrypt
- **Изоляция безопасности** - API недоступны извне

## Архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                    External Network                        │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   Internet      │    │        Nginx                    │ │
│  │   Users         │◄───┤   (Reverse Proxy)               │ │
│  │                 │    │   Ports: 80, 443                │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Internal Network                        │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │   LLM API 1     │◄───┤        Nginx                    │ │
│  │   (llm-api-     │    │   (Load Balancer)               │ │
│  │    service)     │    │   Round-robin                   │ │
│  │   Port: 5500    │    └─────────────────────────────────┘ │
│  └─────────────────┘              │                        │
│                                   │                        │
│  ┌─────────────────┐              │                        │
│  │   LLM API 2     │◄─────────────┘                        │
│  │   (llm-api-     │                                       │
│  │    service)     │                                       │
│  │   Port: 5500    │                                       │
│  └─────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

## Компоненты

### 1. Nginx Reverse Proxy
- **Сети**: external, internal
- **Порты**: 80 (HTTP), 443 (HTTPS)
- **Функции**:
  - Load balancing между API репликами
  - SSL/TLS терминация
  - Rate limiting
  - CORS поддержка
  - Health checks

### 2. LLM API Service Replicas
- **Сеть**: internal (изолированная)
- **Количество**: 2 реплики
- **Директория**: `llm-api-service/`
- **Порты**: 5500 (внутренние)
- **Функции**:
  - Обработка запросов к LLM
  - Health checks
  - Логирование
  - Управление настройками

### 3. Certbot
- **Сеть**: external
- **Функции**:
  - SSL сертификаты Let's Encrypt
  - Автоматическое обновление

## Сети

### External Network
- **Тип**: bridge
- **Доступ**: извне
- **Сервисы**: nginx, certbot

### Internal Network
- **Тип**: bridge, internal
- **Доступ**: только внутри Docker
- **Сервисы**: nginx, api1, api2

## Load Balancing

### Алгоритм
- **Метод**: Round-robin
- **Health checks**: Включены
- **Failover**: Автоматический

### Конфигурация
```nginx
upstream freegpt4_api {
    server api1:5500 max_fails=3 fail_timeout=30s;
    server api2:5500 max_fails=3 fail_timeout=30s;
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

### SSL/TLS
- **Протоколы**: TLSv1.2, TLSv1.3
- **Шифры**: Современные ECDHE
- **HSTS**: Включен

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

### С SSL
```bash
# Запуск с SSL
chmod +x scripts/start-cluster-ssl.sh
./scripts/start-cluster-ssl.sh api.example.com admin@example.com
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

# SSL настройки
SSL_DOMAIN=api.example.com
SSL_EMAIL=admin@example.com
```

### Docker Compose
```yaml
version: "3.9"
services:
  nginx:
    build:
      context: .
      dockerfile: nginx/Dockerfile
    ports:
      - "80:80"
      - "443:443"
    networks:
      - external
      - internal
  
  api1:
    build: .
    networks:
      - internal
  
  api2:
    build: .
    networks:
      - internal

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
- SSL/TLS шифрование
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
docker exec -it nginx_container ping api1
docker exec -it nginx_container ping api2
```

### Проблемы с SSL
```bash
# Проверка сертификатов
docker-compose logs certbot

# Обновление сертификатов
docker-compose run --rm certbot renew
```

## Масштабирование

### Добавление реплик
1. Добавить `api3` в docker-compose.yml
2. Обновить nginx.conf upstream
3. Перезапустить сервисы

### Горизонтальное масштабирование
- Добавить больше nginx инстансов
- Использовать внешний load balancer
- Настроить sticky sessions при необходимости
