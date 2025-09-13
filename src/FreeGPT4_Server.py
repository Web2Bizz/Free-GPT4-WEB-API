"""FreeGPT4 Web API - A Web API for GPT-4.

Repo: github.com/aledipa/FreeGPT4-WEB-API
By: Alessandro Di Pasquale
GPT4Free Credits: github.com/xtekky/gpt4free
"""

import os
import argparse
import threading
import json
from pathlib import Path
from typing import Optional

from flask import Flask, request, render_template, redirect, jsonify, session
from werkzeug.utils import secure_filename
from g4f.api import run_api

from config import config
from database import db_manager
from ai_service import ai_service
from utils.logging import logger, setup_logging
from utils.exceptions import (
    FreeGPTException, 
    ValidationError, 
    AIProviderError,
    FileUploadError
)
from utils.validation import (
    validate_file_upload,
    validate_port,
    validate_proxy_format,
    sanitize_input
)
from utils.helpers import (
    load_json_file,
    save_json_file,
    parse_proxy_url,
    safe_filename
)
from functools import wraps

# Initialize Flask app
app = Flask(__name__)
app.secret_key = config.security.secret_key
app.config['UPLOAD_FOLDER'] = config.files.upload_folder
app.config['MAX_CONTENT_LENGTH'] = config.server.max_content_length

# Set up logging
if os.getenv('LOG_LEVEL'):
    setup_logging(level=os.getenv('LOG_LEVEL'))

logger.info("FreeGPT4 Web API - Starting server...")
logger.info("Repo: github.com/aledipa/FreeGPT4-WEB-API")
logger.info("By: Alessandro Di Pasquale")
logger.info("GPT4Free Credits: github.com/xtekky/gpt4free")

def log_request(f):
    """Decorator to log API requests if request logging is enabled."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if hasattr(server_manager, 'args') and server_manager.args.enable_request_logging:
            # Log request details
            client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr)
            user_agent = request.headers.get('User-Agent', 'Unknown')
            
            logger.info(f"Request: {request.method} {request.path} from {client_ip}")
            logger.debug(f"User-Agent: {user_agent}")
            logger.debug(f"Headers: {dict(request.headers)}")
            
            # Log request data (be careful with sensitive data)
            if request.method == "GET":
                logger.debug(f"Query params: {dict(request.args)}")
            elif request.is_json:
                data = request.get_json()
                # Don't log the full question for privacy
                if data and server_manager.args.keyword in data:
                    question_preview = data[server_manager.args.keyword][:100] + "..." if len(data[server_manager.args.keyword]) > 100 else data[server_manager.args.keyword]
                    logger.debug(f"JSON data: {server_manager.args.keyword}='{question_preview}'")
            elif request.form:
                logger.debug(f"Form data: {dict(request.form)}")
        
        return f(*args, **kwargs)
    return decorated_function

class ServerArgumentParser:
    """Parse and manage server arguments."""
    
    def __init__(self):
        self.parser = self._create_parser()
        self.args = None
    
    def _create_parser(self) -> argparse.ArgumentParser:
        """Create argument parser."""
        parser = argparse.ArgumentParser(description="FreeGPT4 Web API Server")
        
        parser.add_argument(
            "--remove-sources",
            action='store_true',
            help="Remove the sources from the response",
        )
        parser.add_argument(
            "--enable-gui",
            action='store_true',
            help="Use a graphical interface for settings",
        )
        parser.add_argument(
            "--enable-proxies",
            action='store_true',
            help="Use one or more proxies to avoid being blocked or banned",
        )
        parser.add_argument(
            "--enable-history",
            action='store_true',
            help="Enable the history of the messages",
        )
        parser.add_argument(
            "--password",
            action='store',
            help="Set or change the password for the settings page [mandatory in docker environment]",
        )
        parser.add_argument(
            "--cookie-file",
            action='store',
            type=str,
            help="Use a cookie file",
        )
        parser.add_argument(
            "--file-input",
            action='store_true',
            help="Add the file as input support",
        )
        parser.add_argument(
            "--port",
            action='store',
            type=int,
            help="Change the port (default: 5500)",
        )
        parser.add_argument(
            "--model",
            action='store',
            type=str,
            help="Change the model (default: gpt-4)",
        )
        parser.add_argument(
            "--provider",
            action='store',
            type=str,
            help="Change the provider (default: Auto)",
        )
        parser.add_argument(
            "--keyword",
            action='store',
            type=str,
            help="Add the keyword support",
        )
        parser.add_argument(
            "--system-prompt",
            action='store',
            type=str,
            help="Use a system prompt to 'customize' the answers",
        )
        parser.add_argument(
            "--enable-fast-api",
            action='store_true',
            help="Use the fast API standard (PORT 1336 - compatible with OpenAI integrations)",
        )
        parser.add_argument(
            "--log-level",
            action='store',
            type=str,
            choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
            default='INFO',
            help="Set the logging level (default: INFO)",
        )
        parser.add_argument(
            "--log-file",
            action='store',
            type=str,
            help="Enable logging to file (specify file path)",
        )
        parser.add_argument(
            "--log-format",
            action='store',
            type=str,
            help="Custom log format string",
        )
        parser.add_argument(
            "--enable-request-logging",
            action='store_true',
            help="Enable detailed request/response logging",
        )
        
        return parser
    
    def parse_args(self):
        """Parse command line arguments."""
        self.args, _ = self.parser.parse_known_args()
        return self.args

class ServerManager:
    """Manage server configuration and state."""
    
    def __init__(self, args):
        self.args = args
        self.fast_api_thread = None
        self._setup_working_directory()
        self._merge_settings_with_args()
        self._setup_logging()
    
    def _setup_working_directory(self):
        """Set up working directory."""
        script_path = Path(__file__).resolve()
        os.chdir(script_path.parent)
    
    def _setup_logging(self):
        """Set up logging configuration."""
        try:
            # Set up logging with arguments
            log_file = None
            if self.args.log_file:
                log_file = Path(self.args.log_file)
            
            # Reconfigure logging
            global logger
            logger = setup_logging(
                level=self.args.log_level,
                log_file=log_file,
                log_format=self.args.log_format,
                max_file_size=config.logging.max_file_size,
                backup_count=config.logging.backup_count
            )
            
            logger.info(f"Logging configured - Level: {self.args.log_level}")
            if log_file:
                logger.info(f"Logging to file: {log_file}")
            if self.args.enable_request_logging:
                logger.info("Request logging enabled")
                
        except Exception as e:
            logger.error(f"Failed to setup logging: {e}")
    
    def _merge_settings_with_args(self):
        """Merge database settings with command line arguments."""
        try:
            settings = db_manager.get_settings()
            
            # Update args with database settings if not specified
            if not self.args.keyword:
                self.args.keyword = settings.get("keyword", config.api.default_keyword)
            
            if not self.args.file_input:
                self.args.file_input = settings.get("file_input", True)
            
            if not self.args.port:
                self.args.port = int(settings.get("port", config.server.port))
            
            if not self.args.provider:
                self.args.provider = settings.get("provider", config.api.default_provider)
            
            if not self.args.model:
                self.args.model = settings.get("model", config.api.default_model)
            
            if not self.args.cookie_file:
                self.args.cookie_file = settings.get("cookie_file", config.files.cookies_file)
            
            if not self.args.remove_sources:
                self.args.remove_sources = settings.get("remove_sources", True)
            
            if not self.args.system_prompt:
                self.args.system_prompt = settings.get("system_prompt", "")
            
            if not self.args.enable_history:
                self.args.enable_history = settings.get("message_history", False)
            
            if not self.args.enable_proxies:
                self.args.enable_proxies = settings.get("proxies", False)
            
            
            # Handle fast API
            if self.args.enable_fast_api or settings.get("fast_api", False):
                self.start_fast_api()
            
            
            # Handle logging settings
            if not hasattr(self.args, 'log_level'):
                self.args.log_level = settings.get("log_level", config.logging.level)
            if not hasattr(self.args, 'log_file'):
                self.args.log_file = settings.get("log_file", config.logging.file)
            if not hasattr(self.args, 'log_format'):
                self.args.log_format = settings.get("log_format", config.logging.format)
            if not hasattr(self.args, 'enable_request_logging'):
                self.args.enable_request_logging = settings.get("enable_request_logging", config.logging.enable_request_logging)
            
        except Exception as e:
            logger.error(f"Failed to merge settings: {e}")
            # Use defaults
            self.args.keyword = self.args.keyword or config.api.default_keyword
            self.args.port = self.args.port or config.server.port
            self.args.provider = self.args.provider or config.api.default_provider
            self.args.model = self.args.model or config.api.default_model
    
    def start_fast_api(self):
        """Start Fast API in background thread."""
        if self.fast_api_thread and self.fast_api_thread.is_alive():
            return
        
        logger.info(f"Starting Fast API on port {config.api.fast_api_port}")
        self.fast_api_thread = threading.Thread(target=run_api, name="fastapi", daemon=True)
        self.fast_api_thread.start()
    
    def setup_password(self):
        """No password setup needed - authentication disabled."""
        logger.info("Authentication disabled - no password setup required")
# Routes and handlers
@app.errorhandler(404)
def handle_not_found(e):
    """Handle 404 errors."""
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(FreeGPTException)
def handle_freegpt_exception(e):
    """Handle FreeGPT exceptions."""
    logger.error(f"FreeGPT error: {e}")
    return jsonify({"error": str(e)}), 400

@app.errorhandler(Exception)
def handle_general_exception(e):
    """Handle general exceptions."""
    from werkzeug.exceptions import NotFound
    
    # Don't log 404 errors as unexpected errors
    if isinstance(e, NotFound):
        return jsonify({"error": "Not found"}), 404
    
    logger.error(f"Unexpected error: {e}", exc_info=True)
    return jsonify({"error": "Internal server error"}), 500

@app.route("/", methods=["GET", "POST"])
@log_request
def index():
    """Main API endpoint for chat completion."""
    import asyncio
    
    async def _async_index():
        try:
            # Get current settings
            settings = db_manager.get_settings()
            
            # Extract question from request
            question = None
            if request.method == "GET":
                question = request.args.get(server_manager.args.keyword)
            else:
                # Handle POST request - check for JSON body first, then file upload
                if request.is_json:
                    # Handle JSON body
                    data = request.get_json()
                    if data and server_manager.args.keyword in data:
                        question = data[server_manager.args.keyword]
                elif 'file' in request.files:
                    # Handle file upload
                    file = request.files['file']
                    is_valid, error_msg = validate_file_upload(file, config.files.allowed_extensions)
                    if not is_valid:
                        raise FileUploadError(error_msg)
                    
                    question = file.read().decode('utf-8')
                else:
                    # Handle form data
                    question = request.form.get(server_manager.args.keyword)
            
            if not question:
                return "<p id='response'>Please enter a question</p>"
            
            # Sanitize input
            question = sanitize_input(question, 10000)  # 10KB limit
            
            # Use default username
            username = "user"
            
            # Generate AI response
            response_text = await ai_service.generate_response(
                message=question,
                username=username,
                use_history=server_manager.args.enable_history,
                remove_sources=server_manager.args.remove_sources,
                use_proxies=server_manager.args.enable_proxies,
                cookie_file=server_manager.args.cookie_file
            )
            
            logger.info(f"Generated response for user '{username}' ({len(response_text)} chars)")
            return response_text
            
        except FreeGPTException as e:
            logger.error(f"API error: {e}")
            return f"<p id='response'>Error: {e}</p>"
        except Exception as e:
            logger.error(f"Unexpected API error: {e}", exc_info=True)
            return "<p id='response'>Internal server error</p>"
    
    # Run the async function
    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        return loop.run_until_complete(_async_index())
    except Exception as e:
        logger.error(f"Async execution error: {e}", exc_info=True)
        return f"<p id='response'>Error: AI API call failed: {e}</p>"
    finally:
        loop.close()


@app.route("/settings", methods=["GET"])
def settings():
    """Settings page."""
    if not server_manager.args.enable_gui:
        return "The GUI is disabled. Use the --enable-gui argument to enable it."
    
    try:
        # Prepare template data
        template_data = {
            "username": "admin",
            "virtual_users": False,
            "providers": config.available_providers,
            "generic_models": config.generic_models,
            "data": db_manager.get_settings()
        }
        
        # Load proxies
        proxies_path = Path(config.files.proxies_file)
        template_data["proxies"] = load_json_file(proxies_path, [])
        
        return render_template("settings.html", **template_data)
        
    except Exception as e:
        logger.error(f"Settings page error: {e}")
        return f"Error: {e}"

@app.route("/save", methods=["POST"])
def save_settings():
    """Save admin settings."""
    try:
        
        # Process settings update
        settings_update = {}
        
        # Boolean settings
        bool_fields = [
            "file_input", "remove_sources", "message_history", 
            "proxies", "fast_api", "enable_request_logging"
        ]
        for field in bool_fields:
            settings_update[field] = request.form.get(field) == "true"
        
        # String settings
        string_fields = ["port", "model", "keyword", "provider", "system_prompt", "log_level", "log_file", "log_format"]
        for field in string_fields:
            value = request.form.get(field, "")
            if field == "port":
                is_valid, error_msg = validate_port(value)
                if not is_valid:
                    raise ValidationError(f"Invalid port: {error_msg}")
            elif field == "log_level":
                if value and value not in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
                    raise ValidationError("Invalid log level. Must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL")
            elif field == "log_file" and value:
                # Validate log file path
                try:
                    log_path = Path(value)
                    log_path.parent.mkdir(parents=True, exist_ok=True)
                except Exception as e:
                    raise ValidationError(f"Invalid log file path: {e}")
            settings_update[field] = sanitize_input(value)
        
        # Handle password update
        new_password = request.form.get("new_password", "")
        if new_password:
            confirm_password = request.form.get("confirm_password", "")
            if new_password != confirm_password:
                raise ValidationError("Passwords do not match")
            if len(new_password) < 8:
                raise ValidationError("Password must be at least 8 characters long")
            settings_update["password"] = new_password
        
        
        # Handle file upload
        if 'cookie_file' in request.files:
            file = request.files['cookie_file']
            if file.filename:
                is_valid, error_msg = validate_file_upload(file, config.files.allowed_extensions)
                if not is_valid:
                    raise FileUploadError(error_msg)
                
                filename = safe_filename(file.filename)
                file_path = Path(app.config['UPLOAD_FOLDER']) / filename
                file.save(str(file_path))
                settings_update["cookie_file"] = str(file_path)
        
        # Handle proxies
        if request.form.get("proxies") == "true":
            proxies = []
            i = 1
            while f"proxy_{i}" in request.form:
                proxy_url = request.form.get(f"proxy_{i}", "").strip()
                if proxy_url:
                    if not validate_proxy_format(proxy_url):
                        raise ValidationError(f"Invalid proxy format: {proxy_url}")
                    
                    proxy_dict = parse_proxy_url(proxy_url)
                    if proxy_dict:
                        proxies.append(proxy_dict)
                i += 1
            
            # Save proxies to file
            proxies_path = Path(config.files.proxies_file)
            save_json_file(proxies_path, proxies)
        
        
        # Save settings
        db_manager.update_settings(settings_update)
        
        # Restart Fast API if needed
        if settings_update.get("fast_api") and not server_manager.fast_api_thread:
            server_manager.start_fast_api()
        
        # Reconfigure logging if logging settings changed
        logging_fields = ["log_level", "log_file", "log_format", "enable_request_logging"]
        if any(field in settings_update for field in logging_fields):
            server_manager._setup_logging()
            logger.info("Logging configuration updated")
        
        logger.info("Settings saved successfully")
        return "Settings saved and applied successfully!"
        
    except FreeGPTException as e:
        logger.error(f"Settings save error: {e}")
        return f"Error: {e}"
    except Exception as e:
        logger.error(f"Unexpected settings save error: {e}")
        return "Error: Failed to save settings"


@app.route("/models", methods=["GET"])
def get_models():
    """Get available models for a provider."""
    provider = request.args.get("provider", "Auto")
    return jsonify(ai_service.get_available_models(provider))


def main():
    """Main entry point."""
    try:
        # Parse arguments
        arg_parser = ServerArgumentParser()
        args = arg_parser.parse_args()
        
        # Initialize server manager
        global server_manager
        server_manager = ServerManager(args)
        
        # Set up password if needed
        server_manager.setup_password()
        
        logger.info(f"Server configuration:")
        logger.info(f"  Port: {args.port}")
        logger.info(f"  Provider: {args.provider}")
        logger.info(f"  Model: {args.model}")
        logger.info(f"  GUI enabled: {args.enable_gui}")
        logger.info(f"  History enabled: {args.enable_history}")
        logger.info(f"  Proxies enabled: {args.enable_proxies}")
        
        # Start server
        app.run(
            host=config.server.host,
            port=args.port,
            debug=config.server.debug
        )
        
    except KeyboardInterrupt:
        logger.info("Server shutdown requested by user")
    except Exception as e:
        logger.error(f"Server startup failed: {e}", exc_info=True)
        exit(1)

if __name__ == "__main__":
    main()