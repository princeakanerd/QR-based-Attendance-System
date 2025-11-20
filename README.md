Here is a professional, ready-to-use README.md file formatted for GitHub. You can copy this directly into your repository.

I have structured it to highlight the "Offline-First" architecture and the engineering decisions we discussed in the report (like SQLite WAL mode and Core Data synchronization).

📱 Offline-First Biometric Attendance System
(https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat&logo=swift)](https://developer.apple.com/swift/) (https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A robust, offline-capable mobile attendance tracking system designed for universities with unreliable internet connectivity ("dead zones"). This system prevents fraud using biometric verification and geolocation while ensuring zero data loss during network outages.

📖 Table of Contents
-(#-problem-statement)

Key Features -(#-system-architecture) -(#-getting-started) -(#backend-setup) -(#ios-client-setup) -(#-technical-details) -(#-roadmap)

License

🚩 Problem Statement
Traditional attendance systems fail in two critical areas:

Connectivity: Lecture halls and basements often lack stable cellular or Wi-Fi signals. Cloud-only apps fail to load, causing bottlenecks at the door.

Integrity: "Buddy punching" (marking attendance for absent friends) is rampant with simple QR scanning apps.

The Solution: An app that works 100% offline, storing cryptographically signed logs locally and synchronizing them automatically when the device reconnects.

🌟 Key Features
📶 Offline-First Engine: Users can scan and "check in" without any internet connection. Data is persisted locally using Core Data / UserDefaults and synced via background tasks.

📍 Geofence Validation: Verifies student presence using the Haversine Formula to calculate distance from the classroom coordinates.

👤 Biometric Security: Integrates with iOS LocalAuthentication (FaceID/TouchID) to bind attendance records to the physical user.

🔄 Smart Synchronization: Utilizes NWPathMonitor to detect network state changes and trigger batch uploads automatically.

🛡️ Anti-Fraud Logic: Server-side checks for "impossible travel" (location jumping) and time-window validation.

🏗 System Architecture
Mobile Client (iOS)
Frameworks: SwiftUI, Combine, CoreLocation, AVFoundation.

Scanning: Uses CodeScanner for rapid QR detection.

Persistence: Local storage buffer for pending logs using JSON encoding/Core Data.

Backend Server (Python)
Framework: Flask (Microservice architecture).

Database: SQLite configured with Write-Ahead Logging (WAL) for high-concurrency write performance.   

API: RESTful endpoints receiving batched JSON payloads.

🚀 Getting Started
Prerequisites
Xcode 14+ (for iOS App)

Python 3.9+ (for Backend)

iPhone (Physical device required for Camera & FaceID testing)

Backend Setup
Clone the repo and navigate to the server directory:

Bash

git clone https://github.com/yourusername/offline-attendance.git
cd offline-attendance/server
Create and activate a virtual environment:

Bash

python3 -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
Install dependencies:

Bash

pip install flask
Run the server:

Bash

python server.py
The server will start on port 5000 (e.g., http://127.0.0.1:5000).

iOS Client Setup
Open AttendanceApp.xcodeproj in Xcode.

Add Dependencies:

Go to File > Add Packages...

Search for and add: https://github.com/twostraws/CodeScanner.

Configure Network:

Open AttendanceManager.swift.

Find the serverURL variable.

Crucial: Change http://10.10.6.203:5001 to your computer's local IP address (found in System Settings > Wi-Fi > Details).

Permissions:

Ensure Info.plist contains keys for:

NSCameraUsageDescription ("Needed to scan class QR codes")

NSLocationWhenInUseUsageDescription ("Needed to verify you are in the classroom")

Build and run on your iPhone.

🧠 Technical Details
The "Offline" Sync Logic
The app uses a reactive NWPathMonitor to listen for network changes.

Scan Event: Data is instantly written to UserDefaults (Disk). UI updates to "Checked In (Pending Sync)".

Network Restoration: The AttendanceManager detects a valid path (.satisfied).

Batch Upload: All pending logs are wrapped in a single JSON transaction and sent to /submit-log.

Confirmation: Only upon receiving a 200 OK from the server are the local logs cleared.

Database Concurrency
To handle hundreds of students scanning simultaneously, the SQLite backend is configured with:

Python

# Enables non-blocking reads/writes
c.execute("PRAGMA journal_mode=WAL")
This allows the simple file-based database to scale significantly without locking issues.   

🗺 Roadmap
[ ] iBeacon Integration: Add support for BLE beacons for higher-precision indoor location (ignoring GPS drift).   

[ ] Dynamic QR Codes: Implement TOTP (Time-based One-Time Password) QR codes that rotate every 30 seconds to prevent photo-sharing fraud.

[ ] Admin Dashboard: A React-based web frontend for professors to view analytics and export CSVs.

🤝 Contributing
Contributions are welcome! Please follow these steps:

Fork the Project.

Create your Feature Branch (git checkout -b feature/AmazingFeature).

Commit your Changes (git commit -m 'Add some AmazingFeature').

Push to the Branch (git push origin feature/AmazingFeature).

Open a Pull Request.
