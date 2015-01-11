# Hsdq


###High Speed Distributed Queue:
#####A messaging layer allowing distributed applications/scripts to communicate easily and exchange data at high speed. 
**Also allow to offload deferred tasks to outside applications/scripts.**  

## Features

* Connect with ease applications and/or scripts together.
* Easy to scale horizontally by adding or removing new application on line.
* Easy to balance the load, no round-robbing, the first listening application listening will get the message, then the next one will get the next message.
* hot swap, hot deployment. If the app message API is compatible with the previous API version, just deploy the new version and stop the old one.
* No need to have the target application on line to send a message, they will be stored in the bus and the target app will begin processing as soon as back online. (HTTP API need to be online to get the request).

## Dependencies

* HSDQ rely on Redis for the transport layer
* Ruby 1.9.3, Jruby mode 1.9 should work too

## How to use HSDQ

####Step 0: Getting a bit accustomed

Play with some quick and dirty scripts to get familiar, check the examples folder.

####Step 1: create the connected class

- Create a class in your application or script (for a Rails app in lib or accustomed in models)
- Prefix this class name with `Hsdq`, ie: `HsdqMyClass`
- Extend Hsdq into your class

The listening channel will then be created based on your class name ie: `my_class`

####Step 2: to get the events

Into your class override the 5 following methods:

| Method         | Comment                                                                         | 
|:-------------- |:--------------------------------------------------------------------------------|
|`hsdq_request`  |Called when a request is received                                                |
|`hsdq_ack`      |Called when an acknowledgment your request has been received by the receiving app|
|`hsdq_callback` |Called when the other other app respond to your request                          |
|`hsdq_feedback` |Called when the other app is sending intermediate feedback                       |
|`hsdq_error`    |Called when an error occur                                                       |

You must implement these class methods into your class. They will receive the event.
All methods are receiving 2 parameters: A Hash for the message and a Hash or nil for the context.

```Ruby  
def self.hsdq_request(message, context)  
  self.new.hsdq_request message, context  
end  
  
def self.hsdq_request(message, context)  
  # Start your processing here  
end  
```   
**Important:** Unless options[:threaded] is set to false, each event received are totally decoupled and independent. So you need to keep track of the context if needed.

####Step 3: sending messages

Four methods are used to send and respond to messages.  
They are implemented internally in Hsdq and need a Hash as parameter.

| Method                       | Comment                                   |
|:-----------------------------|:------------------------------------------|
|`hsdq_send_request(message)`  | To send a request                         |
|`hsdq_send_calback(message)`  | To send the final response to a request   |
|`hsdq_send_feedback(message)` | To send intermediate data                 |
|`hsdq_send_error(message)`    | To send an error message in case of error |

####Step 4:
Set the authorized topics and tasks in your class:  
`hsdq_authorized_topics :beer, :wine, :cheese, :dishes`  
`hsdq_authorized_tasks :drink, :eat, :clean`  
Note you can in simple cases like in scripts only use topic or task but it is recommended to use both.

####Step 5:
Setup the hsdq config file:  
In the config folder create a file name `hsdq_my_class.yml` There ia a sample file in hsdq config folder

`
development:
  redis:
    message:
      host: 127.0.0.1
      port: 6379
      db:   0
    admin:
      host: 127.0.0.1
      port: 6379
      db:   0
    session:
      host: 127.0.0.1
      port: 6379
      db:   0
`

## Message specifications

#####Five type of message are running into the bus:

|    | Type    | Description                        |
|:---|:--------|:-----------------------------------|
| 1  | Request | Initial message sent               |
| 2  | Ack     | Acknowledgment of reception        |
| 3  | Feedback| Intermediate response (progress)   |
| 4  | Callback| Final response with the data       |
| 5  | Error   | Final response when an error occur | 

#####A message event is composed of 2 parts:  

1 - The spark:

- An ephemeral tiny part that include the minimum but sufficient information pointing to the 2nd part, the message itself.
- The spark is what the listener will be getting from the list queue and this will ignite the process.  
- The spark is pushed to a redis list and popped by the listener. Once popped it will not be available in the redis layer anymore.  
  
2 - The Burst:

- An event in the life of the message, the burst is stored as one value in a Redis hash and can be retrieved using the spark data.
  
#####The complete message

- It will contain all the operations executed during the life cycle of the message.  
- It is stored into a hash and each element of this hash is one message event.  
- The message element is stored in a Redis Hash with a default expiration of 72 hours (can be adjusted)  

A message is composed of multiple events. At minimum there are 3 events:

1. Request
2. Ack
3. Callback or Error

Multiple feedback can be sent before the callback/error and multiple events can be present in the case of chained events.

#####Structure of a message:
**The burst:**  

|  Key           |       | Type   |  Description                                                     |
| :--------------|:-----:| :----- | :--------------------------------------------------------------- |
| sent_to        | M     | String | Name channel you publish                                         |
| topic          | O     | Symbol | Topic to be processed (ex: :beer, :wine, :cheese etc...).        |
| task           | O     | Symbol | Task to be processed (ex: :drink, eat, clean ,etc...).           |
| params         | M     | Hash   | parameters matching the receiver message API (can be empty hash) | 
| data           | C     | Hash   | Mandatory in the responses as this is the response               | 
| type           | I     | Symbol | Type of the message ie: :request, :callback, etc                 |
| sender         | I     | String | the listening channel of the sender. Used to reply               |
| uid            | I     | UUID   | Unique identifier for the message container (redis hash)         |
| spark_uid      | I     | UUID   | Unique identifier for the 'spark' and the 'burst'                |
| tstamp         | I     | UTC    | Timestamp for the event UTC                                      |
| context        | I     | Hash   | Data from the previous request. keys: :reply_to, spark_uid       |
| previous_sender| I     | String | The previous sender of a request. used in chained queries        |
| hsdq_session   | O     | String | Key to load session data related to the context                  |

`M` Mandatory, `O` Optional (but recommended for pre-filtering), `I` Hsdq internal

- Topic and task values must be present respectively in the topics or task white lists when used.
- Redis return symbols as strings in the responses

**The spark:**   

The spark has the same structure and values as the burst except it do not carry the payload.
The params and data as well as eventual custom keys keys which can contain heavy payloads are not included.


