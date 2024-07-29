#! /bin/bash

PRIMARY_BROKER=$CC_KAFKA_PRIMARY  # Replace with your primary Kafka broker address
SECONDARY_BROKER=$CC_KAFKA_SECONDARY  # Replace with your secondary Kafka broker address

PRIMARY_BROKER_PRODUCER_CONFIG=./config/producer-primary.properties
SECONDARY_BROKER_PRODUCER_CONFIG=./config/producer-secondary.properties
PRIMARY_BROKER_CONSUMER_CONFIG=./config/consumer-primary.properties
SECONDARY_BROKER_CONSUMER_CONFIG=./config/consumer-secondary.properties

TOPIC=$CC_HEALTHCHECK_TOPIC  # The topic used for availability check
CONFIGMAP_NAME=$FAILOVER_CONFIGMAP  # ConfigMap name
NAMESPACE=$FAILOVER_CONFIGMAP_NS  # Kubernetes namespace

check_kafka_broker() {
    BROKER=$1
    TOPIC=$2
    PRODUCER_CONFIG=$3
    CONSUMER_CONFIG=$4

    # Produce a test message and consume a test message in parallel
    PRODUCE_CMD="kafka-console-producer.sh --bootstrap-server $BROKER --topic $TOPIC --producer.config $PRODUCER_CONFIG <<< 'test-message'"
    CONSUME_CMD="kafka-console-consumer.sh --bootstrap-server $BROKER --topic $TOPIC --from-beginning --max-messages 1 --consumer.config $CONSUMER_CONFIG --timeout-ms 5000"

    # Run the commands in parallel
    eval "$PRODUCE_CMD > /dev/null 2>&1" &
    PRODUCE_PID=$!

    eval "$CONSUME_CMD > /dev/null 2>&1" &
    CONSUME_PID=$!

    # Wait for the commands to complete
    wait $PRODUCE_PID
    PRODUCE_STATUS=$?
    wait $CONSUME_PID
    CONSUME_STATUS=$?

    # Check if both the producer and consumer commands succeeded
    if [ $PRODUCE_STATUS -eq 0 ] && [ $CONSUME_STATUS -eq 0 ]; then
        echo "Broker $BROKER is available"
        return 0
    else
        echo "Broker $BROKER is not available"
        return 1
    fi
}

get_state() {
    kubectl get configmap $CONFIGMAP_NAME -n $NAMESPACE -o jsonpath='{.data.connection-state}'
}

# Function to update the ConfigMap
update_configmap() {
    PRIMARY_REPLICAS=$1
    PRIMARY_CONSUMER_REPLICAS=$2
    SECONDARY_REPLICAS=$3
    SECONDARY_CONSUMER_REPLICAS=$4
    CONNECTION_STATE=$5

    kubectl patch configmap $CONFIGMAP_NAME -n $NAMESPACE --type merge -p "{
        \"data\": {
            \"primary-producer-replicas\": \"$PRIMARY_REPLICAS\",
            \"primary-consumer-replicas\": \"$PRIMARY_CONSUMER_REPLICAS\",
            \"secondary-producer-replicas\": \"$SECONDARY_REPLICAS\",
            \"secondary-consumer-replicas\": \"$SECONDARY_CONSUMER_REPLICAS\",
            \"connection-state\": \"$CONNECTION_STATE\"
        }
    }"
}

get_configmap_value() {
    local configmap_name=$1
    local namespace=$2
    local key=$3

    # Fetch the value of the key from the ConfigMap
    local value=$(kubectl get configmap "$configmap_name" -n "$namespace" -o jsonpath="{.data.$key}" 2>/dev/null)

    # Check if the key exists and the command succeeded
    if [ $? -eq 0 ] && [ -n "$value" ]; then
        echo "$value"
    else
        echo "Key '$key' not found or ConfigMap does not exist."
        return 1
    fi
}


check_kafka_broker $PRIMARY_BROKER $TOPIC $PRIMARY_BROKER_PRODUCER_CONFIG $PRIMARY_BROKER_CONSUMER_CONFIG
PRIMARY_AVAILABLE=$?

# Check secondary Kafka broker
check_kafka_broker $SECONDARY_BROKER $TOPIC $SECONDARY_BROKER_PRODUCER_CONFIG $SECONDARY_BROKER_CONSUMER_CONFIG
SECONDARY_AVAILABLE=$?

CONNECTION_STATE=$(get_configmap_value "$CONFIGMAP_NAME" "$NAMESPACE" "connection-state")

# Initialize variables for replica counts
PRIMARY_PRODUCER_REPLICAS=0
PRIMARY_CONSUMER_REPLICAS=0
SECONDARY_PRODUCER_REPLICAS=0
SECONDARY_CONSUMER_REPLICAS=0

# Determine replica counts based on broker availability
if [ $PRIMARY_AVAILABLE -eq 0 ]; then
    PRIMARY_PRODUCER_REPLICAS=1
    PRIMARY_CONSUMER_REPLICAS=1
fi

if [ $SECONDARY_AVAILABLE -eq 0 ]; then
    SECONDARY_PRODUCER_REPLICAS=1
    SECONDARY_CONSUMER_REPLICAS=1
fi

# Update the ConfigMap based on the availability of the brokers
if [ $PRIMARY_AVAILABLE -ne 0 ] && [ $SECONDARY_AVAILABLE -eq 0 ]; then

    if [ $CONNECTION_STATE -eq "HEALTHY" ]; then
        # For Failover
        SECONDARY_PRODUCER_REPLICAS=1
        SECONDARY_CONSUMER_REPLICAS=1
        CONNECTION_STATE="FAILOVER"

    elif [$CONNECTION_STATE -eq "FAILOVER"]; then
        SECONDARY_PRODUCER_REPLICAS=1
        SECONDARY_CONSUMER_REPLICAS=1

    elif [$CONNECTION_STATE -eq "FAILBACK"]; then
        CONNECTION_STATE="FAILOVER"

    fi

elif [ $PRIMARY_AVAILABLE -eq 0 ] && [ $SECONDARY_AVAILABLE -eq 0 ]; then

    if [ $CONNECTION_STATE -eq "HEALTHY" ]; then
        SECONDARY_PRODUCER_REPLICAS=0
        SECONDARY_CONSUMER_REPLICAS=0

    elif [$CONNECTION_STATE -eq "FAILOVER"]; then
        PRIMARY_PRODUCER_REPLICAS=0
        SECONDARY_CONSUMER_REPLICAS=0
        PRIMARY_CONSUMER_REPLICAS=0
        CONNECTION_STATE="FAILBACK"
    
    elif [$CONNECTION_STATE -eq "FAILBACK"]; then
        SECONDARY_PRODUCER_REPLICAS=0

else
    SECONDARY_PRODUCER_REPLICAS=0
    SECONDARY_CONSUMER_REPLICAS=0
fi

update_configmap $PRIMARY_PRODUCER_REPLICAS $PRIMARY_CONSUMER_REPLICAS $SECONDARY_PRODUCER_REPLICAS $SECONDARY_CONSUMER_REPLICAS $CONNECTION_STATE

echo "ConfigMap updated based on the availability of Kafka brokers."