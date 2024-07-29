#! /bin/bash 

# Primary 
export KAFKA_TOPIC="auto-dr"
export MIRROR_KAFKA_TOPIC="west-auto-dr"
export KAFKA_CLUSTER_ENV="primary"
export KAFKA_BOOTSTRAP="pkc-k85ygg.us-east-1.aws.confluent.cloud:9092"
export KAFKA_USERNAME="QCUNHZTW325QNHSK"
export KAFKA_PASSWORD="KobCn4/5wr6w/fZAT2jUs1sqsL50f1oMJZl4nCYlNAzwfjnI6QzdtgM4iMqdDy6B"


# Secondary  
# export KAFKA_TOPIC="auto-dr"
# export MIRROR_KAFKA_TOPIC="east-auto-dr"
# export KAFKA_CLUSTER_ENV="secondary"
# export KAFKA_BOOTSTRAP="pkc-pg707m.us-west-2.aws.confluent.cloud:9092"
# export KAFKA_USERNAME="NUCYUTUEHINK67VM"
# export KAFKA_PASSWORD="c8soD1XmGke6UyiJmvXG4vPE1elFlRFve8hO0RQwSlIFpWo4jovgwxXbpsl45V5w"

source ../.venv/bin/activate

# python producer.py

python consumer.py