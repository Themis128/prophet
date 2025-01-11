#!/bin/bash

ROOT_DIR="/home/tbaltzakis/prophet-main/prophet-main"
APP_DIR="$ROOT_DIR/app"
TEMPLATES_DIR="$APP_DIR/templates"
DATA_DIR="$ROOT_DIR/data"
NOTEBOOKS_DIR="$ROOT_DIR/notebooks"

echo "Starting to rearrange the file structure under $ROOT_DIR..."

# Create the necessary directories
echo "Creating new directories..."
mkdir -p "$APP_DIR" "$TEMPLATES_DIR" "$DATA_DIR" "$NOTEBOOKS_DIR"

# Create app.py if not found
if [ ! -f "$APP_DIR/app.py" ]; then
    echo "Creating a new app.py for Flask..."
    cat <<EOF > "$APP_DIR/app.py"
from flask import Flask, render_template, request
from prophet import Prophet
import pandas as pd

app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def index():
    forecast_results = None
    error_message = None

    if request.method == "POST":
        try:
            uploaded_file = request.files["file"]
            if uploaded_file:
                df = pd.read_csv(uploaded_file)
                if "ds" not in df.columns or "y" not in df.columns:
                    error_message = "The CSV must contain 'ds' (date) and 'y' (value) columns."
                else:
                    forecast_days = int(request.form.get("forecast_days", 30))
                    model = Prophet()
                    model.fit(df)
                    future = model.make_future_dataframe(periods=forecast_days)
                    forecast = model.predict(future)
                    forecast_results = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].to_dict(orient="records")
        except Exception as e:
            error_message = str(e)

    return render_template("index.html", forecast=forecast_results, error=error_message)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
else
    echo "app.py already exists, skipping creation."
fi

# Create index.html if not found
if [ ! -f "$TEMPLATES_DIR/index.html" ]; then
    echo "Creating a new index.html for Flask..."
    cat <<EOF > "$TEMPLATES_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Prophet Forecasting</title>
</head>
<body>
    <h1>Prophet Time-Series Forecasting</h1>
    <form method="POST" enctype="multipart/form-data">
        <label for="file">Upload CSV File:</label>
        <input type="file" name="file" required>
        <br>
        <label for="forecast_days">Number of Days to Forecast:</label>
        <input type="number" name="forecast_days" value="30" min="1" required>
        <br>
        <button type="submit">Generate Forecast</button>
    </form>

    {% if error %}
        <p style="color: red;">{{ error }}</p>
    {% endif %}

    {% if forecast %}
        <h2>Forecast Results</h2>
        <table border="1">
            <tr>
                <th>Date</th>
                <th>Forecast</th>
                <th>Lower Bound</th>
                <th>Upper Bound</th>
            </tr>
            {% for row in forecast %}
                <tr>
                    <td>{{ row.ds }}</td>
                    <td>{{ row.yhat }}</td>
                    <td>{{ row.yhat_lower }}</td>
                    <td>{{ row.yhat_upper }}</td>
                </tr>
            {% endfor %}
        </table>
    {% endif %}
</body>
</html>
EOF
else
    echo "index.html already exists, skipping creation."
fi

# Copy a sample CSV from examples to data directory
SAMPLE_CSV=$(find "$ROOT_DIR/examples" -name "*.csv" | head -n 1)
if [ -n "$SAMPLE_CSV" ]; then
    echo "Copying sample CSV from $SAMPLE_CSV to $DATA_DIR/sample_input.csv..."
    cp "$SAMPLE_CSV" "$DATA_DIR/sample_input.csv"
else
    echo "No sample CSV found in $ROOT_DIR/examples."
fi

echo "File structure rearrangement complete!"
