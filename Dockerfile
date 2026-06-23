 ## debian-bookworm
FROM node:22-bookworm-slim as builder

## Install x11 dependencies
RUN \
    DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install --no-install-recommends -y \
    curl \
    git \
    ca-certificates && \
    update-ca-certificates && \
    git clone https://github.com/pedrofariasx/deepsproxy.git /app && \
    cd /app && \
    npm ci && \
    npm run build

FROM node:22-bookworm-slim as release

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV XDG_RUNTIME_DIR=/tmp/runtime-vncuser

# Instala apenas o essencial
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        tigervnc-standalone-server \
        tigervnc-common \
        tigervnc-tools \
        dbus-x11 \
        fluxbox \
        eterm \
        x11-utils \
        websockify \
        supervisor \
        gettext \
        novnc \
        procps && \
    rm -rf /var/lib/apt/lists/*

# Cria usuário
RUN \
    useradd -m -s /bin/bash vncuser && \
    echo "vncuser:vncuser" | chpasswd

# Criar diretórios e configurar TUDO como root
RUN \
    mkdir -p /home/vncuser/.vnc && \
    mkdir -p /home/vncuser/.fluxbox && \
    mkdir -p /tmp/runtime-vncuser && \
    touch /home/vncuser/.Xauthority && \
    mkdir -p /home/vncuser/app && \
    chmod 0700 /tmp/runtime-vncuser && \
    echo "password" | vncpasswd -f > /home/vncuser/.vnc/passwd && \
    chmod 600 /home/vncuser/.vnc/passwd

# Copiar arquivos como root
COPY ./menu /home/vncuser/.fluxbox/menu
COPY ./xstartup /home/vncuser/.vnc/xstartup
COPY ./entrypoint.sh /entrypoint.sh
## Copiar projeto
COPY --from=builder /app/node_modules /home/vncuser/app/node_modules
COPY --from=builder /app/dist /home/vncuser/app/dist
COPY --from=builder /app/package*.json /home/vncuser/app
COPY --from=builder /app/src/ /home/vncuser/app/src/
# Copiar supervisord
COPY ./supervisord.conf /home/vncuser/supervisord.conf.template

## Playwright pro vncuser
WORKDIR /home/vncuser/app
RUN \
    export PLAYWRIGHT_BROWSERS_PATH=/home/vncuser/.cache/ms-playwright && \
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 && \
    npm install && \
    npx playwright install chromium --with-deps && \
    ## permissoes
    chown -R vncuser:vncuser /home/vncuser && \
    chmod 600 /home/vncuser/.Xauthority && \
    chmod +x /home/vncuser/.vnc/xstartup && \
    chmod +x /entrypoint.sh

# Mudar para usuário vncuser
USER vncuser
WORKDIR /home/vncuser/app

EXPOSE 3000
EXPOSE 8080
EXPOSE 5901

# Entrypoint
ENTRYPOINT ["/entrypoint.sh" ]