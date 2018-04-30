[![Build Status](https://travis-ci.org/ballerina-guides/api-gateway.svg?branch=master)](https://travis-ci.org/ballerina-guides/api-gateway)

# API Gateway  
[API Gateway](http://microservices.io/patterns/apigateway.html) a server that act as an API front-end, receives API requests, enforces throttling and security policies, passes requests to the back-end service and then passes the response back to the requester.

> In this guide you will learn about building a API Gateway for a web service. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build 
 
To understanding how you can build a API gateway for RESTful web service using Ballerina, let’s consider a real world use case of ordering items from e-shopping website for authorized users. 
The following figure illustrates how the Ballerina API gateway can use with RESTful service. 

![api_gateway](images/api_gateway.svg "API Gateway")

- **Create Order** : To place a new order you can use the HTTP POST message with the order details to `localhost:9090/e-shop/order`
NOTE: You need to pass "Authorization" header with the request.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the git repo and directly move to the "Testing" section by skipping  "Implementation" section.

### Create the project structure

Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.
```
api-gateway
 └── guide
    ├── api_gateway
    │   ├── order_service.bal
    │   └── tests
    │       └── order_service_test.bal
    └── ballerina.conf
```

- Create the above directories in your local machine and also create empty `.bal` files.

- You can add desired usernames and passwords inside the `ballerina.conf` file. We have added two sample users as follows,
```ballerina
["b7a.users"]

["b7a.users.alice"]
password="abc"
scopes="customer"

["b7a.users.bob"]
password="xyz"
scopes="customer"
```

- Then open the terminal and navigate to `api-gateway/guide` and run Ballerina project initializing toolkit.
```bash
   $ ballerina init
```

### Development of order service with API gateway

Now let us look into the implementation of the order management with the managed security layer.
 
##### order_service.bal
```ballerina
import ballerina/http;
import ballerina/auth;

http:AuthProvider basicAuthProvider ={id:"basic1", scheme:"basic", authProvider:"config"};

// The endpoint used here is 'endpoints:ApiEndpoint', which by default tries to
// authenticate and authorize each request.
// The developer has the option to override the authentication and authorization
// at service and resource level.
endpoint http:APIListener listener {
    port:9090,
    authProviders:[basicAuthProvider]
};

// Add the authConfig in the ServiceConfig annotation to protect the service using Auth
@http:ServiceConfig {
    basePath:"/e-shop",
    authConfig:{
        authProviders:["basic1"],
        authentication:{enabled:true}
    }
}
service<http:Service> eShopService bind listener {

    @Description {value:"Resource that handles the HTTP POST requests that are directed
     to the path '/order' to create a new Order."}
    // Add authConfig param to the ResourceConfig to limit the access for scopes
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order",
        // Authorize only users with "create_orders" scope
        authConfig:{
            scopes:["customer"]
        }
    }
    addOrder(endpoint client, http:Request req) {
        // Retrieve the order details from the request
        json orderReq = check req.getJsonPayload();
        // Extract the Order ID from the request from the order, use "1" for ID if Nill()
        string orderId = orderReq.Order.ID.toString() but { () => "1" };

        // Create response message.
        json payload = {status:"Order Created.", orderId:orderId};
        http:Response response;
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client -> respond(response);
    }
}

```

- With that we've completed the development of OrderMgtService with Auth authentication. 

## Testing 

### Invoking the e-shop service

You can run the RESTful service that you developed above, in your local environment. Open your terminal and navigate to `api-gateway/guide`, and execute the following command.
```
$ ballerina run api_gateway_service
```

- You can test the functionality of the e-shop RESTFul service by sending HTTP request. For example, we have used the curl command to test operation of e-shop as follows. 

NOTE: Use base64 encode to encode the `<username>:<password>` with the username and password pair which is in the `ballerina.conf` file. You can visit https://www.base64encode.org/ to base64 encode username and password. We will use `YWxpY2U6YWJj` as the base64 encoded value for `alice:abc`.

**Create Order** 
```
curl -H "Authorization: Basic YWxpY2U6YWJj" -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://localhost:9090/e-store/order" -H "Content-Type:application/json"

Output :  
{"status":"Order Created.","orderId":"100500"} 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'.  When writing the test functions the below convention should be followed.
- Test functions should be annotated with `@test:Config`. See the below example.
```ballerina
   @test:Config
   function testeShop() {
```
  
This guide contains unit test cases for the `api_gateway_service` that you implemented above. 

To run the unit tests, open your terminal and navigate to `api-gateway/guide`, and run the following command.
```bash
$ ballerina test -c ballerina.conf
```

To check the implementation of the test file, refer to the `tests` directories in the [repository](https://github.com/ballerina-guides/api-gateway).


## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally

- As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above. Navigate to `api-gateway/guide` and run the following command. 
```bash
   $ ballerina api_gateway_service/
```

- Once the balx files are created inside the target folder, you can run that with the following command. 
```
   $ ballerina run target/api_gateway_service.balx
```

### Deploying on Docker


You can run the service that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on 
containers, you just need to put the corresponding docker annotations on your service code. 

- In our order_service.bal file, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

##### order_mgt_service.bal
```ballerina
import ballerina/http;
import ballerinax/docker;
import ballerina/auth;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"api_gateway",
    tag:"v1.0"
}
http:AuthProvider basicAuthProvider = {id:"basic1", scheme:"basic", authProvider:"config"};

endpoint http:SecureListener listener {
    port:9090,
    authProviders:[basicAuthProvider]
};

@http:ServiceConfig {
    basePath:"/e-shop",
    authConfig:{
        authProviders:["basic1"],
        authentication:{enabled:true}
    }
}
service<http:Service> eShop bind listener {

``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/guide/` folder and run the following command.  
  
```
   $ballerina build api_gateway_service

   Run following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/api_gateway:v1.0
```

- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```   
   docker run -d -p 9090:9090 ballerina.guides.io/api_gateway_service:v1.0
```

  Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we  use  the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the docker container should be shown as 'Up'. 
- You can access the service using the same curl commands that we've used above. 
 
```
   curl -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d '{ "Order": \ 
   { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
   "http://localhost:9090/e-store/order" -H "Content-Type:application/json"    
```


### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, 
with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. 
So you don't need to explicitly create docker images prior to deploying it on Kubernetes.   

- We need to import `` import ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### order_mgt_service.bal

```ballerina
import ballerina/http;
import ballerinax/kubernetes;
import ballerina/auth;

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-restful-service",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-restful-service"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/api_gateway:v1.0",
    name:"ballerina-guides-restful-service"
}

endpoint http:Listener listener {
    port:9090
};
service<http:Service> eShop bind listener {    
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:Service `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress `` which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ballerina build api_gateway_service
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/api_gateway_service/kubernetes
```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker ps images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/api_gateway_service/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
   $ kubectl apply -f ./target/api_gateway_service/kubernetes 
 
   deployment.extensions "ballerina-guides-api-gateway" created
   ingress.extensions "ballerina-guides-restful-service" created
   service "ballerina-guides-eshop-service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands.

```
   $kubectl get service
   $kubectl get deploy
   $kubectl get pods
   $kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
curl  -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://<Minikube_host_IP>:<Node_Port>/e-shop/order" -H "Content-Type:application/json"  
```

Ingress:

Add `/etc/hosts` entry to match hostname. 
``` 
127.0.0.1 ballerina.guides.io
```

Access the service 

``` 
curl  -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://ballerina.guides.io/e-shop/order" -H "Content-Type:application/json" 
```

## Observability 
Ballerina is by default observable. Meaning you can easily observe your services, resources, etc.
However, observability is disabled by default via configuration. Observability can be enabled by adding following configurations to `ballerina.conf` file in `api-gateway/guide/`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

NOTE: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations default values are load as the other configuration parameters of metrics and tracing.

### Tracing 

You can monitor ballerina services using in built tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
Follow the following steps to use tracing with Ballerina.

- You can add the following configurations for tracing. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described above.
```
   [b7a.observability]

   [b7a.observability.tracing]
   enabled=true
   name="jaeger"

   [b7a.observability.tracing.jaeger]
   reporter.hostname="localhost"
   reporter.port=5775
   sampler.param=1.0
   sampler.type="const"
   reporter.flush.interval.ms=2000
   reporter.log.spans=true
   reporter.max.buffer.spans=1000
```

- Run Jaeger docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 \
   -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `api-gateway/guide` and run the restful-service using following command 
```
   $ ballerina run api_gateway_service/
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for Ballerina restful service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under `Observability` section.

```ballerina
   [b7a.observability.metrics]
   enabled=true
   provider="micrometer"

   [b7a.observability.metrics.micrometer]
   registry.name="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9700
   hostname="0.0.0.0"
   descriptions=false
   step="PT1M"
```

- Create a file `prometheus.yml` inside `/tmp/` location. Add the below configurations to the `prometheus.yml` file.
```
   global:
     scrape_interval:     15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: prometheus
       static_configs:
         - targets: ['172.17.0.1:9797']
```

   NOTE : Replace `172.17.0.1` if your local docker IP differs from `172.17.0.1`
   
- Run the Prometheus docker image using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```
   
- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

NOTE:  Ballerina will by default have following metrics for HTTP server connector. You can enter following expression in Prometheus UI
-  http_requests_total
-  http_response_time


### Logging

Ballerina has a log package for logging to the console. You can import ballerina/log package and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina Service with the following command from `api-gateway/guide`
```
   $ nohup ballerina run api_gateway_service &>> ballerina.log&
```
   NOTE: This will write the console log to the `ballerina.log` file in the `api-gateway/guide` directory

- Start Elasticsearch using the following command

- Start Elasticsearch using the following command
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.2.2 
```

   NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count` 
   
- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.2.2     
```

- Configure logstash to format the ballerina logs

i) Create a file named `logstash.conf` with the following content
```
input {  
 beats{ 
     port => 5044 
 }  
}

filter {  
 grok{  
     match => { 
	 "message" => "%{TIMESTAMP_ISO8601:date}%{SPACE}%{WORD:logLevel}%{SPACE}
	 \[%{GREEDYDATA:package}\]%{SPACE}\-%{SPACE}%{GREEDYDATA:logMessage}"
     }  
 }  
}   

output {  
 elasticsearch{  
     hosts => "elasticsearch:9200"  
     index => "store"  
     document_type => "store_logs"  
 }  
}  
```

ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}\pipeline`
     
iii) Start the logstash container, replace the `{SAMPLE_ROOT}` with your directory name
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.2.2
```
  
 - Configure filebeat to ship the ballerina logs
    
i) Create a file named `filebeat.yml` with the following content
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
NOTE : Modify the ownership of filebeat.yml file using `$chmod go-w filebeat.yml` 

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}\filebeat`   
        
iii) Start the logstash container, replace the `{SAMPLE_ROOT}` with your directory name
     
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/api_gateway_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.2.2
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```
  
 
