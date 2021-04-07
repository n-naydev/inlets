#! /bin/sh

echo $@

update_certificates() {
  if [ -e /usr/share/ca-certificates/server.crt ]; then
    echo "server.crt" >> /etc/ca-certificates.conf
    update-ca-certificates
  fi
}

start() {
  if [ $1 == "client" ]; then
    update_certificates
  fi
  /usr/bin/inlets $@
}

start $@