# FROM python:3.13-slim-bookworm

# ENV PYTHONUNBUFFERED=1 \
#     PYTHONDONTWRITEBYTECODE=1 \
#     UV_LINK_MODE=copy \
#     UV_COMPILE_BYTECODE=1 \
#     UV_NO_DEV=1 \
#     UV_FROZEN=1 \
#     PYTHONPATH=/app \
#     PATH="/root/.local/bin:$PATH"

# RUN apt-get update \
#     && apt-get install -y --no-install-recommends curl ca-certificates \
#     && rm -rf /var/lib/apt/lists/* \
#     && curl -LsSf https://astral.sh/uv/install.sh | sh

# WORKDIR /app

# COPY pyproject.toml uv.lock ./
# RUN uv sync --frozen --no-install-project --no-dev

# COPY . .

# RUN uv sync --frozen --no-dev

# EXPOSE 8003

# CMD ["uv", "run", "python", "-m", "bin.api"]

FROM python:3.13-slim-bookworm AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR /app

COPY pyproject.toml uv.lock ./
RUN /root/.local/bin/uv sync --frozen --no-dev


# -------- runtime --------
FROM python:3.13-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app /app
COPY --from=builder /root/.local /root/.local

ENV PATH="/app/.venv/bin:/root/.local/bin:$PATH"

COPY . .

EXPOSE 8003

# 🔥 ВАЖНО: запускаем API + consumer одновременно
CMD ["sh", "-c", "\
alembic upgrade head && \
python -m bin.consumer & \
python -m bin.api \
"]