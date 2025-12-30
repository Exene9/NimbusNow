import SwiftUI
import CoreLocation

struct ContentView: View {
    // MARK: - State Management
    @StateObject private var locationManager = LocationManager()
    @State private var airfieldCode = "----"
    @State private var stationName = "Locating..."
    @State private var wx = WeatherConditions()
    
    // UI Triggers
    @State private var showWindTool = false
    @State private var showSearch = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background Color
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    
                    // --- 1. HEADERS ---
                    VStack(spacing: 8) {
                        Text(airfieldCode)
                            .font(.system(size: 42, weight: .heavy, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Text(stationName) // Display Airport Name
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.top, 20)

                    // --- 2. MAIN INSTRUMENTS (Gauges) ---
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ConditionCard(
                            icon: "eye.fill",
                            title: "Visibility",
                            value: String(format: "%.1f SM", wx.visibility),
                            color: wx.visibility < 3 ? .red : .green
                        )
                        
                        ConditionCard(
                            icon: "thermometer",
                            title: "Temp",
                            value: "\(wx.tempC)°C",
                            color: .orange
                        )
                        
                        ConditionCard(
                            icon: "gauge",
                            title: "Altimeter",
                            value: String(format: "%.2f", wx.altimeter),
                            color: .purple
                        )
                        
                        ConditionCard(
                            icon: "airplane.circle",
                            title: "Flight Rules",
                            value: wx.flightCategory,
                            color: wx.flightCategory == "VFR" ? .green : .red
                        )
                    }
                    .padding(.horizontal)

                    Spacer()

                    // --- 3. TOOLS SECTION (Buttons) ---
                    Button(action: { showWindTool = true }) {
                        HStack {
                            Image(systemName: "safari.fill") // Compass icon
                                .font(.title2)
                            Text("Open Wind & Runway Tool")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("NimbusNow")
            .navigationBarTitleDisplayMode(.inline)
            
            // --- TOP RIGHT SEARCH BUTTON ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .bold))
                    }
                }
            }
            // --- SHEET 1: Search ---
            .sheet(isPresented: $showSearch) {
                SearchSheet(airfieldCode: $airfieldCode, stationName: $stationName, onFetch: fetchWeather)
            }
            // --- SHEET 2: Wind Tool ---
            .sheet(isPresented: $showWindTool) {
                WindToolView(wx: wx)
            }
        }
        // --- GPS LOGIC ---
        .onAppear {
            print("requesting location")
            locationManager.requestLocation()
        }
        // iOS 17+ Syntax Fix:
        .onChange(of: locationManager.location) { _, newLocation in
            if let loc = newLocation {
                print("Location update received: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
                isLoading = true
                
                DispatchQueue.global(qos: .userInitiated).async {
                    print("Searching for nearest airport to user location")
                    
                    if let nearest = AirportLoader.shared.findNearestAirport(to: loc) {
                        print("nearest: \(nearest.code) (\(nearest.name))")
                        
                        DispatchQueue.main.async {
                            self.airfieldCode = nearest.code
                            self.stationName = nearest.name
                            self.fetchWeather()
                        }
                    } else {
                        print("No airport found nearby.")
                        DispatchQueue.main.async { isLoading = false }
                    }
                }
            }
        }
    }
    
    func fetchWeather() {
        guard airfieldCode != "----" else { return }
        print("☁️ Fetching weather for \(airfieldCode)...")
        
        WeatherService.fetchMETAR(for: airfieldCode) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let data):
                    print("☀️ Weather received for \(airfieldCode)")
                    self.wx = data
                case .failure(let error):
                    print("⚠️ Error fetching weather: \(error.localizedDescription)")
                }
            }
        }
    }
}
