# NimbusNow

**NimbusNow** is a specialized aviation weather application built with **SwiftUI**. It bypasses standard weather formats to fetch and parse raw **METAR** (Meteorological Aerodrome Report) data directly from the Aviation Weather Center (NOAA), providing pilots with critical, real-time flight conditions and wind calculations.

---

## Features

* **Nearest Airport Discovery**: Leverages `CoreLocation` and a custom `AirportLoader` to parse a global dataset and identify the closest airfield to the user's GPS coordinates.
* **METAR Parsing Engine**: Implements logic to translate complex raw strings (e.g., `KJFK 36010KT 10SM OVC007`) into structured data, including visibility, wind, temperature, altimeter, and cloud layers.
* **Flight Category Calculation**: Automatically determines flight rules (**VFR, MVFR, IFR, or LIFR**) by evaluating current visibility and ceiling heights against aviation standards.
* **Visual Wind Tool**: Features an interactive calculator where users can rotate a virtual runway to visualize headwind and crosswind components based on current METAR wind data.
* **Manual Station Search**: Allows users to manually enter any ICAO airport code globally to instantly load current conditions.

## Technical Architecture

* **`LocationManager.swift`**: Manages user permissions and provides real-time location updates via `CLLocationManagerDelegate`.
* **`METARParser.swift`**: The core logic engine that uses string parsing to extract wind vectors, temperature in Celsius, and altimeter settings.
* **`AirportLoader.swift`**: Handles CSV parsing and uses distance calculations to find the nearest `Airport` object to a given `CLLocation`.
* **`WeatherService.swift`**: Manages asynchronous API calls to `aviationweather.gov` to retrieve the latest raw observation strings.
* **`WindToolView.swift`**: A SwiftUI view utilizing trigonometric functions (`sin`, `cos`) to calculate specific wind angles relative to runway heading.

## Setup & Installation

1.  **Clone the repository**:
    ```bash
    git clone [https://github.com/Exene9/NimbusNow.git](https://github.com/Exene9/NimbusNow.git)
    ```
2.  **Add Assets**: Ensure an `airport-codes.csv` file is included in the project bundle for the `AirportLoader` to function.
3.  **Requirements**: Xcode 15+ and iOS 17+ (due to `.onChange` syntax usage).

## Data Logic Flow

1.  **Identify**: `LocationManager` detects the device's current location.
2.  **Match**: `AirportLoader` scans the database for the nearest ICAO code.
3.  **Fetch**: `WeatherService` pulls raw text data for that specific station.
4.  **Parse**: `METARParser` converts the raw string into a structured `WeatherConditions` object.
5.  **Display**: `ContentView` updates the UI with dynamic indicators (e.g., Green for VFR, Red for IFR).

