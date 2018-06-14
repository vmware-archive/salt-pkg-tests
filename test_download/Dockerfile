FROM alpine:latest

RUN apk --no-cache add python3 rpm
RUN pip3 --no-cache-dir install --upgrade pip
RUN pip3 --no-cache-dir install bs4 requests
RUN mkdir -p /testing

ADD ./download.py /testing/download.py
