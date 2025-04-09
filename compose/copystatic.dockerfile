FROM alpine:3.14

RUN apk add --no-cache bash

RUN mkdir -p /vol/janeway/src/transform/xsl \
    && mkdir -p /vol/janeway/src/static

COPY janeway/src/transform/xsl/ /vol/janeway/src/transform/xsl
COPY janeway/src/static/ /vol/janeway/src/static/

ENTRYPOINT [ "/bin/bash", "-c", "cp -rf /vol/janeway/src/transform/xsl/* /vol/janeway/src/transform/xslDynamic && cp -rf /vol/janeway/src/static/* /vol/janeway/src/staticDynamic" ]