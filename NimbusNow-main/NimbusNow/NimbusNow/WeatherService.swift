import Foundation

class WeatherService {
    static func fetchMETAR(for station: String, completion: @escaping (Result<WeatherConditions, Error>) -> Void) {
        // "metar" endpoint returns the current raw observation
        let urlString = "https://aviationweather.gov/api/data/metar?ids=\(station)"
        
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            
            guard let data = data, let rawString = String(data: data, encoding: .utf8) else { return }
            
            // Parse immediately
            let conditions = METARParser.parse(rawString)
            completion(.success(conditions))
        }.resume()
    }
}
