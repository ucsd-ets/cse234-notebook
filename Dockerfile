# 1) choose base container
# generally use the most recent tag

# base notebook, contains Jupyter and relevant tools
# See https://github.com/ucsd-ets/datahub-docker-stack/wiki/Stable-Tag 
# for a list of the most current containers we maintain
ARG BASE_CONTAINER=ghcr.io/ucsd-ets/datascience-notebook:2025.1-stable

FROM $BASE_CONTAINER

LABEL maintainer="UC San Diego ITS/ATS <datahub@ucsd.edu>"

USER root
# Install kubectl binary
RUN curl -L -o /usr/local/bin/kubectl https://dl.k8s.io/v1.35.4/bin/linux/amd64/kubectl && chmod 0755 /usr/local/bin/kubectl

# Install launch.sh (as on dsmlp-login)
COPY launch-sh-snapshot20260419.tgz /root/launch-sh-snapshot20260419.tgz
RUN cd / ; tar xvzf /root/launch-sh-snapshot20260419.tgz

# 3) install packages using notebook user
USER jovyan

ENV PATH="/opt/conda/bin:$PATH"

# Create the cse234 conda environment with updated Python
# and register new Jupyter kernel
ARG ENVNAME=cse234
ARG ENVDIR="${CONDA_DIR}/envs/${ENVNAME}"
ARG PYVER=3.12
RUN mamba create --yes -p "${ENVDIR}" python=${PYVER} pip ipykernel && \
      mamba run -p "${ENVDIR}" python -m ipykernel install --prefix /opt/conda --name="${ENVNAME}" && \
      mamba run -p "${ENVDIR}" pip install uv

# Bash profile hook to default terminal to cse234 environment
COPY conda_profile.sh /etc/profile.d/conda_profile.sh

ARG RFAI_REQ=${ENVDIR}/lib/python${PYVER}/site-packages/setup/evals/requirements-local.txt
ARG VLLM_COMMIT=72506c98349d6bcd32b4e33eec7b5513453c1502 # 0.13 is first to include x86 cpu-only
RUN mamba run -p "${ENVDIR}"  uv pip install vllm \
            --extra-index-url https://wheels.vllm.ai/${VLLM_COMMIT}/cpu \
            --index-strategy first-index --torch-backend cpu && \
      mamba run -p "${ENVDIR}" uv pip install rapidfireai loguru && \
      sed -i -e 's/^faiss-gpu-cu12/faiss-cpu/' -e 's/torch<=.*/torch/' $RFAI_REQ && \
      mamba run -p "${ENVDIR}" rapidfireai init --evals && \
      mamba run -p "${ENVDIR}" uv cache clean

# rapidfireai server expects "setup" dir to be writeable for PID files
RUN chmod 777 /opt/conda/envs/cse234/lib/python${PYVER}/site-packages/setup
    

