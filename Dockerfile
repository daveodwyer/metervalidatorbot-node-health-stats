# syntax=docker/dockerfile:1

FROM python:3.8-slim-buster

WORKDIR /app

COPY docker_app/ ./
RUN pip3 install -r /app/requirements.txt

COPY . .

CMD [ "python3", "-u", "node_health_sync.py" ]