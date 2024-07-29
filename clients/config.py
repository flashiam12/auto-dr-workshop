import os 

topic_name = os.environ.get("KAFKA_TOPIC")
mirror_topic_name = os.environ.get("MIRROR_KAFKA_TOPIC")
auto_offset_reset = os.environ.get("KAFKA_CONSUMER_OFFSET_RESET")
cluster_env = os.environ.get("KAFKA_CLUSTER_ENV")
bootstrap = os.environ.get("KAFKA_BOOTSTRAP")
sasl_ssl_key = os.environ.get("KAFKA_USERNAME")
sasl_ssl_secret = os.environ.get("KAFKA_PASSWORD")
