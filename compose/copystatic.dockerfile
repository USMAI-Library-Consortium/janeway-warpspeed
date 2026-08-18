FROM alpine:3.14

ARG CLONE_REPOSITORY_URL
ARG CLONE_TAG_VERSION

RUN apk add bash git

RUN mkdir -p /vol/janeway/src/transform/xsl \
    && mkdir -p /vol/janeway/src/static

# Clone Janeway into tmp directory
WORKDIR /tmp
RUN git clone --branch ${CLONE_TAG_VERSION} ${CLONE_REPOSITORY_URL}

RUN cp -rp ./janeway/src/transform/xsl/ /vol/janeway/src/transform/xsl
RUN cp -rp ./janeway/src/static/ /vol/janeway/src/static/

RUN rm -r janeway

ENTRYPOINT [ "/bin/bash", "-c", "cp -rfp /vol/janeway/src/transform/xsl/* /vol/janeway/src/transform/xslDynamic && cp -rfp /vol/janeway/src/static/* /vol/janeway/src/staticDynamic" ]