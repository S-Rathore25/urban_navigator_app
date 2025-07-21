from flask import Flask, jsonify, request
from pymongo import MongoClient
from bson.objectid import ObjectId
from datetime import datetime

app = Flask(__name__)

MONGO_URI = "mongodb+srv://rathoresumit9514:qwertyuiop_01@cluster0.y3vuogo.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"

DB_NAME = "urban_navigator_db"

client = MongoClient(MONGO_URI)
db = client[DB_NAME]

users_collection = db.users
pois_collection = db.pois
accessibility_reports_collection = db.accessibility_reports

@app.route('/')
def home():
    return "Urban Navigator Backend is running!"

@app.route('/test_db_mongo')
def test_db_mongo_connection():
    try:
        server_info = client.server_info()
        return jsonify({"status": "success", "message": "Connected to MongoDB", "version": server_info['version']})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/search-poi', methods=['GET'])
def search_poi():
    query = request.args.get('query', '')
    if not query:
        return jsonify({"status": "error", "message": "Query parameter is required"}), 400

    search_filter = {
        "$or": [
            {"name": {"$regex": query, "$options": "i"}},
            {"address": {"$regex": query, "$options": "i"}}
        ]
    }

    if ObjectId.is_valid(query):
        search_filter["$or"].append({"_id": ObjectId(query)})
    
    results = pois_collection.find(search_filter).limit(10)

    pois_data = []
    for poi in results:
        poi['_id'] = str(poi['_id']) 
        latitude = poi.get('latitude')
        longitude = poi.get('longitude')
        
        if not isinstance(latitude, (int, float)):
            latitude = 0.0
        if not isinstance(longitude, (int, float)):
            longitude = 0.0

        pois_data.append({
            "id": poi['_id'],
            "name": poi['name'],
            "address": poi['address'],
            "latitude": latitude,
            "longitude": longitude,
            "type": poi.get('type', 'unknown'),
            "wheelchairAccessible": poi.get('wheelchair_accessible', False),
            "hasAccessibleRestroom": poi.get('has_accessible_restroom', False),
            "hasRamp": poi.get('has_ramp', False),
            "imageUrl": poi.get('imageUrl', 'https://placehold.co/100x100/E0E0E0/333333?text=POI')
        })

    return jsonify({"status": "success", "data": pois_data})

@app.route('/api/routes/find', methods=['POST'])
def find_routes():
    data = request.get_json()
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    start_lat = data['start_lat']
    start_lon = data['start_lon']
    end_lat = data['end_lat']
    end_lon = data['end_lon']
    user_profile = data['user_profile']

    mock_route_segments_accessible = [
        {"id": "seg1_1", "description": "Walk from start", "distanceKm": 0.5, "durationMinutes": 5, "accessibilityNotes": "Flat pavement", "isAccessible": True, "type": "walk"},
        {"id": "seg1_2", "description": "Take bus 101", "distanceKm": 2.0, "durationMinutes": 10, "accessibilityNotes": "Accessible bus with ramp", "isAccessible": True, "type": "bus"},
    ]
    mock_route_segments_less_accessible = [
        {"id": "seg2_1", "description": "Walk through park shortcut", "distanceKm": 0.3, "durationMinutes": 3, "accessibilityNotes": "Includes 2 flights of stairs", "isAccessible": False, "type": "walk"},
        {"id": "seg2_2", "description": "Take metro line A", "distanceKm": 4.5, "durationMinutes": 7, "accessibilityNotes": "Metro station has stairs, no elevator", "isAccessible": False, "type": "metro"},
    ]

    mock_routes = [
        {"id": "route1", "name": "Accessible Bus Route", "totalDistanceKm": 2.5, "totalDurationMinutes": 15, "segments": mock_route_segments_accessible, "isFullyAccessible": True, "accessibilitySummary": "Fully accessible."},
        {"id": "route2", "name": "Fastest (Less Accessible)", "totalDistanceKm": 4.8, "totalDurationMinutes": 10, "segments": mock_route_segments_less_accessible, "isFullyAccessible": False, "accessibilitySummary": "Faster, but includes stairs at metro station."},
    ]

    return jsonify({"status": "success", "data": mock_routes})

@app.route('/api/accessibility-reports/submit', methods=['POST'])
def submit_report():
    data = request.get_json()
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    report_type = data.get('report_type')
    description = data.get('description')
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    photo_url = data.get('photo_url') 

    if not all([report_type, latitude, longitude]):
        return jsonify({"status": "error", "message": "Missing required fields"}), 400

    try:
        report_document = {
            "report_type": report_type,
            "description": description,
            "photo_url": photo_url,
            "location": {
                "type": "Point",
                "coordinates": [longitude, latitude]
            },
            "status": "pending",
            "created_at": datetime.now()
        }
        result = accessibility_reports_collection.insert_one(report_document)
        
        return jsonify({"status": "success", "message": "Report submitted", "report_id": str(result.inserted_id)}), 201
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
