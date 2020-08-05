
FROM opendatacube/geobase:wheels-3.0.4  as env_builder

ARG py_env_path=/env

RUN mkdir -p /conf
COPY requirements.txt /conf/
RUN pip install numpy

RUN env-build-tool new /conf/requirements.txt ${py_env_path} /wheels

FROM opendatacube/geobase:runner-3.0.4
ARG py_env_path

COPY --from=env_builder $py_env_path $py_env_path
COPY --from=env_builder /bin/tini /bin/tini

RUN apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing --no-install-recommends \
  # developer convenience
  postgresql-client-10 \
  less \
  vim \
  git \
  && rm -rf /var/lib/apt/lists/*


RUN pip install hdmedians==0.13
RUN export GDAL_DATA=$(gdal-config --datadir)
ENV LC_ALL=C.UTF-8 \
    PATH="/env/bin:$PATH"

RUN pip install hdmedians
RUN pip install GDAL==3.0.4
RUN pip uninstall sat-search -y
RUN pip install sat-search

RUN useradd -m -s /bin/bash -N jovyan
USER root

WORKDIR /notebooks

ENTRYPOINT ["/bin/tini", "--"]

CMD ["jupyter", "notebook", "--allow-root", "--ip='0.0.0.0'" "--NotebookApp.token='secretpassword'"]
