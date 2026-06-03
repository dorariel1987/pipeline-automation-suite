FROM hashicorp/terraform:1.7.5

RUN apk add --no-cache bash curl jq

COPY scripts /opt/suite/scripts
COPY pipe.sh /usr/bin/pipe.sh
RUN chmod +x /usr/bin/pipe.sh /opt/suite/scripts/*.sh

ENTRYPOINT ["/usr/bin/pipe.sh"]
