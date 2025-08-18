# Phoneix Usage Guide

## Quick Start

### 1. Start Phoneix
```bash
cd backend
docker-compose -f docker-compose.phoneix.yml up -d
```

### 2. Access Phoneix UI
Open browser: `http://localhost:6006`

### 3. Generate API Key
1. Go to `http://localhost:6006`
2. Navigate to Settings/API Keys section
3. Generate a new API key
4. Copy the generated key for use in your code

### 4. Stop Phoneix
```bash
docker-compose -f docker-compose.phoneix.yml down
```

## Ports
- **6006**: Phoneix web interface
- **4317**: OpenTelemetry endpoint
- **5433**: PostgreSQL database

## Python Integration

### LangChain Integration
```python
from openinference.instrumentation.langchain import LangChainInstrumentor
from phoenix.otel import register

phoenix_endpoint = "YOUR_PHOENIX_ENDPOINT"
phoenix_api_key = "YOUR_PHOENIX_API_KEY"  # Generate from http://localhost:6006

tracer_provider = register(
    project_name="your-project-name",
    endpoint=phoenix_endpoint,
    protocol="http/protobuf",
    headers={"Authorization": f"Bearer {phoenix_api_key}"}
)
LangChainInstrumentor().instrument(tracer_provider=tracer_provider)
```

### LangGraph Integration
```python
from openinference.instrumentation.langgraph import LangGraphInstrumentor
from phoenix.otel import register

phoenix_endpoint = "YOUR_PHOENIX_ENDPOINT"http://localhost:6006/v1/traces
phoenix_api_key = "YOUR_PHOENIX_API_KEY"  # Generate from http://localhost:6006

tracer_provider = register(
    project_name="your-project-name",
    endpoint=phoenix_endpoint,
    protocol="http/protobuf",
    headers={"Authorization": f"Bearer {phoenix_api_key}"}
)
LangGraphInstrumentor().instrument(tracer_provider=tracer_provider)
```

### Azure AI Integration
```python
from openinference.instrumentation.openai import OpenAIInstrumentor
from phoenix.otel import register

phoenix_endpoint = "YOUR_PHOENIX_ENDPOINT" http://localhost:6006/v1/traces
phoenix_api_key = "YOUR_PHOENIX_API_KEY"  # Generate from http://localhost:6006 ui

tracer_provider = register(
    project_name="your-project-name",
    endpoint=phoenix_endpoint,
    protocol="http/protobuf",
    headers={"Authorization": f"Bearer {phoenix_api_key}"}
)
OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
```
