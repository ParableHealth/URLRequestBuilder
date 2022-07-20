import XCTest
@testable import URLRequestBuilder

final class URLRequestBuilderTests: XCTestCase {
    let testURL = URL(string: "https://example.com")!
    
    func testMultipleHeaders() throws {
        let request = URLRequestBuilder(path: "multiple-headers")
            .header(name: "Test-Multiple", values: ["A", "B", "C"])
            .makeRequest(withBaseURL: testURL)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Test-Multiple"), "A,B,C")
        XCTAssertNotEqual(request.value(forHTTPHeaderField: "Test-Multiple"), "A,B")
    }
    
    func readme() throws {
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
    }
}
