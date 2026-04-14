# 1) choose base container
# generally use the most recent tag

# base notebook, contains Jupyter and relevant tools
# See https://github.com/ucsd-ets/datahub-docker-stack/wiki/Stable-Tag 
# for a list of the most current containers we maintain
ARG BASE_CONTAINER=ghcr.io/ucsd-ets/datascience-notebook:2025.1-stable

FROM $BASE_CONTAINER

LABEL maintainer="UC San Diego ITS/ATS <datahub@ucsd.edu>"

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

ARG VLLM_COMMIT=72506c98349d6bcd32b4e33eec7b5513453c1502 # 0.13 is first to include x86 cpu-only
RUN mamba run -p "${ENVDIR}"  uv pip install vllm \
            --extra-index-url https://wheels.vllm.ai/${VLLM_COMMIT}/cpu \
            --index-strategy first-index --torch-backend cpu && \
      mamba run -p "${ENVDIR}" uv pip install rapidfireai loguru && \
      mamba run -p "${ENVDIR}" rapidfireai init --evals && \
      mamba run -p "${ENVDIR}" uv cache clean

# rapidfireai server expects "setup" dir to be writeable for PID files
RUN chmod 777 /opt/conda/envs/cse234/lib/python${PYVER}/site-packages/setup
    
#RUN apt-get -y install htop

# Override command to disable running jupyter notebook at launch
# CMD ["/bin/bash"]
