[![Build Status](https://travis-ci.org/ballerina-guides/api-gateway.svg?branch=master)](https://travis-ci.org/ballerina-guides/api-gateway)

# Building an API Gateway  
[API Gateway](http://microservices.io/patterns/apigateway.html) is a server that acts as an API front-end, receives API requests, enforces throttling and security policies, passes requests to the back-end service and then passes the response back to the requestor.

> In this guide you will learn how to build an API Gateway for a web service.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build 
 
To understand how you can build an API Gateway for RESTful web services using Ballerina, let’s consider a real world use case of ordering items from an e-shopping website for authorized users.

The following figure illustrates how the API Gateway created using Ballerina can be used with a RESTful service.

![api_gateway](images/api_gateway.svg "API Gateway")

- **Create Order** : To place a new order you can send an HTTP POST request with the order details to `localhost:9090/e-store/order`.
> **NOTE**: You need to set the `Authorization` header in the request.

## Prerequisites
 
- [Ballerina Distribution](https://ballerina.io/learn/getting-started/)
- A Text Editor or an IDE 
> **Tip**: For a better development experience, install one of the following Ballerina IDE plugins: [VSCode](https://marketplace.visualstudio.com/items?itemName=ballerina.ballerina), [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina)

### Optional requirements

- [Docker](https://docs.docker.com/engine/installation/)
- [Kubernetes](https://kubernetes.io/docs/setup/)

## Implementation

> If you want to skip the basics, you can download the GitHub repo and continue from the "Testing" section.

### Create the project structure

For the purpose of this guide, let's use the following package structure.
```
api-gateway
 └── guide
    ├── api_gateway
    │   ├── order_service.bal
    │   └── tests
    │       └── order_service_test.bal
    └── ballerina.conf
```

- Create the above directories in your local machine, along with the empty `.bal` files.

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

import ballerina/auth;
import ballerina/http;
import ballerina/log;
import ballerinax/kubernetes;

http:AuthProvider basicAuthProvider = {
    id: "basic1",
    scheme: "BASIC_AUTH",
    authStoreProvider: "CONFIG_AUTH_STORE"
};
http:ServiceSecureSocket secureSocket = {
    keyStore: {
        path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
        password: "ballerina"
    }
};

// The listener used here is 'http:Listener', which tries to authenticate and authorize each request.
// The developer has the option to override the authentication and authorization
// at service and resource level.
listener http:Listener apiListener = new(9090, config = { authProviders: [basicAuthProvider],
        secureSocket: secureSocket });

// Add the authConfig in the ServiceConfig annotation to protect the service using Auth
@http:ServiceConfig {
    basePath: "/e-store",
    authConfig: {
        authProviders: ["basic1"],
        authentication: {
            enabled: true
        }
    }
}
service eShop on apiListener {

    # Resource that handles the HTTP POST requests that are directed
    # to the path '/order' to create a new Order.
    // Add authConfig param to the ResourceConfig to limit the access for scopes
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/order",
        // Authorize only users with "create_orders" scope
        authConfig: {
            scopes: ["customer"]
        }
    }
    resource function addOrder(http:Caller caller, http:Request req) {
        // Retrieve the order details from the request
        var orderReq = req.getJsonPayload();

        if (orderReq is json) {
            // Extract the Order ID from the request from the order, use "1" for ID if Nill()
            string orderId = orderReq.Order.ID.toString();

            // Create response message.
            json payload = {
                status: "Order Created.",
                orderId: untaint orderId
            };

            // Send response to the client.
            var result = caller->respond(payload);
            if (result is error) {
                log:printError("Error while responding", err = result);
            }
            log:printInfo("Order created: " + orderId);
        } else {
            log:printError("Invalid order request");
            var result = caller->respond({
                "^error": "Invalid order request"
            });
            if (result is error) {
                log:printError("Error while responding");
            }
        }
    }
}
```

- With that we have completed the development of OrderMgtService with Auth authentication. 

## Testing 

### Invoking the e-shop service

You can run the RESTful service that you developed above, in your local environment. Open your terminal and navigate to `api-gateway/guide`, and execute the following command.
```
$ ballerina run api_gateway
```

- You can test the functionality of the e-shop RESTFul service by sending HTTP requests. For example, here's a cURL command for sending a new request for an order.

>NOTE: Use base64 encoding scheme to encode the `<username>:<password>` with the username and password pair which is in the `ballerina.conf` file. You can visit https://www.base64encode.org/ to base64 encode username and password. We will use `YWxpY2U6YWJj` as the base64 encoded value for `alice:abc`.

**Create Order** 
```
$ curl -k -H "Authorization: Basic YWxpY2U6YWJj" -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"https://localhost:9090/e-store/order" -H "Content-Type:application/json"

Output :  
{"status":"Order Created.", "orderId":"100500"}
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'. When writing the test functions, follow the convention given below.
- Test functions should be annotated with `@test:Config`. See the following example.
```ballerina
   @test:Config
   function testeShop() {
```
  
The source code for this guide contains unit test cases for the `api_gateway_service` package implemented above.
To run the unit tests, open your terminal and navigate to `api-gateway/guide`, and run the following command.
```bash
$ ballerina test -c ballerina.conf
```

The source code for the tests can be found at [order_service_test.bal](https://github.com/ballerina-guides/api-gateway/blob/master/guide/api_gateway_service/tests/order_service_test.bal).


## Deployment

Once you are done with the development, you can deploy the service using any of the methods listed below.

### Deploying locally

- As the first step, you can build a Ballerina executable archive (.balx) of the service that we developed above. Navigate to `api-gateway/guide` and run the following command. 
```bash
   $ ballerina build api_gateway_service
```

- Once the `.balx` file is created inside the target folder, you can run that with the following command.
```
   $ ballerina run target/api_gateway_service.balx
```

### Deploying on Docker


Services can be packaged and deployed as Docker containers as well. You can use the [Ballerina Docker Extension](https://github.com/ballerinax/docker) (provided in the Ballerina Platform) which provides native support for running Ballerina programs in containers. You just need to add the relevant Docker annotations to your listener endpoints.

- In our `order_service.bal` file, we need to import  `ballerinax/docker` and add the `@docker:Config` annotation to the listener endpoint as shown below to enable Docker image generation when building the service.

##### order_service.bal
```ballerina
import ballerina/auth;
import ballerina/http;
import ballerinax/docker;

http:AuthProvider basicAuthProvider = { id: "basic1", scheme: "basic", authStoreProvider: "config" };
http:ServiceSecureSocket secureSocket = {
    keyStore: {
        path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
        password: "ballerina"
    }
};

@docker:Config {
    registry: "ballerina.guides.io",
    name: "api_gateway",
    tag: "v1.0"
}
@docker:CopyFiles {
    files: [{
        source: "ballerina.conf",
        target: "ballerina.conf"
    }]
}
listener http:Listener apiListener  = new(9090, config = {authProviders: [basicAuthProvider],
                                                            secureSocket:secureSocket});

@http:ServiceConfig {
    basePath:"/e-store",
    authConfig:{
        authProviders:["basic1"],
        authentication:{enabled:true}
    }
}
service eShop on apiListener {

``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/guide/` folder and run the following command.  
  
```
   $ ballerina build api_gateway_service
    Compiling source
        api_gateway_service:0.0.0

    Compiling tests
        api_gateway_service:0.0.0

    Running tests
        api_gateway_service:0.0.0
    ballerina: started HTTP/WS endpoint 0.0.0.0:9090
    ballerina: stopped HTTP/WS endpoint 0.0.0.0:9090
            [pass] testWithIncorrectAuth
            [pass] testWithCorrectAuth

            2 passing
            0 failing
            0 skipped

    Generating executable
        ./target/api_gateway_service.balx
            @docker 		 - complete 3/3

            Run following command to start docker container:
            docker run -d ballerina.guides.io/api_gateway:v1.0
```

- Once you have successfully built the Docker image, you can run it using the `docker run` command which was given at the end of the build output.

```   
   $ docker run -d -p 9090:9090 ballerina.guides.io/api_gateway:v1.0
```

  Here we are running a Docker container with the flag `-p <host_port>:<container_port>` to map the container's port 9090 to the host's port 9090 so that the service will be accessible through the same port on the host.

- Verify that the container is up and running with the use of `docker ps`. The status of the container should be shown as 'Up'.
- You can invoke the service using the same cURL commands that we've used above.
 
```
   $ curl -k -H "Authorization: Basic YWxpY2U6YWJj" -X POST -d \
     '{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
     "https://localhost:9090/e-store/order" -H "Content-Type:application/json"    
```


### Deploying on Kubernetes

- You can run the service that we developed above, on Kubernetes. The Ballerina language offers native support for running Ballerina programs on Kubernetes,
with the use of Kubernetes annotations that you can include as part of your service code. It will create the necessary Docker images as well.
Therefore there's no need to explicitly create Docker images prior to deploying it on Kubernetes.

- We need to import `ballerinax/kubernetes` and use `@kubernetes` annotations as shown below to enable Kubernetes deployment for the service we developed above.

> NOTE: Linux users can use Minikube to try this out locally.

##### order_service.bal

```ballerina
import ballerina/auth;
import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Ingress {
    hostname: "ballerina.guides.io",
    name: "api_gateway",
    path: "/"
}
@kubernetes:Service {
    serviceType: "NodePort",
    name: "api_gateway"
}
@kubernetes:Deployment {
    image: "ballerina.guides.io/api_gateway:v1.0",
    name: "api_gateway",
    copyFiles: [{
        source: "ballerina.conf",
        target: "ballerina.conf"
    }]
}
listener http:Listener apiListener  = new(9090, config = {authProviders: [basicAuthProvider],
                                                            secureSocket:secureSocket});

service eShop on apiListener {

``` 

- Here we have used the `@kubernetes:Deployment` annotation to specify the name of the Docker image which will be created as part of building this service.
- We have also specified `@kubernetes:Service` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.
- Additionally we have used `@kubernetes:Ingress` which is the external interface to access your service (with path `/` and host name `ballerina.guides.io`).

If you are using Minikube, you need to set a couple of additional attributes to the `@kubernetes:Deployment` annotation.
- `dockerCertPath` - The path to the certificates directory of Minikube (e.g., `/home/ballerina/.minikube/certs`).
- `dockerHost` - The host for the running cluster (e.g., `tcp://192.168.99.100:2376`). The IP address of the cluster can be found by running the `minikube ip` command.
 
- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command.
This will also create the corresponding Docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ ballerina build api_gateway_service
   Compiling source
       api_gateway_service:0.0.0

   Compiling tests
       api_gateway_service:0.0.0

   Running tests
       api_gateway_service:0.0.0
   ballerina: started HTTP/WS endpoint 0.0.0.0:9090
   ballerina: stopped HTTP/WS endpoint 0.0.0.0:9090
            [pass] testWithIncorrectAuth
            [pass] testWithCorrectAuth

            2 passing
            0 failing
            0 skipped

   Generating executable
       ./target/api_gateway_service.balx
            @kubernetes:Service 			 - complete 1/1
            @kubernetes:Ingress 			 - complete 1/1
            @kubernetes:Deployment 			 - complete 1/1
            @kubernetes:Docker 			     - complete 3/3

            Run following command to deploy kubernetes artifacts:
            kubectl apply -f ./target/kubernetes/api_gateway_service
```

- You can verify that the Docker image that we specified in `@kubernetes:Deployment` was created, by using the `docker images` command.
- Also the Kubernetes artifacts related to our service will be generated in `./target/kubernetes/api_gateway_service`.
- Now you can create the Kubernetes deployment using:

```
   $ kubectl apply -f ./target/kubernetes/api_gateway_service
 
   deployment.extensions "ballerina-guides-api-gateway" created
   ingress.extensions "ballerina-guides-restful-service" created
   service "ballerina-guides-eshop-service" created
```

- You can verify that the Kubernetes deployment, service and ingress are functioning as expected by using the following Kubernetes commands.

```
   $ kubectl get service
   $ kubectl get deploy
   $ kubectl get pods
   $ kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node Port or Ingress.

Node Port:
 
```
$ curl -k  -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"https://<Minikube_host_IP>:<Node_Port>/e-store/order" -H "Content-Type:application/json"
```
If you are using Minikube, you should use the IP address of the Minikube cluster obtained by running the `minikube ip` command. The port should be the node port given when running the `kubectl get services` command.

Ingress:

Add `/etc/hosts` entry to match hostname. For Minikube, the IP address should be the IP address of the cluster.
``` 
127.0.0.1 ballerina.guides.io
```

Invoke the service

``` 
$ curl -k -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"https://ballerina.guides.io/e-store/order" -H "Content-Type:application/json"
```

## Observability 
Ballerina comes with support for observability built-in to the language.
Observability is disabled by default. It can be enabled by adding the following configurations to `ballerina.conf` file in `api-gateway/guide/`. A sample configuration file can be found in `api-gateway/guide/api_gateway_service`.

```ballerina
[b7a.observability]

[b7a.observability.metrics]
# Flag to enable Metrics
enabled=true

[b7a.observability.tracing]
# Flag to enable Tracing
enabled=true
```

```
   $ ballerina run --config api_gateway_service/ballerina.conf api_gateway_service/
```
> NOTE: The above configuration is the minimum configuration needed to enable tracing and metrics. With these configurations, default values are loaded for the rest of the configuration parameters of metrics and tracing.
To start the ballerina service using the configuration file, run the following command.

### Tracing 

You can monitor Ballerina services using built-in tracing capabilities of Ballerina. We'll use [Jaeger](https://github.com/jaegertracing/jaeger) as the distributed tracing system.
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

- Run Jaeger Docker image using the following command
```bash
   $ docker run -d -p5775:5775/udp -p6831:6831/udp -p6832:6832/udp -p5778:5778 -p16686:16686 \
   -p14268:14268 jaegertracing/all-in-one:latest
```

- Navigate to `api-gateway/guide` and run the restful-service using the following command
```
   $ ballerina run --config api_gateway_service/ballerina.conf api_gateway_service
```

- Observe the tracing using Jaeger UI using following URL
```
   http://localhost:16686
```

### Metrics
Metrics and alerts are built-in with ballerina. We will use Prometheus as the monitoring tool.
Follow the below steps to set up Prometheus and view metrics for the `eShop` service.

- You can add the following configurations for metrics. Note that these configurations are optional if you already have the basic configuration in `ballerina.conf` as described under the `Observability` section.

```
   [b7a.observability.metrics]
   enabled=true
   reporter="prometheus"

   [b7a.observability.metrics.prometheus]
   port=9797
   host="0.0.0.0"
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

> NOTE : Replace `172.17.0.1` if your local Docker IP differs from `172.17.0.1`
   
- Start a Prometheus Docker container using the following command
```
   $ docker run -p 19090:9090 -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
   prom/prometheus
```

- Navigate to `api-gateway/guide` and run the restful-service using the following command
```
   $ ballerina run --config api_gateway_service/ballerina.conf api_gateway_service
```

- You can access Prometheus at the following URL
```
   http://localhost:19090/
```

### Logging

Ballerina has a log package for logging to the console. You can import ballerina/log package and start logging. The following section will describe how to search, analyze, and visualize logs in real time using Elastic Stack.

- Start the Ballerina service with the following command from `api-gateway/guide`
```
   $ nohup ballerina run api_gateway_service &>> ballerina.log&
```
> NOTE: This will write the console log to the `ballerina.log` file in the `api-gateway/guide` directory

- Start Elasticsearch using the following command
```
   $ docker run -p 9200:9200 -p 9300:9300 -it -h elasticsearch --name \
   elasticsearch docker.elastic.co/elasticsearch/elasticsearch:6.5.1 
```

> NOTE: Linux users might need to run `sudo sysctl -w vm.max_map_count=262144` to increase `vm.max_map_count`
   
- Start Kibana plugin for data visualization with Elasticsearch
```
   $ docker run -p 5601:5601 -h kibana --name kibana --link \
   elasticsearch:elasticsearch docker.elastic.co/kibana/kibana:6.5.1     
```

- Configure Logstash to format the Ballerina logs

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

ii) Save the above `logstash.conf` inside a directory named as `{SAMPLE_ROOT}/pipeline`
     
iii) Start the Logstash container, replace the `{SAMPLE_ROOT}` with your directory name
     
```
$ docker run -h logstash --name logstash --link elasticsearch:elasticsearch \
-it --rm -v ~/{SAMPLE_ROOT}/pipeline:/usr/share/logstash/pipeline/ \
-p 5044:5044 docker.elastic.co/logstash/logstash:6.5.1
```
  
 - Configure Filebeat to ship the Ballerina logs
    
i) Create a file named `filebeat.yml` with the following content
```
filebeat.prospectors:
- type: log
  paths:
    - /usr/share/filebeat/ballerina.log
output.logstash:
  hosts: ["logstash:5044"]  
```
>NOTE : Modify the ownership of `filebeat.yml` file using `$chmod go-w filebeat.yml`

ii) Save the above `filebeat.yml` inside a directory named as `{SAMPLE_ROOT}/filebeat`
        
iii) Start the Logstash container, replace the `{SAMPLE_ROOT}` with your directory name
     
```
$ docker run -v {SAMPLE_ROOT}/filbeat/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v {SAMPLE_ROOT}/guide/api_gateway_service/ballerina.log:/usr/share\
/filebeat/ballerina.log --link logstash:logstash docker.elastic.co/beats/filebeat:6.5.1
```
 
 - Access Kibana to visualize the logs using following URL
```
   http://localhost:5601 
```

