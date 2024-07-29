FROM python:3.11-slim

WORKDIR /app

COPY . /app/

RUN pip install -r requirements.txt

# ARG PROXY_ADDRESS
# ARG KAFKA_BOOTSTRAP
# ARG KAFKA_REST

# ENV PROXY_ADDRESS=${PROXY_ADDRESS}
# ENV KAFKA_BOOTSTRAP=${KAFKA_BOOTSTRAP}
# ENV KAFKA_REST=${KAFKA_REST}

# RUN export PROXY_ADDRESS="primary-kafka-proxy.kafka.svc.cluster.local"
# RUN export KAFKA_BOOTSTRAP="pkc-k85ygg.us-east-1.aws.confluent.cloud"
# RUN export KAFKA_REST="pkc-k85ygg.us-east-1.aws.confluent.cloud"

# RUN echo "${PROXY_ADDRESS} ${KAFKA_BOOTSTRAP}" >> /etc/hosts
# RUN echo "${PROXY_ADDRESS} ${KAFKA_REST}" >> /etc/hosts

