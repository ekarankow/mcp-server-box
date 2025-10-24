# Use a small official Python image
FROM python:3.13-slim

# Metadata
LABEL org.opencontainers.image.source="https://github.com/box-community/mcp-server-box"

# Avoid Python writing .pyc files and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create app directory
WORKDIR /app

# Install system deps needed to build/install Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Copy pyproject and source; this allows Docker layer caching for deps
# (If repository uses other lockfiles, you can copy them too)
COPY pyproject.toml uv.lock /app/
COPY src /app/src
COPY README.md /app/README.md

# Install the package (and its dependencies) into the container
# pip will read pyproject.toml (PEP517). If your project requires build backends
# (poetry/flit), pip will invoke them. This keeps container simple.
RUN pip install  pip setuptools wheel \
 && pip install .

# Expose default port used by server (can be overridden)
EXPOSE 8080

# Default env vars placeholders (should be provided at runtime)
ENV BOX_CLIENT_ID="" \
    BOX_CLIENT_SECRET="" \
    BOX_REDIRECT_URL="http://localhost:8000/callback" \
    BOX_MCP_SERVER_AUTH_TOKEN=""

# Use the Python module directly to avoid requiring 'uv' in container.
# The README suggests running with 'uv run src/mcp_server_box.py', but running the
# script with python is equivalent for container usage.
# If you prefer uv, install it and change the CMD accordingly.
CMD ["python", "src/mcp_server_box.py", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8080"]
