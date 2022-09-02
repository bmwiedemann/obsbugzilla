#!/usr/bin/python3 -u
import pika
import sys

# or amqps://suse:suse@rabbit.suse.de
url = "amqps://opensuse:opensuse@rabbit.opensuse.org"
if len(sys.argv) >= 2:
    url = sys.argv[1]
prefix= "opensuse"
if len(sys.argv) >= 3:
    prefix = sys.argv[2]
connection = pika.BlockingConnection(pika.URLParameters(url))
channel = connection.channel()

channel.exchange_declare(exchange='pubsub',
                         passive=True, durable=True)

result = channel.queue_declare("", exclusive=True)
queue_name = result.method.queue

channel.queue_bind(exchange='pubsub', queue=queue_name,routing_key=prefix+'.obs.request.create')
channel.queue_bind(exchange='pubsub', queue=queue_name,routing_key=prefix+'.obs.request.state_change')

#print(' [*] Waiting for logs. To exit press CTRL+C')

# opensuse.obs.request.create
# opensuse.obs.request.state_change
# opensuse.obs.request.review_wanted
# opensuse.obs.request.comment
# opensuse.obs.package.commit ... "requestid":"539138"}
def callback(ch, method, properties, body):
    #if method.routing_key == "opensuse.obs.request.create":
        body=body.decode("utf-8", "ignore")
        print(body)

channel.basic_consume(queue_name, callback,
                      auto_ack=True)

channel.start_consuming()
