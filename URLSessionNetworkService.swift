import Foundation

// Define a generic network error enum
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case noData
    case decodingFailed(Error)
    case unacceptableStatusCode(Int)
}

class URLSessionNetworkService: NetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<R: NetworkRequest>(_ requestDetails: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        guard var urlComponents = URLComponents(url: requestDetails.baseURL.appendingPathComponent(requestDetails.path), resolvingAgainstBaseURL: false) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // If it's a GET request and there's a body, assume it's query parameters
        // This is a common pattern, but for strict REST, GET shouldn't have a body.
        // For this example, we'll interpret 'body' for GET as query items if they are form-urlencoded.
        if requestDetails.method == .get, let bodyData = requestDetails.body {
            if let query = String(data: bodyData, encoding: .utf8) {
                 // Attempt to parse as query string; or expect pre-formed query items
                 // For simplicity, let's assume body for GET is a query string or needs specific handling.
                 // A more robust solution would be to define queryItems directly in NetworkRequest.
                 // Here, we'll just append if it looks like a query string.
                 // This part might need refinement based on actual use case for GET with body.
                 // For now, we'll assume GET requests with body mean query parameters.
                 // A better way is to have `queryItems: [URLQueryItem]?` in `NetworkRequest`.
                 // Let's assume for now that GET requests will have their parameters in the path or URLComponents should be used.
                 // So, we will ignore 'body' for GET in this generic implementation.
            }
        }


        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestDetails.method.rawValue
        urlRequest.allHTTPHeaderFields = requestDetails.headers

        // Set Content-Type if not already set and body exists
        if requestDetails.body != nil && urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        urlRequest.httpBody = requestDetails.body


        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.requestFailed(URLError(.badServerResponse)))) // Or a custom error
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.unacceptableStatusCode(httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(R.ResponseType.self, from: data)
                completion(.success(responseObject))
            } catch {
                completion(.failure(NetworkError.decodingFailed(error)))
            }
        }
        task.resume()
    }
}
