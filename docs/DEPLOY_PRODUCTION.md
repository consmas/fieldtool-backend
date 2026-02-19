# Production Deployment (Docker Compose)

This guide assumes a single host running Docker + Docker Compose. The API is still an HTTP server, so it must run a Rails process (even though it is API-only).

## Recommended Compose

Use three services: `db`, `redis`, and `api`.

```yaml
services:
  db:
    image: postgres:16-alpine
    container_name: consmas_fieldtool_pg
    restart: unless-stopped
    environment:
      POSTGRES_DB: consmas_fieldtool_production
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d consmas_fieldtool_production"]
      interval: 5s
      timeout: 3s
      retries: 10

  redis:
    image: redis:7-alpine
    container_name: consmas_fieldtool_redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

  api:
    container_name: consmas_fieldtool_api
    build: .
    env_file:
      - .env
    environment:
      RAILS_ENV: production
      DATABASE_URL: postgresql://postgres:postgres@db:5432/consmas_fieldtool_production
      REDIS_URL: redis://redis:6379/0
    command: bin/rails server -b 0.0.0.0 -p 3000
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    ports:
      - "3000:3000"
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:
```

## Required Environment

Ensure your `.env` has:

```
RAILS_MASTER_KEY=your_master_key_here
GOOGLE_ROADS_API_KEY=your_google_roads_api_key
APP_HOST=your_domain_or_ip
APP_PORT=3000
```

Do not commit the master key.

## First-Time Boot

```sh
docker-compose down
docker-compose up -d --build
docker-compose logs -f --tail=200 api
```

Run migrations (and seed if needed):

```sh
docker-compose exec api bin/rails db:prepare
```

## Basic Health Check

```sh
curl -i http://127.0.0.1:3000/up
```

## Notes

- The API is still a web server. It must be reachable by your frontend or reverse proxy.
- If you need HTTPS, place Nginx/Caddy in front of the `api` service.
- If you deploy to a VPS, ensure port 3000 is open or proxy it.
- If you use ActiveStorage with S3/DigitalOcean Spaces, configure `config/storage.yml` and set your env vars.

## Optional: Run Sidekiq

If you want background jobs, add:

```yaml
  sidekiq:
    container_name: consmas_fieldtool_sidekiq
    build: .
    env_file:
      - .env
    environment:
      RAILS_ENV: production
      DATABASE_URL: postgresql://postgres:postgres@db:5432/consmas_fieldtool_production
      REDIS_URL: redis://redis:6379/0
    command: bundle exec sidekiq
    depends_on:
      - redis
      - db
    restart: unless-stopped
```

## Webhooks + Sidekiq Notes

- Set these environment variables in production:
  - `SIDEKIQ_REDIS_URL=redis://redis:6379/1`
  - `SIDEKIQ_CONCURRENCY=10`
  - `WEBHOOK_MAX_RETRIES=5`
  - `WEBHOOK_CIRCUIT_BREAKER_THRESHOLD=10`
  - `WEBHOOK_ENFORCE_HTTPS=true`
- Sidekiq Web UI is mounted at `/admin/sidekiq` and requires admin user credentials (email/password).
- Sidekiq health endpoint:
  - `GET /admin/sidekiq/health`
