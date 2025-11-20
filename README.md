Offline-First QR Attendance System

A robust, offline-capable mobile attendance tracking system designed for educational institutions with unreliable internet connectivity. This system allows students to mark attendance via QR codes even in "dead zones" (basements, lecture halls), syncing data automatically once a connection is restored.

🚩 The Problem
Traditional attendance apps fail in two critical areas:

Connectivity: Lecture halls and basements often lack stable cellular or Wi-Fi signals. Cloud-only apps fail to load, causing bottlenecks at the door.

Integrity: Simple QR scanners are prone to "buddy punching" (marking attendance for absent friends).

💡 The Solution
This project implements a Store-and-Forward architecture:

Capture: Attendance is recorded immediately using local storage (UserDefaults/JSON).

Verify: GPS and Altitude data are captured to validate physical presence inside the classroom.

Sync: A background network monitor detects when connectivity returns and automatically uploads batched logs to the central server.

✨ Key Features
📱 iOS Client (Swift)
Offline-First Engine: Uses NWPathMonitor to detect network status. If offline, logs are serialized and stored locally in UserDefaults.

Smart Sync: Automatically attempts to flush the local buffer to the server every time the network becomes available.

Location Validation: Captures Latitude, Longitude, and Altitude (Height from sea level) to prevent remote spoofing.

Visual Feedback: Real-time UI indicators (Green/Orange pulsing) show the user if the app is tracking and if data is pending sync.

🖥️ Backend Server (Python/Flask)
SQLite Persistence: Lightweight, serverless database setup.

Geofence Logic: Server-side verification checks if the student is within a specific radius (70% rule) and height tolerance of the classroom.

Batch Processing: API endpoints designed to handle bulk uploads of logs to reduce network overhead.

🛠️ Tech Stack
Mobile: Swift, SwiftUI, Combine, CoreLocation, AVFoundation.

Dependencies:(https://github.com/twostraws/CodeScanner) (for QR scanning).

Backend: Python 3, Flask.

Database: SQLite (with Write-Ahead Logging for concurrency).

🚀 Getting Started
1. Backend Setup
The backend is a lightweight Flask microservice.bash

Clone the repository
git clone https://github.com/princegajnani/QR-based-Attendance-System.git cd QR-based-Attendance-System

Set up virtual environment (Optional but recommended)
python3 -m venv venv source venv/bin/activate # On Windows use venv\Scripts\activate

Install Flask
pip install flask

Run the server
python server.py
