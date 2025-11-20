import sqlite3
from flask import Flask, request, jsonify
import math

app = Flask(__name__)

# --- DATABASE SETUP (SQLite) ---
def init_db():
    conn = sqlite3.connect('attendance.db')
    c = conn.cursor()
    # Create table for logs if not exists
    c.execute('''CREATE TABLE IF NOT EXISTS logs 
                 (student_id TEXT, class_id TEXT, lat REAL, lon REAL, alt REAL, timestamp TEXT)''')
    conn.commit()
    conn.close()

# Initialize DB on start
init_db()

# --- CLASSROOM CONFIGURATION ---
# Added 'alt' (altitude in meters) as per your requirement
classrooms = {
    "CS101": {
        "lat": 37.7749, 
        "lon": -122.4194,
        "alt": 15.0,      # Height from sea level (e.g., 2nd floor)
        "radius_meters": 50,
        "height_tolerance": 5.0 # Allow +/- 5 meters variation
    }
}

def haversine_distance(lat1, lon1, lat2, lon2):
    R = 6371000 # Earth radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2) * math.sin(dlambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    return R * c

@app.route('/submit-log', methods=['POST'])
def submit_log():
    data = request.json
    student_id = data.get('student_id')
    class_id = data.get('class_id')
    logs = data.get('logs', []) # List of dicts: {lat, lon, alt, timestamp}
    
    if not logs:
        return jsonify({"message": "No logs provided"}), 400

    print(f"Received {len(logs)} logs from {student_id} for {class_id}")

    # 1. Store logs in Real DB (SQLite)
    conn = sqlite3.connect('attendance.db')
    c = conn.cursor()
    for log in logs:
        # Default altitude to 0 if missing, though app sends it
        alt = log.get('alt', 0.0)
        c.execute("INSERT INTO logs VALUES (?, ?, ?, ?, ?, ?)", 
                  (student_id, class_id, log['lat'], log['lon'], alt, log['timestamp']))
    conn.commit()
    conn.close()
    
    # 2. Calculate Attendance Logic (70% Rule + Height Check)
    if class_id in classrooms:
        target = classrooms[class_id]
        inside_count = 0
        total_count = len(logs)
        
        for log in logs:
            # Check 1: Horizontal Distance
            dist = haversine_distance(log['lat'], log['lon'], target['lat'], target['lon'])
            
            # Check 2: Vertical Distance (Height from sea level)
            # If your GPS doesn't support altitude well, this might be strict.
            # We check if student altitude is within target +/- tolerance
            student_alt = log.get('alt', 0.0)
            alt_diff = abs(student_alt - target['alt'])
            
            if dist <= target['radius_meters'] and alt_diff <= target['height_tolerance']:
                inside_count += 1
        
        percentage = (inside_count / total_count) * 100
        is_present = percentage >= 70
        
        print(f"Student stats: {inside_count}/{total_count} valid pings ({percentage:.1f}%)")
        
        return jsonify({
            "message": "Logs synced to DB", 
            "attendance_percentage": percentage,
            "marked_present": is_present
        })
        
    return jsonify({"message": "Class not found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
