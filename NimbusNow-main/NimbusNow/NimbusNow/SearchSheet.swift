import SwiftUI
struct SearchSheet: View {
    @Binding var airfieldCode: String
    @Binding var stationName: String
    var onFetch: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var input = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Manual Station Search")
                    .font(.headline)
                    .padding(.top)
                
                TextField("Enter ICAO (e.g. KJFK)", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .textCase(.uppercase)
                
                Button("Load Weather") {
                    if !input.isEmpty {
                        airfieldCode = input.uppercased()
                        stationName = "Manual Entry" // Reset name since we don't have it from GPS
                        onFetch()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(input.isEmpty)
                
                Spacer()
            }
        }
        .presentationDetents([.height(250)])
    }
}
