# Dockerfile - Odoo 18.0 with OCA modules
FROM odoo:18.0

USER root

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    python3-dev \
    build-essential \
    libpq-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    node-less \
    nodejs \
    npm \
    wkhtmltopdf \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for OCA modules
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Create directories for OCA modules and custom addons
RUN mkdir -p /mnt/oca /mnt/enterprise-addons /mnt/extra-addons

# Clone OCA repositories
COPY scripts/download_oca_modules.sh /tmp/download_oca_modules.sh
RUN chmod +x /tmp/download_oca_modules.sh && /tmp/download_oca_modules.sh

# Copy custom addons directory (if exists)
COPY ./addons/ /mnt/extra-addons/

# Copy Odoo configuration
COPY config/odoo.conf /etc/odoo/odoo.conf

# Set permissions
RUN chown -R odoo:odoo /mnt/oca /mnt/enterprise-addons /mnt/extra-addons /etc/odoo

USER odoo

# Expose Odoo ports
# 8069: Main HTTP
# 8071: HTTP (alternative)
# 8072: Longpolling/Websocket
EXPOSE 8069 8071 8072

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8069/web/health || exit 1

# Start Odoo
CMD ["odoo", "-c", "/etc/odoo/odoo.conf"]
