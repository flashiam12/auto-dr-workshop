#! /bin/bash 

# Primary 
export KAFKA_TOPIC="auto-dr"
export MIRROR_KAFKA_TOPIC="west-auto-dr"
export KAFKA_CLUSTER_ENV="primary"
export KAFKA_BOOTSTRAP="pkc-xxxx.us-east-1.aws.confluent.cloud:9092"
export KAFKA_USERNAME="QCUNHZTWXXXXXXXX"
export KAFKA_PASSWORD="KobCn4/5wr6w/fZAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"


# Secondary  
# export KAFKA_TOPIC="auto-dr"
# export MIRROR_KAFKA_TOPIC="east-auto-dr"
# export KAFKA_CLUSTER_ENV="secondary"
# export KAFKA_BOOTSTRAP="pkc-xxxx.us-west-2.aws.confluent.cloud:9092"
# export KAFKA_USERNAME="NUCYUTXXXXXXXXXX"
# export KAFKA_PASSWORD="c8soD1XmGkeXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

source ../.venv/bin/activate

# python producer.py

python consumer.py