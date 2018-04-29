# API Gateway  
The [API Gateway](http://microservices.io/patterns/apigateway.html) is a server that acts as an API front end, receives API requests, enforces throttling and security policies, passes requests to the backend service, and then passes the response back to the requester.

> This guide explains how to build an API Gateway for a Web service. The following sections are available:

- [What you will build](#what-you-are-building)
- [Prerequisites](#prerequisites)
- [Developing the service](#developing-the-service)
- [Testing the service](#testing-the-service)
- [Deploying the service](#deploying-the-service)

## What you are building 
 
The following diagram illustrates how the Ballerina API Gateway is used with a RESTful service in order to allow authorized users to order items from an e-shopping website.  

![api_gateway](images/api_gateway.svg "API Gateway")

**Create Order** : To place a new order, send an HTTP POST message with the order details to `localhost:9090/e-shop/order`
NOTE: You should pass the 'Authorization' header with the request.

## Prerequisites
 
- JDK 1.8 or later.
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md).
- A text editor or an IDE.

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the service 

Let's get started with `eShopService`, which is the Auth-protected RESTful Ballerina service that serves the order request.

You can create the service in a predefined directory structure. For example, if you are going to use the package name `api_gateway`, you need the following directory structure. Create the service file using any text editor or IDE. 

```
api-gateway-sample
  └── guide
      └── api_gateway
      |    ├── order_service.bal
      |     └── test
      |        └── order_service_test.bal          
      └── ballerina.conf
```

Once you created your package structure, go to the sample `guide` directory and run the following command to initialize the Ballerina project. It initializes the project with a `Ballerina.toml` file and the `.ballerina` implementation directory.

```bash
   $ballerina init
```
Add the usernames and passwords inside the `ballerina.conf` file. In the following example, we have added two sample users:
```ballerina
["b7a.users"]

["b7a.users.alice"]
password="abc"
scopes="customer"

["b7a.users.bob"]
password="xyz"
scopes="customer"
```
Next, let's implement order management with the managed security layer.
 
##### order_service.bal
```ballerina
import ballerina/http;
import ballerina/auth;

http:AuthProvider basicAuthProvider = {id:"basic1",scheme:"basic",authProvider:"config"};

// The endpoint used here is 'endpoints:ApiEndpoint', which
// authenticates and authorizes each request by default.
// Authentication and authorization can be overridden at the service or resource levels.
endpoint http:APIListener listener {
    port:9090,
    authProviders:[basicAuthProvider]
};

// To protect the service using Auth, add `authConfig` in the `ServiceConfig` annotation.
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
    // Add the `authConfig` parameter to `ResourceConfig` to limit access for scopes.
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order",
        // Authorize only the users with `create_orders` scope.
        authConfig:{
            scopes:["customer"]
        }
    }
    addOrder(endpoint client, http:Request req) {
        // Retrieve the order details from the request.
        json orderReq = check req.getJsonPayload();
        // Extract the Order ID from the request from the order, use "1" for ID if Nill()
        string orderId = orderReq.Order.ID.toString() but { () => "1" };

        // Create the response message.
        json payload = {status:"Order Created.", orderId:orderId};
        http:Response response;
        response.setJsonPayload(payload);

        // Send the response to the client.
        _ = client -> respond(response);
    }
}

```

You have now developed `OrderMgtService` with Auth authentication. 

## Testing the service

### Invoking the RESTful service 

Let's see how to run the e-shop RESTful service that was developed earlier in your local environment. 

1. Install Ballerina in your machine and point to the `<ballerina>/bin/ballerina` binary.

2. Navigate to `<SAMPLE_ROOT>/src/` and run the following command to build a Ballerina executable archive (.balx) of the service that was developed earlier. It points to the directory of the service and creates an executable binary out of that.

```
$ballerina build api_gateway
```

2. Once `api_gateway.balx` is created inside the target folder, run the following command. 

```
$ballerina run target/api_gateway.balx
```

3. If the execution of the service is successful, you see the following output. 
```
$ ballerina run target/api_gateway.balx 

ballerina: deploying service(s) in 'target/api_gateway.balx'
ballerina: started HTTP/WS server connector 0.0.0.0:9090
```

4. Test the functionality of the e-shop RESTFul service by sending an HTTP request. For example, we have used the curl command to test the operation of e-shop as follows:  

NOTE: Use base64 (https://www.base64encode.org/) to encode `<username>:<password>` with the username and password pair in the `ballerina.conf` file. We use `YWxpY2U6YWJj` as the base64-encoded value for `alice:abc`.

**Creating an order** 
```
curl -H "Authorization: Basic YWxpY2U6YWJj" -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://localhost:9090/e-store/order" -H "Content-Type:application/json"

Output :  
{"status":"Order Created.","orderId":"100500"} 
```

### Writing unit tests 

In Ballerina, the unit test cases should be in the same package inside a folder named `tests`. The naming convention should be as follows:

* Test functions should have the prefix `test`.
  * e.g., testWithCorrectAuth()

To run the unit tests, navigate to the `guide` directory and run the following command.
```bash
   $ballerina test
```

## Deployment

Once you are done with the development, you deploy the service using any of the following methods: 

### Deploying locally
You can deploy the RESTful service that was developed earlier in your local environment by running the Ballerina executable archive (.balx) as follows:

```
$ballerina run target/api_gateway.balx
```

### Deploying on Docker

You can run the service that we developed earlier as a Docker container. As Ballerina offers support for running programs on 
containers, you just need to put the corresponding Docker annotations in your service's code. 

To enable docker image generation during build time, import `import ballerinax/docker;` and use the annotation `@docker:Config` in `OrderMgtService` as shown below:

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

Using the following command, you can build a Ballerina executable archive (.balx) of the service that you developed earlier. It points to the service file that we developed earlier and creates an executable binary out of that. 
This also creates the corresponding docker image using the docker annotations that you configured above. Navigate to the `<SAMPLE_ROOT>/src/` folder and run the following command.  
  
```
   $ballerina build api_gateway

   Run the following command to start the Docker container: 
   docker run -d -p 9090:9090 ballerina.guides.io/api_gateway:v1.0
```

Once you successfully build the docker image, run it with the `` docker run`` command that is shown in the previous step.  

```   
   docker run -d -p 9090:9090 ballerina.guides.io/api_gateway:v1.0
```

You run the docker image with the flag `` -p <host_port>:<container_port>`` so that you can use host port 9090 and container port 9090. Therefore, you can access the service through the host port. 

Use `` $ docker ps`` to verify whether the Docker container is running. The status of the docker container should be 'Up'. You can access the service using the same curl commands used above. 
 
```
   curl -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d '{ "Order": \ 
   { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
   "http://localhost:9090/e-store/order" -H "Content-Type:application/json"    
```

### Deploying on Kubernetes

Ballerina offers native support for running programs on Kubernetes using Kubernetes annotations that you can include as part of the service code. It also creates the Docker images so that you do not have to explicitly create them prior to deploying on Kubernetes.   

To enable Kubernetes deployment for the service, import `` import ballerinax/kubernetes; `` and use the `` @kubernetes `` annotations as follows:

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

We use ``@kubernetes:Deployment`` to specify the Docker image name, which is created when building the service. Also, use ``@kubernetes:Service {}`` to create a Kubernetes service that exposes the Ballerina service running on a Pod. In addition, use ``@kubernetes:Ingress``, which is the external interface to access your service, with path ``/`` and hostname ``ballerina.guides.io``.

Use the following command to build a Ballerina executable archive (.balx) of the service. It creates an executable binary, the corresponding docker image, and the Kubernetes artifacts.
  
```
   $ballerina build api_gateway
  
   Run following command to deploy kubernetes artifacts:  
   kubectl apply -f ./target/api_gateway/kubernetes
```

Use ``docker ps images`` to verify that the docker image that you specified in ``@kubernetes:Deployment`` is created. Also, the Kubernetes artifacts related to our service is generated in ``./target/api_gateway/kubernetes``. 
Use the following command to create the Kubernetes deployment:

```
   $ kubectl apply -f ./target/api_gateway/kubernetes 
 
   deployment.extensions "ballerina-guides-restful-service" created
   ingress.extensions "ballerina-guides-restful-service" created
   service "ballerina-guides-restful-service" created
```

Use the following commands to verify that the Kubernetes deployment, service, and ingress are running properly:

```
   $kubectl get service
   $kubectl get deploy
   $kubectl get pods
   $kubectl get ingress
```

If everything is successfully deployed, you can invoke the service either via Node port or ingress as follows: 

Node Port:
 
```
curl  -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://<Minikube_host_IP>:<Node_Port>/e-shop/order" -H "Content-Type:application/json"  
```

Ingress:

Add the `/etc/hosts` entry to match the hostname. 
``` 
127.0.0.1 ballerina.guides.io
```

Access the service.

``` 
curl  -H "Authorization: Basic YWxpY2U6YWJj" -v -X POST -d \
'{ "Order": { "ID": "100500", "Name": "XYZ", "Description": "Sample order."}}' \
"http://ballerina.guides.io/e-shop/order" -H "Content-Type:application/json" 
```
