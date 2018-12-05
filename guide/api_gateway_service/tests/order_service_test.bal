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

import ballerina/test;
import ballerina/http;

http:SecureSocket? secureSock = {
    trustStore: {
        path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
        password: "ballerina"
    }
};
http:Client clientEP = new("https://localhost:9090/e-store", config = { secureSocket: secureSock });

@test:Config
// Function to test POST resource 'addOrder' with correct Auth header.
function testWithCorrectAuth() {
    // Initialize the empty http request.
    http:Request request = new;
    request.addHeader("Authorization", "Basic YWxpY2U6YWJj");
    // Construct the request payload.
    json payload = { "Order": { "ID": "100500", "Name": "XYZ", "Description":
    "Sample order." } };
    request.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/order", request);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 200,
            msg = "addOrder resource did not respond with expected response code!");
        // Check whether the response is as expected.
        var resPayload = response.getJsonPayload();
        if (resPayload is json) {
            test:assertEquals(resPayload.toString(),
                "{\"status\":\"Order Created.\", \"orderId\":\"100500\"}", msg =
                "Response mismatch!");
        } else {
            test:assertFail(msg = "The payload has to be json.");
        }
    } else {
        test:assertFail(msg = "Error when responding");
    }
}

@test:Config
// Function to test POST resource 'addOrder' with incorrect Auth header.
function testWithIncorrectAuth() {
    // Initialize the empty http request.
    http:Request request = new;
    request.addHeader("Authorization", "Basic c2lsdmE6d3dlcg==");
    // Construct the request payload.
    json payload = { "Order": { "ID": "100500", "Name": "XYZ", "Description":
    "Sample order." } };
    request.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    var response = clientEP->post("/order", request);
    if (response is http:Response) {
        // Expected response code is 200.
        test:assertEquals(response.statusCode, 401,
            msg = "addOrder resource did not respond with expected response code!");
    } else {
        test:assertFail(msg = "Error when responding");
    }
}
