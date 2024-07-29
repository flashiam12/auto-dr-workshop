from confluent_kafka import Producer
import random
from config import * 
import logging
import json
import faker
import time
import asyncio

logging.basicConfig()
logging.root.setLevel(logging.NOTSET)

logger = logging.getLogger("kafka-producer-{}".format(cluster_env))



async def main():
    producer_conf = {
                    'bootstrap.servers': bootstrap,
                    'security.protocol': 'SASL_SSL',
                    'sasl.mechanisms': 'PLAIN',
                    'sasl.username': sasl_ssl_key,
                    'sasl.password': sasl_ssl_secret
                }
    producer = Producer(producer_conf)
    fake = faker.Faker()
    while True:
        try:
            producer.poll(0.0)
            key = str(random.randint(1,1000))
            value = json.dumps({
                "name": fake.name(),
                "address": fake.address(),
                "phone": fake.phone_number(),
                "email": fake.email(),
                "company": fake.company()
            })
            producer.produce(
                topic = topic_name, 
                key=key, 
                value=value,
                on_delivery=lambda err, msg: logger.error(msg="error occured in producer - {}".format(err)) if err is not None else logger.info(msg="successfully produced for key - {0} at offset - {1}".format(msg.key(), msg.offset()))
            )
            time.sleep(1)
            producer.flush()
        except Exception as e:
            logger.exception(msg=e)
            producer.flush()
            producer.close()
            break

# main()
if __name__=="__main__":
    # main()
    loop = asyncio.get_event_loop()
    task = loop.create_task(main())
    loop.run_forever()
