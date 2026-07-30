FROM nginx:alpine

COPY app/index.html /usr/share/nginx/html/index.html

ENV SERVICE_NAME=web