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
}
