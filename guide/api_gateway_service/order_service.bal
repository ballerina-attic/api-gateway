// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/auth;
import ballerina/http;
import ballerina/log;
//import ballerinax/docker;
import ballerinax/kubernetes;

http:AuthProvider basicAuthProvider = { id: "basic1", scheme: "BASIC_AUTH", authStoreProvider: "CONFIG_AUTH_STORE" };
http:ServiceSecureSocket secureSocket = {
    keyStore: {
        path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
        password: "ballerina"
    }
};
//@docker:Config {
//    registry: "ballerina.guides.io",
//    name: "api_gateway",
//    tag: "v1.0"
//}
//@docker:CopyFiles {
//    files: [{
//        source: "ballerina.conf",
//        target: "ballerina.conf"
//    }]
//}

//@kubernetes:Ingress {
//    hostname: "ballerina.guides.io",
//    name: "api_gateway",
//    path: "/"
//}
//@kubernetes:Service {
//    serviceType: "NodePort",
//    name: "api_gateway"
//}
//@kubernetes:Deployment {
//    image: "ballerina.guides.io/api_gateway:v1.0",
//    name: "api_gateway",
//    copyFiles: [{
//        source: "ballerina.conf",
//        target: "ballerina.conf"
//    }]
//}
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
        authentication: { enabled: true }
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
            json payload = { status: "Order Created.", orderId: untaint orderId };

            // Send response to the client.
            var result = caller->respond(payload);
            if (result is error) {
                log:printError("Error while responding", err = result);
            }
            log:printInfo("Order created: " + orderId);
        } else {
            log:printError("Invalid order request");
            var result = caller->respond({ "^error": "Invalid order request" });
            if (result is error) {
                log:printError("Error while responding");
            }
        }
    }
}
