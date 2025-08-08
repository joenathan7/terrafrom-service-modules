# Service Template Repository

This is a template repository for microservice applications. It contains a basic application structure with CI/CD pipelines.

## Repository Structure

```
├── src/                    # Application source code
│   ├── app.py             # Main application file
│   ├── requirements.txt   # Python dependencies
│   └── Dockerfile         # Docker configuration
├── tests/                 # Test files
│   └── test_app.py       # Unit tests
├── docs/                  # Documentation
├── scripts/               # Helper scripts
│   ├── build.sh          # Build script
│   └── deploy.sh         # Deployment script
└── .github/              # GitHub Actions workflows
    └── workflows/
        └── deploy.yml    # Deployment workflow
```

## Quick Start

1. **Clone this repository** (it will be created automatically when a new microservice is deployed)
2. **Install dependencies**:
   ```bash
   pip install -r src/requirements.txt
   ```
3. **Run the application**:
   ```bash
   python src/app.py
   ```
4. **Run tests**:
   ```bash
   python -m pytest tests/
   ```

## Application Features

This template includes:

- **Flask Web Framework**: For building REST APIs
- **Docker Support**: Containerized deployment
- **Health Checks**: Built-in health endpoint
- **Logging**: Structured logging with JSON format
- **Configuration**: Environment-based configuration
- **Testing**: Unit test framework with pytest

## Environment Variables

Set the following environment variables:

- `PORT`: Application port (default: 8080)
- `ENVIRONMENT`: Environment (dev, staging, production)
- `LOG_LEVEL`: Logging level (debug, info, warning, error)

## Development

1. **Install development dependencies**:
   ```bash
   pip install -r requirements-dev.txt
   ```

2. **Run linting**:
   ```bash
   flake8 src/
   ```

3. **Run tests**:
   ```bash
   pytest tests/
   ```

## Deployment

The application can be deployed using:

- **Docker**: `docker build -t app . && docker run -p 8080:8080 app`
- **Google Cloud Run**: Automatic deployment via GitHub Actions
- **Kubernetes**: Using the provided manifests

## Contributing

1. Create a feature branch
2. Make your changes
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details 