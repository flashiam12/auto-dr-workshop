export CC_KAFKA_PRIMARY="pkc-q2k097.us-east-2.aws.confluent.cloud:9092"
export CC_KAFKA_SECONDARY="pkc-7yw2z1.us-east-2.aws.confluent.cloud:9092"
export CC_HEALTHCHECK_TOPIC="healthcheck"
export FAILOVER_CONFIGMAP="kafka_failover_config"
export FAILOVER_CONFIGMAP_NS="kafka"

./healthcheck/healthcheck.sh