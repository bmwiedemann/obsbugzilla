#!/usr/bin/python3 -u
import pika
import re
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

channel.exchange_declare(exchange='pubsub', type='topic',
                         passive=True, durable=True)

result = channel.queue_declare(exclusive=True)
queue_name = result.method.queue

#channel.queue_bind(exchange='pubsub', queue=queue_name,routing_key='#')
channel.queue_bind(exchange='pubsub', queue=queue_name,routing_key=prefix+'.src.*.pull_request.*')
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
        body=body.replace("\n"," ")
        body=re.sub("^{", "{ \"routing_key\": \"" + method.routing_key +'", ', body)
        print(body)

channel.basic_consume(callback,
                      queue=queue_name,
                      no_ack=True)

channel.start_consuming()
