import Foundation
import CoreLocation
import Combine

// Data structure for a single GPS ping, including Altitude (Height)
struct LocationLog: Codable, Identifiable {
    var id = UUID()
    let lat: Double
    let lon: Double
    let alt: Double // Height from sea level
    let timestamp: Date
}

class AttendanceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = false
    @Published var statusMessage = "Ready to scan"
    @Published var pendingLogs: [LocationLog] = []
      
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var currentClassID: String?
    // In a real app, this ID would come from a login screen
    private let studentID = "Student_001"
    
    // CHANGE THIS IP to your Mac's Local IP address (System Settings -> Wi-Fi -> Details)
    // Ensure the port matches your Python script (5000)
    private let serverURL = "http://10.10.6.203:5001/submit-log"
    override init() {
        super.init()
        locationManager.delegate = self
        // Critical for background tracking
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Improve accuracy for Altitude to ensure we get height data
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        loadOfflineLogs()
    }
    
    // MARK: - Start/Stop Class
    func startClass(classCode: String) {
        self.currentClassID = classCode
        self.isTracking = true
        self.statusMessage = "Class \(classCode) Started. Tracking..."
        
        locationManager.startUpdatingLocation()
        
        // Collect data every 2 minutes (120 seconds) as per requirements
        timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
            self.captureLocation()
        }
        // Capture immediately upon check-in
        captureLocation()
    }
    
    func endClass() {
        self.isTracking = false
        self.statusMessage = "Class Ended. Syncing data..."
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
        syncData()
    }
    
    // MARK: - Location Capture
    private func captureLocation() {
        guard let loc = locationManager.location else { return }
        
        // Capturing Altitude (Height) now
        let newLog = LocationLog(
            lat: loc.coordinate.latitude,
            lon: loc.coordinate.longitude,
            alt: loc.altitude,
            timestamp: Date()
        )
        
        pendingLogs.append(newLog)
        saveLogsLocally() // Save to disk immediately
        print("📍 Log Captured: Lat:\(newLog.lat) Lon:\(newLog.lon) Alt:\(newLog.alt)")
        
        // Try to sync immediately if internet is available
        syncData()
    }
    
    // MARK: - Offline/Online Sync Logic
    func syncData() {
        guard let url = URL(string: serverURL), !pendingLogs.isEmpty else { return }
        
        // Prepare the payload matching the Python Server expectations
        let payload: [String: Any] = [
            "student_id": studentID,
            "class_id": currentClassID ?? "Unknown",
            "logs": pendingLogs.map { [
                "lat": $0.lat,
                "lon": $0.lon,
                "alt": $0.alt,
                "timestamp": $0.timestamp.description
            ]}
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Sync failed (Likely Offline): \(error.localizedDescription)")
                // We do nothing here; logs remain in 'pendingLogs' to be retried later
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Data Synced Successfully with Server")
                DispatchQueue.main.async {
                    // Clear logs only after successful server confirmation
                    self?.pendingLogs.removeAll()
                    self?.saveLogsLocally()
                    self?.statusMessage = "Data Synced!"
                }
            }
        }.resume()
    }
    
    // MARK: - Disk Storage (Persistence)
    // This ensures data survives if the app is closed or phone restarts
    private func saveLogsLocally() {
        if let encoded = try? JSONEncoder().encode(pendingLogs) {
            UserDefaults.standard.set(encoded, forKey: "offline_logs")
        }
    }
    
    private func loadOfflineLogs() {
        if let data = UserDefaults.standard.data(forKey: "offline_logs"),
           let decoded = try? JSONDecoder().decode([LocationLog].self, from: data) {
            pendingLogs = decoded
        }
    }
}
