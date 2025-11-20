import SwiftUI
// You need to add "CodeScanner" via File -> Add Packages -> Search "CodeScanner"
// If you can't add packages, replace CodeScannerView with a simple Button for testing.
import CodeScanner
internal import AVFoundation

struct ContentView: View {
    @StateObject var manager = AttendanceManager()
    @State private var isShowingScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack {
                    Image(systemName: "wifi.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(manager.pendingLogs.isEmpty ? .green : .orange)
                    Text("Attendance Tracker")
                        .font(.largeTitle)
                        .bold()
                    Text(manager.statusMessage)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Stats Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current Session")
                        .font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Logs Stored")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(manager.pendingLogs.count)")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                        if manager.isTracking {
                            PulsingView() // Visual indicator needed for user trust
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                // Action Button
                if manager.isTracking {
                    Button(action: {
                        manager.endClass()
                    }) {
                        Text("End Class & Sync")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan Classroom QR")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr]) { response in
                    switch response {
                    case .success(let result):
                        manager.startClass(classCode: result.string)
                        isShowingScanner = false
                    case .failure(let error):
                        print(error.localizedDescription)
                        isShowingScanner = false
                    }
                }
            }
        }
    }
}

// A small animation to show the app is alive
struct PulsingView: View {
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 15, height: 15)
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0.5)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = true }
    }
}
