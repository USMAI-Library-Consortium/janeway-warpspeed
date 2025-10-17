FROM alpine:3.14

RUN apk add bash git

RUN mkdir -p /vol/janeway/src/transform/xsl \
    && mkdir -p /vol/janeway/src/static

# Clone Janeway into tmp directory
WORKDIR /tmp
RUN git clone https://github.com/USMAI-Library-Consortium/janeway.git

RUN cp -r ./janeway/src/transform/xsl/ /vol/janeway/src/transform/xsl
RUN cp -r ./janeway/src/static/ /vol/janeway/src/static/

RUN rm -r janeway

ENTRYPOINT [ "/bin/bash", "-c", "cp -rf /vol/janeway/src/transform/xsl/* /vol/janeway/src/transform/xslDynamic && cp -rf /vol/janeway/src/static/* /vol/janeway/src/staticDynamic" ]