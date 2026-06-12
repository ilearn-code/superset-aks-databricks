# Production-ready Apache Superset with Databricks Integration
# Includes ODBC drivers, Databricks connectors, and security enhancements

FROM apache/superset:2.1.0

# Build arguments for metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=2.1.0

# Labels for container metadata
LABEL org.opencontainers.image.title="Apache Superset with Databricks"
LABEL org.opencontainers.image.description="Production-ready Superset with Azure Databricks integration"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL maintainer="dataplatform@gmail.com"

# Set environment variables
ENV SUPERSET_HOME=/app/superset \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=superset \
    SUPERSET_PORT=8088 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Switch to root for system installations
USER root

# Install system dependencies for database drivers
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    make \
    unixodbc \
    unixodbc-dev \
    curl \
    gnupg \
    wget \
    ca-certificates \
    apt-transport-https \
    pkg-config \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC Driver 17 for SQL Server (required for Databricks)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt /app/requirements.txt

# Install Python packages with fixed setuptools version for compatibility
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir "setuptools<69.0.0" "setuptools_scm<9.0.0" wheel && \
    pip install --no-cache-dir -r /app/requirements.txt && \
    # Install Databricks connectors
    pip install --no-cache-dir \
        "apache-superset[databricks]" \
        "databricks-dbapi[sqlalchemy]" \
        databricks-sql-connector \
        pyodbc \
    # Database drivers
        psycopg2-binary \
        mysqlclient \
        pymssql \
    # Authentication
        authlib \
        azure-identity \
        msal \
    # Caching and async
        redis \
        celery[redis] \
        gevent \
    # Utilities
        flask-cors \
        gunicorn[gevent] \
        cryptography \
    && pip cache purge

# Copy application configuration
# COPY ../src/superset/config.py /app/pythonpath/superset_config.py
# COPY ../src/superset/security.py /app/pythonpath/security_config.py
# COPY ../src/superset/custom_views.py /app/pythonpath/custom_views.py

# Copy initialization scripts
# COPY ../src/scripts/*.sh /app/scripts/
# RUN chmod +x /app/scripts/*.sh

# Create necessary directories
RUN mkdir -p /app/superset_home \
    /app/superset_home/uploads \
    /app/superset_home/logs \
    && chown -R superset:superset /app/superset_home

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:${SUPERSET_PORT}/health || exit 1

# Switch back to superset user for security
USER superset

# Set working directory
WORKDIR /app

# Expose Superset port
EXPOSE 8088

# Use gunicorn for production
CMD ["gunicorn", \
     "--bind", "0.0.0.0:8088", \
     "--workers", "4", \
     "--worker-class", "gevent", \
     "--threads", "2", \
     "--timeout", "120", \
     "--limit-request-line", "0", \
     "--limit-request-field_size", "0", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "superset.app:create_app()"]