FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates webhook && \
    curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.18.0/openshift-client-linux.tar.gz | tar zx && \
    mv oc kubectl /usr/local/bin/ && \
    chmod +x /usr/local/bin/oc /usr/local/bin/kubectl && \
    mkdir -p /etc/webhook && \
    echo "[]" > /etc/webhook/hooks.json && \
    apt-get purge -y curl bash git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /usr/share/locale /var/cache/*

RUN groupadd -g 65535 webhook && \
    useradd -u 65535 -g 65535 -s /usr/sbin/nologin -d /nonexistent webhook && \
    chown -R webhook:webhook /etc/webhook

USER 65535:65535

VOLUME ["/etc/webhook"]

ENTRYPOINT ["/usr/bin/webhook"]
CMD ["-hooks", "/etc/webhook/hooks.json", "-port", "9000", "-verbose"]
