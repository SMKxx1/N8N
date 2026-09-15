# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1: build a self-contained Python tree.
#
# The n8n runtime image is a hardened Alpine 3.24 image with apk-tools removed
# (`apk del apk-tools` in n8n's base Dockerfile), so `apk add` cannot be run
# against it. Python is installed into a separate rootfs here and copied into
# the final image as plain files, which leaves every base package untouched.
# ---------------------------------------------------------------------------
FROM alpine:3.24 AS python-builder

RUN apk add --no-cache python3 py3-pip

RUN apk add --no-cache --initdb --root /rootfs \
        --keys-dir /etc/apk/keys \
        --repositories-file /etc/apk/repositories \
        python3 py3-pip

# Python packages available to your workflows. Add to this list as needed.
RUN pip install --break-system-packages --no-cache-dir \
        --prefix /rootfs/usr \
        requests

# Console scripts ship with a `#!/usr/bin/python3` shebang; repoint them at
# the interpreter's real location in the final image.
RUN sed -i '1s|^#!/usr/bin/python3|#!/opt/py/usr/bin/python3|' /rootfs/usr/bin/* 2>/dev/null || true

# ---------------------------------------------------------------------------
# Stage 2: n8n + Python
# ---------------------------------------------------------------------------
FROM n8nio/n8n:latest

USER root
COPY --from=python-builder /rootfs/usr /opt/py/usr
USER node

# Appended rather than prepended, so nothing in the base image is shadowed.
ENV PATH="${PATH}:/opt/py/usr/bin" \
    LD_LIBRARY_PATH="/opt/py/usr/lib"
