import kafka, time, json, numpy as np,requests 

topic = "vmsevents"
bootstrap_servers = "10.3.61.2:9092"
consumer = kafka.KafkaConsumer(topic, bootstrap_servers=bootstrap_servers, auto_offset_reset="latest")

assert(consumer.bootstrap_connected())
print(f"Bootstrap '{bootstrap_servers}' connected. Listening...")
print(consumer.topics())

for message in consumer:
    print(message)
    #message = f"""
    #Message received: {message.value}
    #Message key: {message.key}
    #Message partition: {message.partition}
    #Message offset: {message.offset}
    #"""
    message= f"""{message.value}"""
    count = message.count("person")
    print(count)
    if (count>=2):  
        print("alert") 
        requests.post("https://ntfy.sh/iotvms-events", data="Alert 😀 2 personnes detectees".encode(encoding='utf-8')) 
