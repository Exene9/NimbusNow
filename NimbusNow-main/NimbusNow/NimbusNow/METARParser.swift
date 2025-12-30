import Foundation

struct WeatherConditions {
    var raw: String = ""
    var windDirection: Int = 0
    var windSpeed: Int = 0
    var visibility: Double = 10.0
    var tempC: Double = 0.0
    var altimeter: Double = 29.92
    var ceiling: Double = 100000 // Default to high/unlimited
    var flightCategory: String = "VFR"
}

struct METARParser {
    
    static func parse(_ raw: String) -> WeatherConditions {
        var wx = WeatherConditions()
        wx.raw = raw
        
        let cleanRaw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleanRaw.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        // Track the lowest "broken" or "overcast" layer found
        var lowestCeiling: Double? = nil
        
        for (index, part) in parts.enumerated() {
            
            // 1. WIND (Format: 36010KT or VRB05KT)
            if part.hasSuffix("KT") {
                // Typical format: DDDSSKT (e.g., 36010KT)
                let windStr = part.dropLast(2) // Remove KT
                if windStr.count >= 5 {
                    let dirStr = windStr.prefix(3)
                    let spdStr = windStr.dropFirst(3) // Handles 10 or 10G20
                    
                    if let dir = Int(dirStr) { wx.windDirection = dir }
                    // Simple logic: grab first 2 digits of speed. Ignoring gusts for simplicity.
                    let speedClean = spdStr.prefix(2)
                    if let spd = Int(speedClean) { wx.windSpeed = spd }
                }
            }
            
            // 2. VISIBILITY (Fixed logic)
            if part.hasSuffix("SM") {
                let valString = String(part.dropLast(2)) // remove "SM"
                
                // Case A: Simple integer or fraction "10SM" or "1/2SM"
                if let val = parseVisibilityNumber(valString) {
                    wx.visibility = val
                    
                    // Case B: "1 1/2SM" -> The "1" was the previous part!
                    // Check if previous part was a single digit number
                    if index > 0 {
                        let prevPart = parts[index - 1]
                        if let prevVal = Int(prevPart) {
                            wx.visibility += Double(prevVal)
                        }
                    }
                }
            }
            
            // 3. CLOUDS / CEILING (Looking for BKN or OVC)
            // Format: OVC007 (Overcast 700ft) or BKN020 (Broken 2000ft) or VV003
            if (part.hasPrefix("BKN") || part.hasPrefix("OVC") || part.hasPrefix("VV")) && part.count >= 6 {
                let layerHeightStr = part.suffix(3) // Get last 3 digits "007"
                if let heightRaw = Double(layerHeightStr) {
                    let heightInFeet = heightRaw * 100
                    
                    // Ceiling is defined as the lowest Broken or Overcast layer
                    if lowestCeiling == nil || heightInFeet < lowestCeiling! {
                        lowestCeiling = heightInFeet
                    }
                }
            }
            
            // 4. TEMPERATURE (Format: 22/10 or 22/M05)
            if part.contains("/") {
                let subParts = part.components(separatedBy: "/")
                if subParts.count == 2 {
                    // Ensure it looks like temp (not R35/2000)
                    if isTempNumber(subParts[0]) && isTempNumber(subParts[1]) {
                        wx.tempC = parseMetarNumber(subParts[0])
                    }
                }
            }
            
            // 5. ALTIMETER
            if (part.hasPrefix("A") || part.hasPrefix("Q")) && part.count == 5 {
                let numStr = String(part.dropFirst())
                if let val = Double(numStr) {
                    if part.hasPrefix("A") { wx.altimeter = val / 100.0 }
                    else { wx.altimeter = val * 0.02953 }
                }
            }
        }
        
        // Finalize Ceiling
        if let actualCeiling = lowestCeiling {
            wx.ceiling = actualCeiling
        }
        
        // 6. CALCULATE CATEGORY (Now uses actual ceiling)
        wx.flightCategory = calculateFlightCategory(vis: wx.visibility, ceil: wx.ceiling)
        
        return wx
    }
    
    // --- HELPERS ---
    
    private static func isTempNumber(_ str: String) -> Bool {
        let clean = str.replacingOccurrences(of: "M", with: "")
        // Simple check: strict integer, max 2-3 chars, excludes things like "P2000"
        return Int(clean) != nil && clean.count <= 3
    }
    
    private static func parseMetarNumber(_ str: String) -> Double {
        var numStr = str
        var multiplier = 1.0
        if numStr.hasPrefix("M") {
            multiplier = -1.0
            numStr = String(numStr.dropFirst())
        }
        return (Double(numStr) ?? 0.0) * multiplier
    }

    private static func parseVisibilityNumber(_ str: String) -> Double? {
        if let val = Double(str) { return val }
        if str.contains("/") {
            let parts = str.components(separatedBy: "/")
            if parts.count == 2, let n = Double(parts[0]), let d = Double(parts[1]), d != 0 {
                return n / d
            }
        }
        return nil
    }
    
    private static func calculateFlightCategory(vis: Double, ceil: Double) -> String {
        // LIFR: Ceiling < 500 OR Vis < 1
        if ceil < 500 || vis < 1 { return "LIFR" }
        
        // IFR: Ceiling 500 to < 1000 OR Vis 1 to < 3
        if ceil < 1000 || vis < 3 { return "IFR" }
        
        // MVFR: Ceiling 1000 to 3000 OR Vis 3 to 5
        if ceil <= 3000 || vis <= 5 { return "MVFR" }
        
        // VFR: Ceiling > 3000 AND Vis > 5
        return "VFR"
    }
}
