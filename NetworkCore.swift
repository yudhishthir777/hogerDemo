import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    // Add other methods like DELETE, PATCH if needed in the future
}

protocol NetworkRequest {
    associatedtype ResponseType: Decodable

    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

extension NetworkRequest {
    var headers: [String: String]? { nil }
    var body: Data? { nil }
}

protocol NetworkService {
    func request<R: NetworkRequest>(_ requestDetails: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void)
}
