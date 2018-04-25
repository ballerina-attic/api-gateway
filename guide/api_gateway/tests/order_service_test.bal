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

@test:BeforeSuite
function beforeFunc() {
    // Start the 'order_mgt' service before running the test.
    _ = test:startServices("api_gateway");
}

endpoint http:Client clientEP {
    targets:[{url:"http://localhost:9090/e-shop"}]
};

@test:Config
// Function to test POST resource 'addOrder' with correct Auth header.
function testWithCorrectAuth() {
    // Initialize the empty http request.
    http:Request request;
    request.addHeader("Authorization", "Basic YWxpY2U6YWJj");
    // Construct the request payload.
    json payload = {"Order":{"ID":"100500", "Name":"XYZ", "Description":"Sample order."}};
    request.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    http:Response response = check clientEP -> post("/order", request);
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 200,
        msg = "addOrder resource did not respond with expected response code!");
    // Check whether the response is as expected.
    json resPayload = check response.getJsonPayload();
    test:assertEquals(resPayload.toString(),
        "{\"status\":\"Order Created.\",\"orderId\":\"100500\"}", msg = "Response mismatch!");
}

@test:Config
// Function to test POST resource 'addOrder' with incorrect Auth header.
function testWithIncorrectAuth() {
    // Initialize the empty http request.
    http:Request request;
    request.addHeader("Authorization", "Basic c2lsdmE6d3dlcg==");
    // Construct the request payload.
    json payload = {"Order":{"ID":"100500", "Name":"XYZ", "Description":"Sample order."}};
    request.setJsonPayload(payload);
    // Send 'POST' request and obtain the response.
    http:Response response = check clientEP -> post("/order", request);
    // Expected response code is 200.
    test:assertEquals(response.statusCode, 401,
        msg = "addOrder resource did not respond with expected response code!");
}

@test:AfterSuite
function afterFunc() {
    // Stop the 'order_mgt' service after running the test.
    test:stopServices("restful_service");
}
