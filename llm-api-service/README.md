# LLM API Service

This directory contains the Python application for the FreeGPT4 API service.

## Structure

```
llm-api-service/
├── src/                   # Source code directory
│   └── freegpt4/         # Main package
│       ├── __init__.py   # Package initialization
│       ├── FreeGPT4_Server.py  # Main application
│       ├── config.py     # Configuration management
│       ├── auth.py       # Authentication logic
│       ├── ai_service.py # AI service integration
│       ├── database.py   # Database management
│       ├── DBManager.py  # Database manager (deprecated)
│       └── utils/        # Utility modules
│           ├── __init__.py
│           ├── exceptions.py
│           ├── helpers.py
│           ├── http_utils.py
│           ├── logging.py
│           ├── provider_monitor.py
│           └── validation.py
├── static/               # Static web assets
│   ├── css/              # CSS files
│   ├── js/               # JavaScript files
│   └── img/              # Images
├── templates/            # HTML templates
│   ├── login.html        # Login page
│   └── settings.html     # Settings page
├── data/                 # Data directory
│   ├── cookies.json      # Browser cookies
│   ├── proxies.json      # Proxy configuration
│   └── settings.db       # Settings database
├── Dockerfile            # Docker configuration
├── requirements.txt      # Python dependencies
├── setup.py             # Package setup
├── pyproject.toml       # Modern Python project config
└── README.md            # This file
```

## Running the Service

### With Docker Compose (Recommended)

The service is designed to run as part of a cluster with load balancing:

```bash
# From the project root
docker compose up -d
```

### Standalone

```bash
# Install in development mode
pip install -e .

# Run the service
python -m freegpt4.FreeGPT4_Server --help

# Or use the console script
freegpt4-server --help
```

### Development

```bash
# Install in development mode with dev dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Format code
black src/

# Lint code
flake8 src/

# Type checking
mypy src/
```

## Configuration

The service can be configured through:

1. **Command line arguments** - See `python FreeGPT4_Server.py --help`
2. **Environment variables** - Set in docker compose.yml
3. **Web GUI** - Access via `/settings` endpoint

## Data Directory

The `data/` directory contains:
- `cookies.json` - Browser cookies for authentication
- `proxies.json` - Proxy server configuration
- `settings.db` - SQLite database with application settings

## Logs

Logs are written to:
- Console output (stdout)
- Log files in `/app/logs/` (when running in Docker)

## Health Check

The service provides a health check endpoint at `/models` that returns the list of available AI models.

## API Endpoints

- `GET /` - Main API endpoint
- `POST /` - Main API endpoint (with request body)
- `GET /settings` - Settings page
- `POST /settings` - Update settings
- `GET /models` - Health check and model list
