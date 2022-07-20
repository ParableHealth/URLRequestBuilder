# URLRequestBuilder

Deal with query items, HTTP headers, request body and more in an easy, declarative way

## Showcase

```swift
let urlRequest = try URLRequestBuilder(path: "users/submit")
    .method(.post)
    .jsonBody(user)
    .contentType(.applicationJSON)
    .accept(.applicationJSON)
    .timeout(20)
    .queryItem(name: "city", value: "San Francisco")
    .header(name: "Auth-Token", value: authToken)
    .makeRequest(withBaseURL: testURL)
```
