from flask import Flask, request, render_template, jsonify
from prophet import Prophet
from prophet.models import StanBackendEnum
import pandas as pd
import os

# Initialize Flask app
app = Flask(__name__, template_folder='templates')
app.config['UPLOAD_FOLDER'] = './data'

# Log function for standardized messages
def log_message(message, level="INFO"):
    levels = {
        "INFO": "[INFO]",
        "ERROR": "[ERROR]",
        "DEBUG": "[DEBUG]",
    }
    print(f"{levels.get(level, '[INFO]')} {message}")

# Initialize and configure Prophet model
def initialize_prophet_model():
    try:
        log_message("Initializing Prophet model with cmdstanpy backend...")
        model = Prophet()
        model.stan_backend = StanBackendEnum.CMDSTANPY
        log_message("Prophet model initialized successfully.")
        return model
    except Exception as e:
        log_message(f"Error initializing Prophet model: {e}", "ERROR")
        raise e

# Flask route: Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

# Flask route: Home page with form
@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        try:
            # Handle file upload
            uploaded_file = request.files['file']
            if uploaded_file.filename == '':
                return render_template('index.html', error="No file selected.")

            # Save file to upload folder
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], uploaded_file.filename)
            uploaded_file.save(file_path)

            # Read uploaded CSV
            data = pd.read_csv(file_path)
            if 'ds' not in data.columns or 'y' not in data.columns:
                return render_template('index.html', error="Invalid CSV format. Columns 'ds' and 'y' are required.")

            # Parse forecast days
            forecast_days = int(request.form['forecast_days'])

            # Initialize and fit Prophet model
            model = initialize_prophet_model()
            model.fit(data)

            # Generate forecast
            future = model.make_future_dataframe(periods=forecast_days)
            forecast = model.predict(future)

            # Prepare forecast for rendering
            forecast_results = forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].to_dict(orient='records')

            # Render template with forecast results
            return render_template('index.html', forecast=forecast_results)

        except Exception as e:
            log_message(f"Error processing request: {e}", "ERROR")
            return render_template('index.html', error=str(e))
    return render_template('index.html')

# Entry point for the application
if __name__ == '__main__':
    if not os.path.exists(app.config['UPLOAD_FOLDER']):
        os.makedirs(app.config['UPLOAD_FOLDER'])
    log_message("Starting the application...")
    app.run(host='0.0.0.0', port=5001)
