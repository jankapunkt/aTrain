# syntax=docker/dockerfile:1
# =========================================================================== #
# Dockerfile for building aTrain with Docker.
#
# The rebuild on code-changes should be much faster, due to caching.
# The file is created by using the following resources:
# - https://docs.docker.com/build/cache/
# - https://github.com/docker/awesome-compose/blob/master/nginx-wsgi-flask
# - https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
# - https://nickjanetakis.com/blog/running-docker-containers-as-a-non-root-user-with-a-custom-uid-and-gid
# - https://testdriven.io/blog/docker-best-practices/#version-docker-images
# - https://www.howtogeek.com/devops/understanding-the-dockerfile-volume-instruction/
# - https://medium.com/@DahlitzF/run-python-applications-as-non-root-user-in-docker-containers-by-example-cba46a0ff384
# =========================================================================== #

FROM python:3.11-slim as builder

# Install OS-level dependencies, curl is for healthchecks
RUN apt update && \
    apt install -y --no-install-recommends ffmpeg

# update pip before switching to user mode
RUN pip install --upgrade pip

# use non-root user for tightened security
RUN adduser --disabled-password nonroot

# switch user to nonroot and set default workdir
# to /home/nonroot which is owned by nontoo:nonroot
USER nonroot
WORKDIR /home/nonroot

# copy all the build-releated files to the container
# before installation as their changes might affect the installtation layers
COPY --chown=nonroot:nonroot README.md LICENSE setup.py pyproject.toml build.py ./
COPY --chown=nonroot:nonroot aTrain/version.py aTrain/__init__.py ./aTrain/

# install python deps
RUN pip install --user ./ --extra-index-url https://download.pytorch.org/whl/cu118

# setup gunicorn webserver to run aTrain as a service
# and use service/config.py as our wsgi configuration file
RUN pip install --user gunicorn

# copy the remaining project files
# note: do not put this befre the pip install
# or the dependencies will rebuild (and download!)
# on every change in the source files
COPY --chown=nonroot:nonroot aTrain/ ./aTrain/
COPY --chown=nonroot:nonroot service/ ./service/

# we add the installed packages to our PATH
# to make their binaries available
ENV PATH="/home/nonroot/.local/bin/:${PATH}"

# attach volume mount point(s)
# in order to keep data persistent
# VOLUME ["/home/nonroot/Documents/aTrain/", "/usr/local/lib/python3.11/site-packages/aTrain/models/"]

# running gunicorn as our webserver
EXPOSE 8080
CMD ["gunicorn","--config", "service/config.py", "aTrain.app:app"]
