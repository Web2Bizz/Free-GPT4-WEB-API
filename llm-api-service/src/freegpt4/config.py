"""Configuration management for FreeGPT4 Web API."""

import os
from dataclasses import dataclass
from typing import Dict, Any, Optional
from pathlib import Path

# Base configuration
BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"
TEMPLATES_DIR = BASE_DIR / "templates"
STATIC_DIR = BASE_DIR / "static"

# Ensure data directory exists
DATA_DIR.mkdir(exist_ok=True)

@dataclass
class DatabaseConfig:
    """Database configuration."""
    settings_file: str = os.getenv("DATABASE_PATH", str(DATA_DIR / "settings.db"))
    
@dataclass
class ServerConfig:
    """Server configuration."""
    host: str = "0.0.0.0"
    port: int = 5500
    debug: bool = False
    max_content_length: int = 16 * 1024 * 1024  # 16 MB
    
@dataclass
class SecurityConfig:
    """Security configuration."""
    secret_key: str = os.getenv("SECRET_KEY", "dev-key-change-in-production")
    password_min_length: int = 8
    
@dataclass
class APIConfig:
    """API configuration."""
    default_model: str = "gpt-4"
    default_provider: str = "DuckDuckGo"  # More reliable than Auto
    default_keyword: str = "text"
    fast_api_port: int = 1336
    
@dataclass
class FileConfig:
    """File configuration."""
    upload_folder: str = str(DATA_DIR)
    cookies_file: str = str(DATA_DIR / "cookies.json")
    proxies_file: str = str(DATA_DIR / "proxies.json")
    log_file: str = str(DATA_DIR / "freegpt4.log")
    allowed_extensions: set = None
    
    def __post_init__(self):
        if self.allowed_extensions is None:
            self.allowed_extensions = {'json'}

@dataclass
class LoggingConfig:
    """Logging configuration."""
    level: str = "INFO"
    file: Optional[str] = None
    format: str = "[%(asctime)s] %(levelname)s in %(name)s: %(message)s"
    max_file_size: int = 10 * 1024 * 1024  # 10 MB
    backup_count: int = 5
    enable_request_logging: bool = False

class Config:
    """Main configuration class."""
    
    def __init__(self):
        self.database = DatabaseConfig()
        self.server = ServerConfig()
        self.security = SecurityConfig()
        self.api = APIConfig()
        self.files = FileConfig()
        self.logging = LoggingConfig()
        
        # Load environment overrides
        self._load_env_overrides()
        
    def _load_env_overrides(self):
        """Load configuration from environment variables."""
        # Server config
        if os.getenv("PORT"):
            self.server.port = int(os.getenv("PORT"))
        if os.getenv("DEBUG"):
            self.server.debug = os.getenv("DEBUG").lower() == "true"
            
        # API config
        if os.getenv("DEFAULT_MODEL"):
            self.api.default_model = os.getenv("DEFAULT_MODEL")
        if os.getenv("DEFAULT_PROVIDER"):
            self.api.default_provider = os.getenv("DEFAULT_PROVIDER")
            
    @property
    def available_providers(self) -> Dict[str, Any]:
        """Get available providers."""
        import g4f
        return {
            "Auto": "",
            "ARTA": g4f.Provider.ARTA,
            "Blackbox": g4f.Provider.Blackbox,
            # "Chatai": g4f.Provider.Chatai,  # Temporarily disabled due to 401 errors
            "Cloudflare": g4f.Provider.Cloudflare,
            "Copilot": g4f.Provider.Copilot,
            "DeepInfra": g4f.Provider.DeepInfra,
            "DuckDuckGo": g4f.Provider.DuckDuckGo,
            "LambdaChat": g4f.Provider.LambdaChat,
            # "OIVSCodeSer0501": g4f.Provider.OIVSCodeSer0501,
            # "OpenAIFM": g4f.Provider.OpenAIFM,
            "PerplexityLabs": g4f.Provider.PerplexityLabs,
            "PollinationsAI": g4f.Provider.PollinationsAI,
            # "PollinationsImage": g4f.Provider.PollinationsImage,  # Image provider
            "TeachAnything": g4f.Provider.TeachAnything,
            "Together": g4f.Provider.Together,
            "WeWordle": g4f.Provider.WeWordle,
            "Yqcloud": g4f.Provider.Yqcloud,
        }
    
    @property
    def generic_models(self) -> list:
        """Get generic models."""
        return ["gpt-4", "gpt-4o", "gpt-4o-mini"]

# Global config instance
config = Config()
