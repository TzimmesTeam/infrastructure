# Zimmes · локальная инфраструктура

Для запуска нужны Docker Compose 2.23.1+ и доступ к registry с готовыми образами. Compose загружает приложения из GHCR или настроенного зеркала, а PostgreSQL, NATS, SeaweedFS, LocalStack и AWS CLI — из Docker Hub по умолчанию. Все файлы, которые Compose монтирует с хоста, лежат внутри `infrastructure/devops`.

Настройте `.env` по [.env.example](.env.example). `ZIMMES_IMAGE_NAMESPACE` задаёт общий префикс имени образов, а `ZIMMES_IMAGE_TAG` — их тег. Для разных тегов или registry задайте полные ссылки в `CONTROL_PLANE_IMAGE`, `DATA_PREP_IMAGE` и `EVENT_BRIDGE_IMAGE`. Сейчас соглашение по умолчанию — `ghcr.io/tzimmesteam/<service>:latest`. Указывайте существующие теги релиза или digest. Для приватных пакетов нужен `docker login` в соответствующий registry. [Доступ к GHCR](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

```bash
docker compose pull
docker compose up -d --wait
docker compose ps -a
curl -fsS http://127.0.0.1:8089/readyz
curl -fsS http://127.0.0.1:8080/health/ready
```

`postgres-migrate` и `s3-init` — разовые задачи. Успешное состояние для них — `Exited (0)`. Активная миграция находится в [devops/postgres/migrations](devops/postgres/migrations/0001_simple_state_machine.sql), инициализация очередей — в [devops/data-prep/localstack](devops/data-prep/localstack/init.sh), тестовый CSV на 55 сделок — в [devops/cashflow/fixtures](devops/cashflow/fixtures/prep-deals.csv).

| Сервис | Адрес с хоста | Назначение |
| --- | --- | --- |
| Control Plane | `127.0.0.1:8089` | API запуска расчёта и статусов |
| Data Prep | `127.0.0.1:8080` | HTTP-проверки состояния обработки |
| SeaweedFS | `127.0.0.1:9000`, Iceberg REST `127.0.0.1:8181` | Общий S3 для CSV, Parquet и отчётов, каталог Iceberg для витрины |
| Консоль SeaweedFS | `127.0.0.1:12535` | Просмотр бакетов, файлов и таблиц Iceberg |
| PostgreSQL | `127.0.0.1:5432` | Состояние расчётов |
| NATS | `127.0.0.1:4222`, мониторинг `127.0.0.1:8222` | Задачи расчётов и результаты |

Все приложения в сети Compose используют один S3 endpoint `http://s3:8333`. SeaweedFS предоставляет каталог Iceberg `warehouse` через тот же контейнер. Постоянные сервисы перезапускаются с `restart: on-failure` при ненулевом коде выхода.

Event Bridge и LocalStack доступны по именам сервисов внутри сети Compose. `docker compose down` останавливает стек с сохранением именованных томов.

Веб-консоль SeaweedFS доступна на хосте, когда в `.env` заданы отдельные `S3_ADMIN_PASSWORD` и `S3_VIEWER_PASSWORD`. После сохранения параметров примените их командой `docker compose up -d --wait s3`. Войдите под пользователем `viewer` с паролем `S3_VIEWER_PASSWORD`. Раздел **Object Store → Buckets** показывает обычные бакеты, **Object Store → S3 Tables** открывает каталог таблиц, а **Files** позволяет перейти в `/buckets/irrbb-curated-local` и посмотреть Parquet.
