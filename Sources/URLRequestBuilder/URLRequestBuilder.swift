import Foundation

public typealias EndpointRequest = URLRequestBuilder

public struct URLRequestBuilder {
    public private(set) var buildURLRequest: (inout URLRequest) -> Void
    public private(set) var urlComponents: URLComponents

    private init(urlComponents: URLComponents) {
        self.buildURLRequest = { _ in }
        self.urlComponents = urlComponents
    }

    // MARK: - Starting point

    public init(path: String) {
        var components = URLComponents()
        components.path = path
        self.init(urlComponents: components)
    }

    public static func customURL(_ url: URL) -> URLRequestBuilder {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("can't make URLComponents from URL")
            return URLRequestBuilder(urlComponents: .init())
        }
        return URLRequestBuilder(
            urlComponents: components
        )
    }

    // MARK: - Factories

    public static func get(path: String) -> URLRequestBuilder {
        .init(path: path)
            .method(.get)
    }

    public static func post(path: String) -> URLRequestBuilder {
        .init(path: path)
            .method(.post)
    }

    // MARK: - JSON Factories

    public static func jsonGet(path: String) -> URLRequestBuilder {
        .get(path: path)
            .contentType(.applicationJSON)
    }

    public static func jsonPost(path: String, jsonData: Data) -> URLRequestBuilder {
        .post(path: path)
            .contentType(.applicationJSON)
            .body(jsonData)
    }

    public static func jsonPost<Content: Encodable>(path: String, jsonObject: Content, encoder: JSONEncoder = URLRequestBuilder.jsonEncoder) throws -> URLRequestBuilder {
        try .post(path: path)
            .contentType(.applicationJSON)
            .jsonBody(jsonObject, encoder: encoder)
    }

    // MARK: - Building Blocks

    public func modifyRequest(_ modifyRequest: @escaping (inout URLRequest) -> Void) -> URLRequestBuilder {
        var copy = self
        let existing = buildURLRequest
        copy.buildURLRequest = { request in
            existing(&request)
            modifyRequest(&request)
        }
        return copy
    }

    public func modifyURL(_ modifyURL: @escaping (inout URLComponents) -> Void) -> URLRequestBuilder {
        var copy = self
        modifyURL(&copy.urlComponents)
        return copy
    }

    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case head = "HEAD"
        case delete = "DELETE"
        case patch = "PATCH"
        case options = "OPTIONS"
        case connect = "CONNECT"
        case trace = "TRACE"
    }

    public func method(_ method: Method) -> URLRequestBuilder {
        modifyRequest { $0.httpMethod = method.rawValue }
    }

    public func body(_ body: Data, setContentLength: Bool = false) -> URLRequestBuilder {
        let updated = modifyRequest { $0.httpBody = body }
        if setContentLength {
            return updated.contentLength(body.count)
        } else {
            return updated
        }
    }

    public static let jsonEncoder = JSONEncoder()

    public func jsonBody<Content: Encodable>(_ body: Content, encoder: JSONEncoder = URLRequestBuilder.jsonEncoder, setContentLength: Bool = false) throws -> URLRequestBuilder {
        let body = try encoder.encode(body)
        return self.body(body)
    }

    // MARK: Query

    public func queryItems(_ queryItems: [URLQueryItem]) -> URLRequestBuilder {
        modifyURL { urlComponents in
            var items = urlComponents.queryItems ?? []
            items.append(contentsOf: queryItems)
            urlComponents.queryItems = items
        }
    }

    public func queryItems(_ queryItems: KeyValuePairs<String, String>) -> URLRequestBuilder {
        self.queryItems(queryItems.map { .init(name: $0.key, value: $0.value) })
    }

    public func queryItem(name: String, value: String) -> URLRequestBuilder {
        queryItems([name: value])
    }

    // MARK: Content Type

    public struct ContentType {
        public static let header = HeaderName(rawValue: "Content-Type")

        public var rawValue: String

        // MARK: - Application
        public static let applicationJSON = ContentType(rawValue: "application/json")
        public static let applicationOctetStream = ContentType(rawValue: "application/octet-stream")
        public static let applicationXML = ContentType(rawValue: "application/xml")
        public static let applicationZip = ContentType(rawValue: "application/zip")
        public static let applicationXWwwFormUrlEncoded = ContentType(rawValue: "application/x-www-form-urlencoded")

        // MARK: - Image
        public static let imageGIF = ContentType(rawValue: "image/gif")
        public static let imageJPEG = ContentType(rawValue: "image/jpeg")
        public static let imagePNG = ContentType(rawValue: "image/png")
        public static let imageTIFF = ContentType(rawValue: "image/tiff")

        // MARK: - Text
        public static let textCSS = ContentType(rawValue: "text/css")
        public static let textCSV = ContentType(rawValue: "text/csv")
        public static let textHTML = ContentType(rawValue: "text/html")
        public static let textPlain = ContentType(rawValue: "text/plain")
        public static let textXML = ContentType(rawValue: "text/xml")

        // MARK: - Video
        public static let videoMPEG = ContentType(rawValue: "video/mpeg")
        public static let videoMP4 = ContentType(rawValue: "video/mp4")
        public static let videoQuicktime = ContentType(rawValue: "video/quicktime")
        public static let videoXMsWmv = ContentType(rawValue: "video/x-ms-wmv")
        public static let videoXMsVideo = ContentType(rawValue: "video/x-msvideo")
        public static let videoXFlv = ContentType(rawValue: "video/x-flv")
        public static let videoWebm = ContentType(rawValue: "video/webm")

        // MARK: - Multipart Form Data
        public static func multipartFormData(boundary: String) -> ContentType {
            ContentType(rawValue: "multipart/form-data; boundary=\(boundary)")
        }
    }

    public func contentType(_ contentType: ContentType) -> URLRequestBuilder {
        header(name: ContentType.header, value: contentType.rawValue)
    }
    
    public func accept(_ contentType: ContentType) -> URLRequestBuilder {
        header(name: .accept, value: contentType.rawValue)
    }

    // MARK: Encoding

    public enum Encoding: String {
        case gzip
        case compress
        case deflate
        case br

        public static let contentEncodingHeader = HeaderName(rawValue: "Content-Encoding")
        public static let acceptEncodingHeader = HeaderName(rawValue: "Accept-Encoding")
    }

    public func contentEncoding(_ encoding: Encoding) -> URLRequestBuilder {
        header(name: Encoding.contentEncodingHeader, value: encoding.rawValue)
    }

    public func acceptEncoding(_ encoding: Encoding) -> URLRequestBuilder {
        header(name: Encoding.acceptEncodingHeader, value: encoding.rawValue)
    }

    // MARK: Other

    public func contentLength(_ length: Int) -> URLRequestBuilder {
        header(name: .contentLength, value: String(length))
    }

    public func header(name: HeaderName, value: String) -> URLRequestBuilder {
        modifyRequest { $0.addValue(value, forHTTPHeaderField: name.rawValue) }
    }

    public func header(name: HeaderName, values: [String]) -> URLRequestBuilder {
        var copy = self
        for value in values {
            copy = copy.header(name: name, value: value)
        }
        return copy
    }

    public func timeout(_ timeout: TimeInterval) -> URLRequestBuilder {
        modifyRequest { $0.timeoutInterval = timeout }
    }
}

// MARK: - Finalizing

extension URLRequestBuilder {
    public func makeRequest(withBaseURL baseURL: URL) -> URLRequest {
        makeRequest(withConfig: .baseURL(baseURL))
    }

    public func makeRequest(withConfig config: RequestConfiguration) -> URLRequest {
        config.configureRequest(self)
    }
}

extension URLRequest {
    public init(baseURL: URL, endpointRequest: URLRequestBuilder) {
        self = endpointRequest.makeRequest(withBaseURL: baseURL)
    }
}

extension URLRequestBuilder {
    public struct RequestConfiguration {
        public init(configureRequest: @escaping (URLRequestBuilder) -> URLRequest) {
            self.configureRequest = configureRequest
        }

        public let configureRequest: (URLRequestBuilder) -> URLRequest
    }
}

extension URLRequestBuilder.RequestConfiguration {
    public static func baseURL(_ baseURL: URL) -> URLRequestBuilder.RequestConfiguration {
        return URLRequestBuilder.RequestConfiguration { request in
            let finalURL = request.urlComponents.url(relativeTo: baseURL) ?? baseURL

            var urlRequest = URLRequest(url: finalURL)
            request.buildURLRequest(&urlRequest)

            return urlRequest
        }
    }
    
    public static func base(scheme: String?, host: String?, port: Int?) -> URLRequestBuilder.RequestConfiguration {
        URLRequestBuilder.RequestConfiguration { request in
            var request = request
            request.urlComponents.scheme = scheme
            request.urlComponents.host = host
            request.urlComponents.port = port
            
            if !request.urlComponents.path.starts(with: "/") {
                request.urlComponents.path = "/" + request.urlComponents.path
            }
            
            guard let finalURL = request.urlComponents.url else {
                preconditionFailure()
            }
            
            var urlRequest = URLRequest(url: finalURL)
            request.buildURLRequest(&urlRequest)
            
            return urlRequest
        }
    }
}

// MARK: - HeaderName

extension URLRequestBuilder {
    public struct HeaderName {
        public var rawValue: String

        public static let userAgent: HeaderName = "User-Agent"
        public static let cookie: HeaderName = "Cookie"
        public static let authorization: HeaderName = "Authorization"
        public static let accept: HeaderName = "Accept"
        public static let contentLength: HeaderName = "Content-Length"
        
        public static let contentType = URLRequestBuilder.ContentType.header
        public static let contentEncoding = URLRequestBuilder.Encoding.contentEncodingHeader
        public static let acceptEncoding = URLRequestBuilder.Encoding.acceptEncodingHeader
    }
}

extension URLRequestBuilder.HeaderName: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}
