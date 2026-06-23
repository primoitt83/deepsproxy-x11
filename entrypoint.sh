#!/bin/bash
if [ -n "$VNC_PASSWORD" ]; then
    echo "$VNC_PASSWORD" | vncpasswd -f > /home/vncuser/.vnc/passwd
    chmod 600 /home/vncuser/.vnc/passwd
fi

# Usar envsubst sem especificar variáveis (substitui todas as variáveis de ambiente)
envsubst < /home/vncuser/supervisord.conf.template > /home/vncuser/supervisord.conf

## Run supervisor
supervisord --nodaemon -c /home/vncuser/supervisord.conf