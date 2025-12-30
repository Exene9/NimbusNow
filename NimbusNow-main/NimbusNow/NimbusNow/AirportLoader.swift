import Foundation
import CoreLocation

struct Airport: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let location: CLLocation
}

class AirportLoader {
    static let shared = AirportLoader()
    var airports: [Airport] = []

    init() {
        loadAirports()
    }

    func loadAirports() {
        guard let path = Bundle.main.path(forResource: "airport-codes", ofType: "csv") else {
            print("CSV file not found")
            return
        }

        do {
            print("Starting CSV")
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var loadedAirports: [Airport] = []
            
            for (index, line) in lines.enumerated() {
               
                if index == 0 { continue }
                
                let columns = parseCSVLine(line)
                
                
                if columns.count > 1 {
                    
                    let gpsCode = columns[8].replacingOccurrences(of: "\"", with: "") // 'ICAO' column
                    let name = columns[2].replacingOccurrences(of: "\"", with: "")    // 'name' column
                    let coordString = columns[12].replacingOccurrences(of: "\"", with: "") // 'coordinates'
                    
                    if !gpsCode.isEmpty {
                        if let location = parseCoordinates(coordString) {
                            let airport = Airport(code: gpsCode, name: name, location: location)
                            loadedAirports.append(airport)
                            
                            
                            if loadedAirports.count <= 3 {
                                print("   Parsed: \(name) (\(gpsCode)) at \(location.coordinate.latitude)")
                            }
                        }
                    }
                }
            }
            
            self.airports = loadedAirports
            print("Successfully loaded \(self.airports.count) airports.")
            
        } catch {
            print("Error reading CSV: \(error)")
        }
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)
        return result
    }
    
    private func parseCoordinates(_ coordString: String) -> CLLocation? {
        
        let parts = coordString.components(separatedBy: ",")
        
        if parts.count == 2 {
            let p0 = parts[0].trimmingCharacters(in: .whitespaces)
            let p1 = parts[1].trimmingCharacters(in: .whitespaces)
            
            
            if let lon = Double(p0), let lat = Double(p1) {
                // Validate Earth ranges (Lat -90 to 90, Lon -180 to 180)
                if abs(lat) <= 90 && abs(lon) <= 180 {
                    return CLLocation(latitude: lat, longitude: lon)
                }
            }
            
           
            if let lat = Double(p0), let lon = Double(p1) {
                if abs(lat) <= 90 && abs(lon) <= 180 {
                    return CLLocation(latitude: lat, longitude: lon)
                }
            }
        }
        return nil
    }

    func findNearestAirport(to location: CLLocation) -> Airport? {
        if airports.isEmpty {
            print("list is empty")
            return nil
        }
        
        
        return airports.min(by: { a, b in
            a.location.distance(from: location) < b.location.distance(from: location)
        })
    }
}
