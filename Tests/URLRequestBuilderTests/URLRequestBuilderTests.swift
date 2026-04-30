import XCTest
@testable import URLRequestBuilder

final class URLRequestBuilderTests: XCTestCase {
    let testURL = URL(string: "https://example.com")!
    let localhost = URL(string: "http://localhost:3000/")!
    
    // MARK: - JSON Factory Tests

    func testJsonGetUsesAcceptHeaderNotContentType() {
        let request = URLRequestBuilder.jsonGet(path: "/items")
            .makeRequest(withBaseURL: testURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    func testJsonPostWithDataSetsContentTypeAndAcceptHeaders() {
        let jsonData = Data("{\"key\":\"value\"}".utf8)
        let request = URLRequestBuilder.jsonPost(path: "/items", jsonData: jsonData)
            .makeRequest(withBaseURL: testURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.httpBody, jsonData)
    }

    func testJsonPostWithEncodableObjectSetsContentTypeAndAcceptHeaders() throws {
        struct Item: Encodable { let name: String }
        let request = try URLRequestBuilder.jsonPost(path: "/items", jsonObject: Item(name: "test"))
            .makeRequest(withBaseURL: testURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertNotNil(request.httpBody)
    }

    // MARK: -

    func testMultipleHeaders() throws {
        let request = URLRequestBuilder(path: "multiple-headers")
            .header(name: "Test-Multiple", values: ["A", "B", "C"])
            .makeRequest(withBaseURL: testURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Test-Multiple"), "A,B,C")
        XCTAssertNotEqual(request.value(forHTTPHeaderField: "Test-Multiple"), "A,B")
    }
    
    func testReadme() throws {
        let user = 1
        let authToken = "aaa"
        
        let urlRequest = try URLRequestBuilder(path: "users/submit")
            .method(.post)
            .jsonBody(user)
            .contentType(.applicationJSON)
            .accept(.applicationJSON)
            .timeout(20)
            .queryItem(name: "city", value: "San Francisco")
            .header(name: "Auth-Token", value: authToken)
            .makeRequest(withBaseURL: testURL)
        
        print(urlRequest)
        
        XCTAssertEqual(urlRequest.url!.absoluteString, "https://example.com/users/submit?city=San%20Francisco")
    }
    
    func testLocalhost() throws {
        let user = 1
        let authToken = "aaa"
        
        let urlRequest = try URLRequestBuilder(path: "users/submit")
            .method(.post)
            .jsonBody(user)
            .contentType(.applicationJSON)
            .accept(.applicationJSON)
            .timeout(20)
            .queryItem(name: "city", value: "San Francisco")
            .header(name: "Auth-Token", value: authToken)
            .makeRequest(withConfig: .base(scheme: "http", host: "localhost", port: 3000))
        
        print(urlRequest)
        
//        XCTAssertEqual(urlRequest.url!.absoluteString, "https://example.com/users/submit?city=San%20Francisco")
    }
}
