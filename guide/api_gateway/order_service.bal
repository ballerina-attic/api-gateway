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

import ballerina/http;
import ballerina/auth;

http:AuthProvider basicAuthProvider = {id:"basic1", scheme:"basic", authProvider:"config"};

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
service<http:Service> e_shopping bind listener {

// Order management is done using an in memory map.
    map<json> ordersMap;
    @Description {value:"Resource that handles the HTTP POST requests that are directed
     to the path '/order' to create a new Order."}
    // Add authConfig param to the ResourceConfig to limit the access for scopes
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order",
        // Authorize only users with "create_orders" scope
        authConfig:{
            scopes:["create_orders"]
        }
    }
    addOrder(endpoint client, http:Request req) {
        // Retrieve the order details from the request
        json orderReq = check req.getJsonPayload();
        // Extract the Order ID from the request from the order, use "1" for ID if Nill()
        string orderId = orderReq.Order.ID.toString() but { () => "1" };
        // add the order to the ordersMap
        ordersMap[orderId] = orderReq;

        // Create response message.
        json payload = {status:"Order Created.", orderId:orderId};
        http:Response response;
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client -> respond(response);
    }
}
