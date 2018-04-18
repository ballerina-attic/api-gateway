# API Gateway  
[API Gateway](http://microservices.io/patterns/apigateway.html) a server that act as an API front-end, receives API requests, enforces throttling and security policies, passes requests to the back-end service and then passes the response back to the requester.

> In this guide you will learn about building a API Gateway for a web service. 

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing](#testing)
- [Deployment](#deployment)

## What you’ll build 
 
To understanding how you can build a API gateway for RESTful web service using Ballerina, let’s consider a real world use case of ordering items from e-shopping website for authorized users. 
The following figure illustrates how the Ballerina API gateway can use with RESTful service. 

![api_gateway](images/api_gateway.png "API Gateway")

- **Create Order** : To place a new order you can use the HTTP POST message with the order details to `localhost:9090/e-shop/order`
NOTE: You need to pass "Authorization" header with the request.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service 

We can add security layer for Ballerina services by adding security parameters to `@ServiceConfig` annotation. 

- We can get started with a Ballerina service; 'OrderMgtService', which is the Auth protected RESTful service that serves the order management request. OrderMgtService can have multiple resources and each resource is dedicated for a specific order management functionality.

- You can decide the package structure for the service and then create the service in the corresponding directory structure. For example, suppose that you are going to use the package name 'api_gateway', then you need to create the following directory structure and create the service file using the text editor or IDE that you use. 

```
api-gateway-sample
  └── guide
      └── api_gateway
      |    ├── order_service.bal
      |     └── test
      |        └── order_service_test.bal          
      └── ballerina.conf
```

- Once you created your package structure, go to the sample `guide` directory and run the following command to initialize your Ballerina project.

```bash
   $ballerina init
```

  The above command will initialize the project with a `Ballerina.toml` file and `.ballerina` implementation directory that contain a list of packages in the current directory.

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

 Now let us look into the implementation of the order management with the managed security layer.
 
##### order_service.bal
```ballerina
import ballerina/http;
import ballerina/auth;

http:AuthProvider basicAuthProvider = {id:"basic1",scheme:"basic",authProvider:"config"};

// The endpoint used here is 'endpoints:ApiEndpoint', which by default tries to
// authenticate and authorize each request.
// The developer has the option to override the authentication and authorization
// at service and resource level.
endpoint http:SecureListener listener {
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

### Invoking the RESTful service 

You can run the e-shop RESTful service that you developed above, in your local environment. You need to have the Ballerina installation in you local machine and simply point to the <ballerina>/bin/ballerina binary to execute all the following steps.  

1. As the first step you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the directory in which the service we developed above located and it will create an executable binary out of that. Navigate to the `<SAMPLE_ROOT>/src/` folder and run the following command. 

```
$ballerina build api_gateway
```

2. Once the api_gateway.balx is created inside the target folder, you can run that with the following command. 

```
$ballerina run target/api_gateway.balx
```

3. The successful execution of the service should show us the following output. 
```
$ ballerina run target/api_gateway.balx 

ballerina: deploying service(s) in 'target/api_gateway.balx'
ballerina: started HTTP/WS server connector 0.0.0.0:9090
```

4. You can test the functionality of the e-shop RESTFul service by sending HTTP request. For example, we have used the curl command to test operation of e-shop as follows. 

NOTE: Use base64 encode to encode the `<username>:<password>` with the username and password pair which is in the `ballerina.conf` file. You can use https://www.base64encode.org/ to base64 encode username and password. We will use `YWxpY2U6YWJj` as the base64 encoded value for `alice:abc`.

**Create Order** 
```
curl -H "Authorization: Basic YWxpY2U6YWJj" -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://localhost:9090/e-store/order" -H "Content-Type:application/json"

Output :  
{"status":"Order Created.","orderId":"100500"} 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'. The naming convention should be as follows,

* Test functions should contain test prefix with annotation `@test:Config` before the test function.
  * e.g.: testWithCorrectAuth()

To run the unit tests, navigate to the `guide` directory and run the following command.
```bash
   $ballerina test
```


## Deployment

Once you are done with the development, you can deploy the service using any of the methods that we listed below. 

### Deploying locally
You can deploy the RESTful service that you developed above, in your local environment. You can use the Ballerina executable archive (.balx) archive that we created above and run it in your local environment as follows. 

```
$ballerina run target/api_gateway.balx
```

### Deploying on Docker


You can run the service that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on 
containers, you just need to put the corresponding docker annotations on your service code. 

- In our OrderMgtService, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

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
service<http:Service> eShopService bind listener {

``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/src/` folder and run the following command.  
  
```
   $ballerina build api_gateway

   Run following command to start docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/api_gateway:v1.0
```

- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```   
   docker run -d -p 9090:9090 ballerina.guides.io/api_gateway:v1.0
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
service<http:Service> eShopService bind listener {    
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:Service {} `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress `` which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
   $ballerina build api_gateway
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/api_gateway/kubernetes
```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker ps images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/api_gateway/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
   $ kubectl apply -f ./target/api_gateway/kubernetes 
 
   deployment.extensions "ballerina-guides-restful-service" created
   ingress.extensions "ballerina-guides-restful-service" created
   service "ballerina-guides-restful-service" created
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
