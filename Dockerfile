FROM n8nio/n8n:latest

USER root

RUN apk add --no-cache python3 py3-pip

# optional: packages you want available to scripts
RUN pip3 install --break-system-packages --no-cache-dir requests pandas

USER node