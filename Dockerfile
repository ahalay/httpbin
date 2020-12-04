FROM python:alpine3.13 AS compile-image

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

ADD Pipfile Pipfile.lock /httpbin/
WORKDIR /httpbin

RUN apk update \ 
    && apk add --no-cache --virtual .build-deps gcc build-base linux-headers ca-certificates python3-dev libffi-dev libressl-dev musl-dev git bash \
    && pip install cffi \
    && pip3 install --no-cache-dir pipenv \
    && /bin/bash -c "pip3 install --no-cache-dir -r <(pipenv lock -r)" \
    && apk del .build-deps

ADD . /httpbin
RUN pip3 install --no-cache-dir /httpbin


FROM python:alpine3.13
COPY --from=compile-image /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

LABEL name="httpbin"
LABEL version="0.9.2"
LABEL description="A simple HTTP service."
LABEL org.kennethreitz.vendor="Kenneth Reitz"

EXPOSE 8080

CMD ["gunicorn", "-b", "0.0.0.0:8080", "httpbin:app", "-k", "gevent", "--worker-tmp-dir", "/dev/shm"]
