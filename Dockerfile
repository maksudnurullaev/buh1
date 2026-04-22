FROM perl:5.38-slim

# System libraries required by Perl modules (EV needs libev, DBD::SQLite needs build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libev-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Perl dependencies before copying the rest of the source so this
# layer is cached as long as cpanfile does not change.
COPY cpanfile .
RUN cpanm --notest --installdeps .

# Copy application source
COPY . .

# Ensure the database and client-data directories exist
RUN mkdir -p db/clients

EXPOSE 3000

# Set sane defaults; override via env or docker-compose
ENV MOJO_MODE=production

# Run Mojolicious in foreground daemon mode.
# For high-concurrency production use, replace with:
#   hypnotoad -f script/buh1
CMD ["perl", "script/buh1", "daemon", "-l", "http://*:3000"]
