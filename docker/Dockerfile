# Dockerfile - Odoo 18.0 + OCA Modules
FROM odoo:18.0

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    python3-dev \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for Supabase integration
RUN pip3 install --no-cache-dir \
    supabase-py==2.10.0 \
    python-dotenv==1.0.0 \
    requests==2.31.0 \
    psycopg2-binary==2.9.9 \
    postgrest==0.16.8 \
    realtime==2.0.0

# Create directories for modules
RUN mkdir -p /mnt/oca /mnt/extra-addons /var/log/odoo

# Copy and run OCA download script
COPY scripts/download_oca_modules.sh /tmp/
RUN chmod +x /tmp/download_oca_modules.sh && /tmp/download_oca_modules.sh

# Copy custom addons
COPY addons /mnt/extra-addons

# Set proper permissions
RUN chown -R odoo:odoo /mnt/oca /mnt/extra-addons /var/log/odoo

USER odoo

# Expose ports
EXPOSE 8069 8072

CMD ["odoo"]
