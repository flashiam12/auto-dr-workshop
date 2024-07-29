from confluent_kafka import Consumer
from config import * 
import logging
import json
import time
import asyncio

logging.basicConfig()
logging.root.setLevel(logging.NOTSET)

logger = logging.getLogger("kafka-consumer-{}".format(cluster_env))

async def main():
    consumer_conf = {
                        'bootstrap.servers': bootstrap,
                        'security.protocol': 'SASL_SSL',
                        'sasl.mechanisms': 'PLAIN',
                        'sasl.username': sasl_ssl_key,
                        'sasl.password': sasl_ssl_secret,
                        'group.id': "auto-dr-consumer",
                        'auto.offset.reset': auto_offset_reset
                    }
    consumer = Consumer(consumer_conf)
    consumer.subscribe([topic_name, mirror_topic_name])

    while True:
        try:
            message = consumer.poll(1.0)
            if message is not None:
                # message_obj = message
                logger.info("Successfully consumed message for key {0} at offset {1}".format(message.key(), message.offset()))
                time.sleep(1)
                consumer.commit()
            else:
                logger.debug(message)
                continue
        except Exception as e:
            logger.exception(msg=e)
            consumer.close()
            break


if __name__=="__main__":
    loop = asyncio.get_event_loop()
    task = loop.create_task(main())
    loop.run_forever()