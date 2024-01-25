# syntax=docker/dockerfile:1

# =========================================================================== #
# Dockerfile for building aTrain with Docker.
# Uses a multi-stage build.
# Expect > 10 GB overall to download and thus
# respective build times.
#
# The rebuild on code-changes should be much faster, due to caching.
#
# The file is created by using the following resources:
# - https://docs.docker.com/build/cache/
# - https://github.com/docker/awesome-compose/blob/master/nginx-wsgi-flask
# - https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
# - https://nickjanetakis.com/blog/running-docker-containers-as-a-non-root-user-with-a-custom-uid-and-gid
# - https://testdriven.io/blog/docker-best-practices/#version-docker-images
# =========================================================================== #

FROM python:3.11-slim as builder

WORKDIR /app

# Install OS-level dependencies, curl is for healthchecks
RUN apt update && \
    apt install -y --no-install-recommends git ffmpeg curl

# permissions and nonroot user for tightened security
# RUN addgroup --gid 1005 --system nonroot && \
#    adduser --no-create-home --shell /bin/false --disabled-password --uid 1005 --system --group nonroot
# USER nonroot

# copy all the build-releated files to the container
# before installation as their changes might affect the installtation layers
COPY README.md LICENSE setup.py pyproject.toml build.py ./
COPY aTrain/version.py aTrain/__init__.py ./aTrain/

# install python deps
RUN --mount=type=cache,target=/var/cache/pip \
    pip install ./ --extra-index-url https://download.pytorch.org/whl/cu118

# copy the remaining project files
# note: do not put this befre the pip install
# or the dependencies will rebuild (and download!)
# on every change in the source files
COPY aTrain/ /usr/local/lib/python3.11/site-packages/aTrain/


# we add the installed packages to our PATH
# to make their binaries available
ENV INSTALL=/usr/local/lib/python3.11/site-packages
ENV PATH="$INSTALL/bin:$PATH"


# setup gunicorn webserver to run aTrain as a service
# and use service/config.py as our wsgi configuration file
RUN pip install gunicorn
COPY service /app/service

# removing the local aTrain folder resolve
# a naming conflict when trying to run aTrain
# as main entry for gunicorn
RUN rm -r -v aTrain

EXPOSE 8080

RUN cd /usr/local/lib/python3.11/site-packages/
CMD ["gunicorn","--config", "service/config.py", "aTrain.app:app"]
