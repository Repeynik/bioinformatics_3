FROM condaforge/miniforge3:latest

RUN mamba install -y \
    -c conda-forge \
    -c bioconda \
    fastqc \
    bwa \
    samtools \
    freebayes \
    graphviz \
    gawk \
    && mamba clean -a -y

WORKDIR /work
