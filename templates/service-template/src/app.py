#!/usr/bin/env python3
"""
Microservice Application Template

A basic Flask application with health checks, logging, and configuration.
"""

import os
import logging
import json
from datetime import datetime
from flask import Flask, jsonify, request
from werkzeug.middleware.proxy_fix import ProxyFix

# Configure logging
logging.basicConfig(
    level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create Flask application
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

# Configuration
class Config:
    """Application configuration."""
    PORT = int(os.getenv('PORT', 8080))
    ENVIRONMENT = os.getenv('ENVIRONMENT', 'dev')
    DEBUG = ENVIRONMENT == 'dev'
    SERVICE_NAME = os.getenv('SERVICE_NAME', 'microservice')

app.config.from_object(Config)

@app.before_request
def log_request():
    """Log incoming requests."""
    logger.info(f"Request: {request.method} {request.path} from {request.remote_addr}")

@app.after_request
def log_response(response):
    """Log outgoing responses."""
    logger.info(f"Response: {response.status_code} for {request.method} {request.path}")
    return response

@app.route('/')
def index():
    """Root endpoint."""
    return jsonify({
        'service': app.config['SERVICE_NAME'],
        'version': '1.0.0',
        'environment': app.config['ENVIRONMENT'],
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/health')
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': app.config['SERVICE_NAME'],
        'environment': app.config['ENVIRONMENT'],
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/ready')
def ready():
    """Readiness check endpoint."""
    # Add any readiness checks here (database, external services, etc.)
    return jsonify({
        'status': 'ready',
        'service': app.config['SERVICE_NAME'],
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/v1/status')
def status():
    """Detailed status endpoint."""
    return jsonify({
        'service': app.config['SERVICE_NAME'],
        'version': '1.0.0',
        'environment': app.config['ENVIRONMENT'],
        'status': 'running',
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': {
            'health': '/health',
            'ready': '/ready',
            'status': '/api/v1/status'
        }
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource was not found',
        'path': request.path
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred'
    }), 500

def main():
    """Main application entry point."""
    logger.info(f"Starting {app.config['SERVICE_NAME']} in {app.config['ENVIRONMENT']} mode")
    
    app.run(
        host='0.0.0.0',
        port=app.config['PORT'],
        debug=app.config['DEBUG']
    )

if __name__ == '__main__':
    main() 