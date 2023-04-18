FROM golang:1.19

COPY . /home

RUN cd /home/api/cmd && go build -o api
