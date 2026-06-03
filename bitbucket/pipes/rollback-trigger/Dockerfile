FROM mcr.microsoft.com/azure-cli:2.59.0

ARG KUBECTL_VERSION=1.29.3
RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl

COPY scripts /opt/suite/scripts
COPY pipe.sh /usr/bin/pipe.sh
RUN chmod +x /usr/bin/pipe.sh /opt/suite/scripts/*.sh

ENTRYPOINT ["/usr/bin/pipe.sh"]
