# Установка workflow framework Reflow

## 1. Общая информация

В качестве workflow framework был выбран Reflow.

Официальный готовый бинарный файл Reflow не удалось использовать напрямую, поэтому Reflow был собран из исходников. Для запуска использовался локальный Docker-based режим на виртуальной машине Timeweb Cloud.

## 2. Установка системных зависимостей

```bash
apt-get update
apt-get install -y git curl build-essential docker.io graphviz
systemctl enable docker
systemctl start docker
3. Установка Go

Для сборки Reflow использовался Go 1.22.2.

Проверка версии:

go version
4. Клонирование исходников
cd /root
git clone https://github.com/grailbio/reflow.git reflow-src
git clone https://github.com/grailbio/base.git base-src
5. Настройка Go modules
cd /root/reflow-src

go mod edit -replace github.com/grailbio/base=/root/base-src

go env -w GOFLAGS="-mod=mod"
go env -w GOPROXY="https://proxy.golang.org,direct"
go env -w GOSUMDB="sum.golang.org"
6. Необходимые патчи совместимости

При сборке Reflow потребовались патчи совместимости со свежими версиями Docker, AWS SDK, Prometheus и X-Ray SDK.

Основные изменения:

Docker API version в localcluster был изменён с 1.22 на 1.44;
localcluster был упрощён для локального Docker-запуска без AWS/ECR/S3;
были исправлены несовместимые вызовы Prometheus и X-Ray;
были исправлены обращения к отсутствующим AWS SDK типам;
был подключён localcluster provider;
был подключён in-memory assoc provider.
7. Сборка Reflow
cd /root/reflow-src

go build \
  -mod=mod \
  -ldflags "-X main.version=localcluster-clean-docker144" \
  -o /usr/local/bin/reflow-built \
  github.com/grailbio/reflow/cmd/reflow

Проверка:

reflow-built version
8. Конфигурация Reflow

Использованный конфиг:

docker: docker
repository: noprepo
cache: "off"
assoc: inmemassoc
taskdb: noptaskdb
metrics: nopmetrics
tracer: noptracer

Файл конфигурации:

/tmp/reflow-local-run-config.yaml
9. Запуск Hello World
reflow-built \
  -config /tmp/reflow-local-run-config.yaml \
  run -local \
  reflow/hello.rf
10. Фактический статус

Reflow runtime стартует в local mode, создаёт run ID и переходит к выполнению задачи. Однако выполнение Docker-задачи остановилось из-за несовместимости старого image resolver в Reflow с OCI manifest format, используемым современным Docker registry.

Зафиксированная ошибка:

MANIFEST_UNKNOWN: OCI manifest found, but accept header does not support OCI manifests

Данная проблема относится к совместимости Reflow и Docker registry, а не к логике биоинформатического пайплайна.
