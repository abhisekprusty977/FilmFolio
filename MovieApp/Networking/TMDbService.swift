import Foundation
class TMDbService: ObservableObject {
    private let networkService: NetworkServiceProtocol
    private let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    
    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
        
        // Load API key from Config.plist safely
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["APIKey"] as? String, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.apiKey = key
        } else {
            // Don't crash the app; set to empty and log a helpful message
            self.apiKey = ""
#if DEBUG
            print("[TMDbService] Warning: TMDb API key not found in Config.plist. Create Config.plist with an 'APIKey' string.")
#endif
        }
    }
    
    // MARK: - Popular Movies
    func fetchPopularMovies(page: Int = 1) async throws -> TMDbResponse {
        guard let url = buildURL(endpoint: "/movie/popular", queryItems: [
            URLQueryItem(name: "page", value: "\(page)")
        ]) else {
            throw NetworkError.invalidURL
        }
        
        return try await networkService.fetch(TMDbResponse.self, from: url)
    }
    
    // MARK: - Search Movies
    func searchMovies(query: String, page: Int = 1) async throws -> TMDbResponse {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let url = buildURL(endpoint: "/search/movie", queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)")
              ]) else {
            throw NetworkError.invalidURL
        }
        
        return try await networkService.fetch(TMDbResponse.self, from: url)
    }
    
    // MARK: - Movie Details
    func fetchMovieDetails(id: Int) async throws -> MovieDetail {
        guard let url = buildURL(endpoint: "/movie/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        return try await networkService.fetch(MovieDetail.self, from: url)
    }
    
    // MARK: - Helper Methods
    private func buildURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        // Ensure API key is set; if not, avoid building a bad URL and surface a helpful log
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
#if DEBUG
            print("[TMDbService] Error: Missing TMDb API key. Requests will fail until Config.plist provides 'APIKey'.")
#endif
            return nil
        }
        
        guard var components = URLComponents(string: baseURL + endpoint) else {
            return nil
        }
        
        var items = [URLQueryItem(name: "api_key", value: apiKey)]
        items.append(contentsOf: queryItems)
        components.queryItems = items
        
        return components.url
    }
}

