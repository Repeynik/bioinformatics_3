# Домашнее задание 3. Пайплайн поиска генетических вариантов

## 1. Цель работы

Цель работы — разработать и описать пайплайн первичной обработки данных секвенирования и поиска генетических вариантов. В рамках работы были выбраны короткие paired-end чтения Illumina, выполнены контроль качества, выравнивание на референсный геном, оценка доли выровненных чтений, принятие решения о качестве выравнивания и запуск variant calling.

## 2. Выбранный стек

Вариант стека:

- тип секвенирования: Illumina paired-end reads;
- инструмент выравнивания: BWA MEM;
- workflow framework: Reflow;
- исполнение: cloud-native среда на виртуальной машине Timeweb Cloud;
- дополнительные инструменты: FastQC, samtools, freebayes, Docker, Graphviz.

## 3. Исходные данные

Для работы был выбран набор чтений:

- accession: SRR826444;
- объект: Escherichia coli K-12 MG1655;
- тип данных: Illumina MiSeq paired-end whole genome sequencing;
- ссылка NCBI SRA: https://www.ncbi.nlm.nih.gov/sra/SRR826444

FASTQ-файлы были загружены через ENA FTP, так как SRA Toolkit в текущей среде не смог обратиться к внешним сервисам NCBI.

Использованные ссылки:

- ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR826/SRR826444/SRR826444_1.fastq.gz
- ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR826/SRR826444/SRR826444_2.fastq.gz

Референсный геном:

- организм: Escherichia coli str. K-12 substr. MG1655;
- assembly: GCF_000005845.2;
- sequence: NC_000913.3;
- файл в проекте: data/ref/ecoli.fa.

## 4. Общая схема пайплайна

Пайплайн реализует следующую последовательность действий:

1. загрузка paired-end FASTQ-файлов;
2. запуск FastQC для первичной проверки качества чтений;
3. индексация референсного генома с помощью bwa index;
4. индексация референса с помощью samtools faidx;
5. выравнивание чтений на референсный геном с помощью bwa mem;
6. конвертация SAM в BAM через samtools view;
7. получение статистики выравнивания через samtools flagstat;
8. парсинг процента mapped reads;
9. проверка условия: если mapped reads > 90%, результат считается OK;
10. при статусе OK выполняется сортировка BAM;
11. создаётся индекс BAM;
12. запускается freebayes;
13. формируется VCF-файл с вариантами.

## 5. Bash-реализация

Основная bash-реализация находится в файле:

- scripts/run_bash_pipeline.sh

Парсер результата samtools flagstat находится в файле:

- scripts/parse_flagstat.sh

Парсер извлекает процент mapped reads из строки samtools flagstat вида:

```
... mapped (...%)
```

и возвращает числовое значение процента.

## 6. Результат bash-пайплайна

Фактический результат выполнения bash-пайплайна:

- sample: SRR826444;
- mapped reads: 96.80%;
- статус по алгоритму: OK;
- порог качества: 90%;
- VCF-файл: results/variants/SRR826444.vcf;
- размер VCF-файла: 3.2M;
- число variant records в VCF: 7906.

Так как 96.80% > 90%, результат выравнивания был признан достаточным для продолжения пайплайна. После этого были выполнены сортировка BAM, индексация BAM и variant calling с помощью freebayes.

## 7. Reflow-реализация

Для workflow-части был выбран Reflow. Исходный код Reflow был собран из исходников, так как готовая версия имела ограничения при локальном запуске и работе с современным Docker.

Файлы Reflow:

- reflow/hello.rf — минимальный Hello World pipeline;
- reflow/mapping_qc_pipeline.rf — Reflow-описание пайплайна mapping quality control и variant calling.

Reflow был настроен на локальное выполнение через Docker на cloud VM. Локальный runtime Reflow стартует, создаёт run ID и доходит до стадии запуска задачи. Фактический запуск задачи был остановлен из-за несовместимости старого Reflow-клиента с форматом Docker OCI manifest при обращении к локальному Docker registry.

Фактическая зафиксированная ошибка:

```
MANIFEST_UNKNOWN: OCI manifest found, but accept header does not support OCI manifests
```

и ранее:

```
tool.imageDigestReference index.docker.io/library/bio-hw3:latest: UNAUTHORIZED
```

Таким образом, Reflow-часть представлена кодом workflow, инструкцией установки, логами запуска и описанием ограничения совместимости. Основной биоинформатический пайплайн был выполнен через bash-реализацию.

## 8. Docker-образ

Для воспроизводимости был создан Docker image со следующими инструментами:

- FastQC;
- bwa;
- samtools;
- freebayes;
- graphviz;
- gawk.

Dockerfile находится в корне репозитория.

Образ был собран локально и загружен в локальный Docker registry:

```
localhost:5000/bio-hw3
```

Локальный registry был поднят командой:

```
docker run -d -p 5000:5000 --restart=always --name local-registry registry:2
```

## 9. Визуализация пайплайна

Граф пайплайна сохранён в файлах:

- results/reflow/mapping_qc_dag.dot;
- results/reflow/mapping_qc_dag.svg.

Визуализация построена в виде DAG. DAG показывает зависимости между шагами пайплайна: какие операции должны быть выполнены до других операций. В отличие от обычной блок-схемы, DAG не описывает императивную логику построчно, а показывает граф вычислительных зависимостей. Это ближе к workflow framework, где задачи запускаются на основании доступности входных файлов и зависимостей.

## 10. Структура репозитория

Основные файлы репозитория:

```
README.md
Dockerfile
scripts/download_data.sh
scripts/parse_flagstat.sh
scripts/run_bash_pipeline.sh
reflow/hello.rf
reflow/mapping_qc_pipeline.rf
docs/framework_installation.md
docs/reflow_status.md
docs/visualization.md
results/flagstat/SRR826444.mapped_percent.txt
results/flagstat/SRR826444.status.txt
results/flagstat/SRR826444.bash_summary.txt
results/flagstat/SRR826444.flagstat.txt
results/variants/SRR826444.vcf
results/logs/reflow_hello.log
results/logs/reflow_hello_debug.log
results/logs/reflow_mapping_qc.log
results/reflow/mapping_qc_dag.dot
results/reflow/mapping_qc_dag.svg
```

Крупные исходные данные FASTQ, референсные индексы и промежуточные BAM/SAM-файлы не добавляются в git. Они воспроизводятся командами из скриптов и описаны в README.

## 11. Итог

В результате работы был подготовлен воспроизводимый пайплайн анализа paired-end Illumina reads для E. coli. Bash-версия пайплайна была успешно выполнена до получения VCF-файла. Процент выровненных чтений составил 96.80%, что выше заданного порога 90%. Workflow-версия на Reflow была реализована в виде DSL-кода и доведена до стадии запуска локального runtime на cloud VM; выполнение задачи остановилось из-за несовместимости старого Reflow с современным Docker manifest format.

---

## 12. Дополнение: фактическое выполнение Reflow workflow

Первоначальная Reflow-реализация с передачей FASTQ и FASTA как внешних параметров запускалась, но останавливалась на этапе staging локальных файлов:

```text
blob.Bucket : operation not supported: no implementation for scheme

Это ограничение было связано с local-конфигурацией Reflow и использованием noprepo: Reflow local runtime запускался, но не мог корректно передать локальные input-файлы в Docker executor через blob layer.

Для обхода этого ограничения был подготовлен embedded-вариант Reflow workflow:

reflow/mapping_qc_embedded.rf

В этом варианте FASTQ-файлы и референсный геном были заранее помещены внутрь Docker image:

localhost:5000/bio-hw3-data:docker-v2

В image были включены:

SRR826444_1.fastq.gz;
SRR826444_2.fastq.gz;
ecoli.fa.

После этого Reflow workflow был успешно выполнен в режиме run -local.

12.1. Что выполнил Reflow workflow

Файл reflow/mapping_qc_embedded.rf выполняет внутри одной Reflow Docker-задачи:

FastQC для paired-end FASTQ;
bwa index;
samtools faidx;
bwa mem;
samtools view;
samtools flagstat;
парсинг процента mapped reads;
проверку условия mapped percent > 90;
samtools sort;
samtools index;
freebayes;
формирование итогового отчёта.
12.2. Фактические признаки успешного выполнения

В логе Reflow были зафиксированы следующие стадии:

scheduler: task ... submitted
executor: completed exec
scheduler task ... returning task with state: done
<- mapping_qc_embedded.Main ... ok exec 32s 616B

Это означает, что задача была отправлена scheduler-ом, выполнена Docker executor-ом и завершилась со статусом ok.

После завершения задачи Reflow CLI всё ещё завершался с ошибкой:

runtime error: invalid memory address or nil pointer dereference

Эта ошибка возникала после выполнения Docker-задачи, на этапе финальной обработки результата CLI. Она не отменяет факт выполнения workflow, так как задача уже получила статус ok.

12.3. Итоговый результат Reflow workflow

Итоговый результат Reflow workflow сохранён в файле:

results/reflow/reflow_embedded_result.txt

Содержимое результата:

Sample: SRR826444
Mapped percent: 96.80
Status: OK
Variant count: 7906
Finished: yes

Полный samtools flagstat, полученный в Reflow workflow:

297200 + 0 in total (QC-passed reads + QC-failed reads)
296036 + 0 primary
0 + 0 secondary
1164 + 0 supplementary
0 + 0 duplicates
0 + 0 primary duplicates
287686 + 0 mapped (96.80% : N/A)
286522 + 0 primary mapped (96.79% : N/A)
296036 + 0 paired in sequencing
148018 + 0 read1
148018 + 0 read2
275612 + 0 properly paired (93.10% : N/A)
281576 + 0 with itself and mate mapped
4946 + 0 singletons (1.67% : N/A)
0 + 0 with mate mapped to a different chr
0 + 0 with mate mapped to a different chr (mapQ>=5)

Таким образом, Reflow workflow подтвердил тот же результат, что и bash-пайплайн: процент mapped reads составил 96.80%, что выше порога 90%, поэтому статус анализа — OK. После этого workflow выполнил сортировку BAM, индексацию BAM и запуск freebayes. Количество variant records в результате Reflow workflow составило 7906.
