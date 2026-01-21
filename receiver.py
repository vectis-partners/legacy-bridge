from flask import Flask, request, jsonify
import csv
import io

app = Flask(__name__)
API_KEY = "VECTIS_SECURE_TOKEN"

def sanitize_legacy_csv(binary_data):
    """
    The Washing Machine.
    Takes raw bytes (Win-1252), fixes the encoding, strips bad chars.
    """
    try:
        # 1. Decode the "Zombie" encoding
        text_content = binary_data.decode('cp1252', errors='ignore')
        
        # 2. Parse the CSV
        f = io.StringIO(text_content)
        reader = csv.DictReader(f)
        
        clean_records = []
        for row in reader:
            # Logic: If it has a Name, it's a person. Ignore footer stats.
            if row.get('ClientName'):
                clean_records.append({
                    "name": row['ClientName'].strip(),
                    "id": row.get('ID', 'N/A'),
                    "status": "Ready for Import"
                })
        return clean_records
    except Exception as e:
        return {"error": str(e)}

@app.route('/exfil', methods=['POST'])
def receive_data():
    """The C2 Endpoint."""
    token = request.headers.get('X-Auth')
    if token != API_KEY:
        return jsonify({"status": "forbidden"}), 403
        
    uploaded_file = request.files.get('file')
    if not uploaded_file:
        return jsonify({"status": "no file"}), 400
        
    print(f"[+] Received exfil package: {uploaded_file.filename}")
    
    # Process the dirty data immediately
    raw_bytes = uploaded_file.read()
    clean_json = sanitize_legacy_csv(raw_bytes)
    
    print("[*] Sanitized Data Output:")
    print(clean_json) # In real life, this goes to the Database
    
    return jsonify({"status": "received", "processed_count": len(clean_records)}), 200

if __name__ == "__main__":
    print("[*] C2 Receiver listening on port 5000...")
    app.run(port=5000)