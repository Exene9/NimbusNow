import SwiftUI


struct WindToolView: View {
    let wx: WeatherConditions
    @Environment(\.presentationMode) var presentationMode
    @State private var runwayHeading: Double = 250
    
    var crosswind: Double {
        let delta = Double(wx.windDirection) - runwayHeading
        let radians = delta * .pi / 180
        return abs(Double(wx.windSpeed) * sin(radians))
    }
    
    var headwind: Double {
        let delta = Double(wx.windDirection) - runwayHeading
        let radians = delta * .pi / 180
        return Double(wx.windSpeed) * cos(radians)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                Text("Align the runway to check crosswind limits.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 260, height: 260)
                    
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 60, height: 280)
                        .overlay(
                            Text("\(Int(runwayHeading/10))")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-runwayHeading))
                                .offset(y: 110)
                        )
                        .cornerRadius(6)
                        .rotationEffect(.degrees(runwayHeading))
                        .animation(.spring(), value: runwayHeading)
                    
                    Image(systemName: "arrow.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 120)
                        .foregroundColor(.blue)
                        .offset(y: -110)
                        .rotationEffect(.degrees(Double(wx.windDirection)))
                        .animation(.spring(), value: wx.windDirection)
                    
                    Image(systemName: "airplane")
                        .font(.largeTitle)
                        .rotationEffect(.degrees(runwayHeading - 90))
                }
                
                HStack(spacing: 40) {
                    StatBox(label: "Headwind", value: String(format: "%.0f kt", headwind), color: headwind < 0 ? .red : .green)
                    StatBox(label: "Crosswind", value: String(format: "%.0f kt", crosswind), color: crosswind > 15 ? .orange : .primary)
                }
                
                VStack {
                    Text("Runway Heading: \(Int(runwayHeading))°")
                        .font(.headline)
                    Slider(value: $runwayHeading, in: 0...360, step: 10)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Wind Calculator")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}



struct WindToolView_Previews: PreviewProvider {
    static var previews: some View {
        WindToolView(wx: WeatherConditions(windDirection: 90, windSpeed: 20))
    }
}
