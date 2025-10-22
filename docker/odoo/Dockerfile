FROM odoo:18.0-20251008

USER root

# Install system dependencies for OCA modules
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libpq-dev \
    wkhtmltopdf \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for OCA modules
RUN pip3 install --no-cache-dir \
    num2words \
    xlsxwriter \
    xlrd \
    openpyxl \
    pysftp \
    boto3 \
    redis \
    python-dateutil \
    pytz

# Copy custom entrypoint
COPY entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8069/web/health || exit 1

# Switch back to odoo user for runtime (non-root)
USER odoo

ENTRYPOINT ["/entrypoint-custom.sh"]
CMD ["odoo"]
