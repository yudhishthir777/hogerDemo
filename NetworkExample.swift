import Foundation

// 1. Define a Codable struct for the data to be fetched
struct Post: Codable, Identifiable {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}

// 2. Define a specific request struct conforming to NetworkRequest
struct GetPostsRequest: NetworkRequest {
    typealias ResponseType = [Post] // We expect an array of Post objects

    var baseURL: URL { URL(string: "https://jsonplaceholder.typicode.com")! }
    var path: String { "/posts" }
    var method: HTTPMethod { .get }
    // Headers and body are nil by default, which is fine for this GET request
}

// 3. Example of how to use the network service (e.g., in a ViewModel or another service)
class PostViewModel {
    private let networkService: NetworkService

    init(networkService: NetworkService = URLSessionNetworkService()) {
        self.networkService = networkService
    }

    func fetchPosts() {
        let postsRequest = GetPostsRequest()

        networkService.request(postsRequest) { (result: Result<[Post], Error>) in
            switch result {
            case .success(let posts):
                print("Successfully fetched \(posts.count) posts.")
                // Here you would typically update your UI or publish the posts
                // For example, posts.forEach { print("- \($0.title)") }
            case .failure(let error):
                print("Error fetching posts: \(error)")
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .invalidURL:
                        print("Detail: Invalid URL")
                    case .requestFailed(let underlyingError):
                        print("Detail: Request failed - \(underlyingError.localizedDescription)")
                    case .noData:
                        print("Detail: No data received")
                    case .decodingFailed(let underlyingError):
                        print("Detail: Decoding failed - \(underlyingError.localizedDescription)")
                    case .unacceptableStatusCode(let statusCode):
                        print("Detail: Unacceptable status code - \(statusCode)")
                    }
                }
            }
        }
    }
}

// To run this example (e.g., in a test environment or a simple command-line tool):
// let viewModel = PostViewModel()
// viewModel.fetchPosts()
