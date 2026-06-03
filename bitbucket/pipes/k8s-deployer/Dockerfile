FROM mcr.microsoft.com/azure-cli:2.59.0

ARG KUBECTL_VERSION=1.29.3
ARG HELM_VERSION=3.14.4

RUN curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | \
        tar xz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    rm -rf /tmp/linux-amd64

COPY scripts /opt/suite/scripts
COPY kubernetes/helm /opt/suite/helm
COPY pipe.sh /usr/bin/pipe.sh
RUN chmod +x /usr/bin/pipe.sh /opt/suite/scripts/*.sh

ENV CHART_PATH=/opt/suite/helm/app-chart

ENTRYPOINT ["/usr/bin/pipe.sh"]
