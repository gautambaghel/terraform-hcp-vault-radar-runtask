FROM python:3.10

WORKDIR /app

COPY ./app /app/

RUN pip install -r requirements.txt

EXPOSE 80

RUN apt-get update && apt-get install -y wget unzip

RUN if [ "$(uname -m)" = "x86_64" ]; then \
        wget https://releases.hashicorp.com/vault-radar/0.7.0/vault-radar_0.7.0_linux_amd64.zip && \
        unzip vault-radar_0.7.0_linux_amd64.zip && \
        mv vault-radar /usr/local/bin && \
        rm vault-radar_0.7.0_linux_amd64.zip; \
    else \
        wget https://releases.hashicorp.com/vault-radar/0.7.0/vault-radar_0.7.0_linux_arm64.zip && \
        unzip vault-radar_0.7.0_linux_arm64.zip && \
        mv vault-radar /usr/local/bin && \
        rm vault-radar_0.7.0_linux_arm64.zip; \
    fi

CMD [ "python", "main.py" ]
