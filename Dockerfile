# 1) choose base container
# generally use the most recent tag

# base notebook, contains Jupyter and relevant tools
# See https://github.com/ucsd-ets/datahub-docker-stack/wiki/Stable-Tag 
# for a list of the most current containers we maintain
ARG BASE_CONTAINER=ghcr.io/ucsd-ets/scipy-ml-notebook:2025.1-stable

FROM $BASE_CONTAINER

LABEL maintainer="UC San Diego ITS/ATS <datahub@ucsd.edu>"

# 3) install packages using notebook user
USER jovyan

ENV PATH="/opt/conda/bin:$PATH"

# Create the cse234 conda environment with updated Python
# and register new Jupyter kernel
ARG ENVNAME=cse234
ARG ENVDIR="${CONDA_DIR}/envs/${ENVNAME}"
ARG PYVER=3.13
RUN mamba create --yes -p "${ENVDIR}" python=${PYVER} pip ipykernel && \
      mamba run -p "${ENVDIR}" python -m ipykernel install --prefix /opt/conda --name="${ENVNAME}"

# Add course-specific packages to the cse234 conda environment
RUN mamba run -p "${ENVDIR}" pip install rapidfireai openai
    
#RUN apt-get -y install htop

# Override command to disable running jupyter notebook at launch
# CMD ["/bin/bash"]
