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
            # Handle uploaded file
            uploaded_file = request.files["file"]
            if uploaded_file:
                # Read the uploaded CSV file
                df = pd.read_csv(uploaded_file)

                # Validate the required columns
                if "ds" not in df.columns or "y" not in df.columns:
                    error_message = "The uploaded CSV must contain 'ds' (date) and 'y' (value) columns."
                else:
                    # Get the number of forecast days from the form
                    forecast_days = int(request.form.get("forecast_days", 30))

                    # Fit the Prophet model
                    model = Prophet()
                    model.fit(df)

                    # Create a future dataframe and make predictions
                    future = model.make_future_dataframe(periods=forecast_days)
                    forecast = model.predict(future)

                    # Extract relevant results for display
                    forecast_results = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].to_dict(orient="records")

        except Exception as e:
            # Handle any exceptions
            error_message = f"An error occurred: {str(e)}"

    # Render the HTML template with the results
    return render_template("index.html", forecast=forecast_results, error=error_message)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
