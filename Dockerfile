ARG BASE_IMAGE=ruby:3.3.1-alpine
FROM ${BASE_IMAGE}

# Create lobsters user and group.
RUN set -xe; \
    addgroup -S lobsters; \
    adduser -S -h /lobsters -s /bin/bash -G lobsters lobsters;

# Install needed runtime dependencies.
RUN set -xe; \
    chown -R lobsters:lobsters /lobsters; \
    apk add --no-cache --update --virtual .runtime-deps \
        mariadb-connector-c \
        bash \
        nodejs \
        npm \
        yarn \
        sqlite-libs \
        tzdata \
        shared-mime-info;

# Change shell to bash
SHELL ["/bin/bash", "-c"]

# Install needed development dependencies
RUN set -xe; \
    apk add --no-cache --virtual .build-deps \
        build-base \
        curl \
        gcc \
        git \
        linux-headers \
        mariadb-connector-c-dev \
        mariadb-dev \
        mariadb-client \
        sqlite-dev \
        ruby-dev \
        musl-dev \
        g++ \
        zlib-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        pkgconfig \
        postgresql-dev;

# Copy Gemfile to container
COPY --chown=lobsters:lobsters Gemfile Gemfile.lock /lobsters/

# Install gems
RUN set -xe; \
    export PATH=/lobsters/.gem/ruby/3.3.1/bin:$PATH; \
    export SUPATH=$PATH; \
    export GEM_HOME="/lobsters/.gem"; \
    export GEM_PATH="/lobsters/.gem"; \
    export BUNDLE_PATH="/lobsters/.bundle"; \
    cd /lobsters; \
    su lobsters -c "gem install bundler --user-install"; \
    su lobsters -c "bundle config unset force_ruby_platform"; \
    su lobsters -c "bundle config build.nokogiri --use-system-libraries"; \
    su lobsters -c "bundle config set no-cache 'true'"; \
    su lobsters -c "bundle install"; \
    mv /lobsters/Gemfile /lobsters/Gemfile.bak; \
    mv /lobsters/Gemfile.lock /lobsters/Gemfile.lock.bak;

# Copy application code
COPY --chown=lobsters:lobsters . /lobsters/

# Set proper permissions and move assets
RUN set -xe; \
    mv /lobsters/Gemfile.bak /lobsters/Gemfile; \
    mv /lobsters/Gemfile.lock.bak /lobsters/Gemfile.lock; \
    chown -R lobsters:lobsters /lobsters; \
    chmod +x /lobsters/docker-entrypoint.sh;

# Drop down to unprivileged user
USER lobsters

# Set working directory
WORKDIR /lobsters/

# Set environment variables
ENV MARIADB_HOST="db" \
    MARIADB_PORT="3306" \
    MARIADB_PASSWORD="password" \
    MARIADB_USER="root" \
    MYSQL_ROOT_PASSWORD="password" \
    LOBSTER_DATABASE="lobsters" \
    LOBSTER_HOSTNAME="localhost" \
    LOBSTER_SITE_NAME="Example News" \
    RAILS_ENV="development" \
    GEM_HOME="/lobsters/.gem" \
    GEM_PATH="/lobsters/.gem" \
    BUNDLE_PATH="/lobsters/.bundle" \
    RAILS_MAX_THREADS="5" \
    RAILS_LOG_TO_STDOUT="1" \
    PATH="/lobsters/.gem/ruby/3.3.1/bin:$PATH"

# Expose HTTP port
EXPOSE 3000

# Execute entry script
CMD ["bash", "/lobsters/docker-entrypoint.sh"]
