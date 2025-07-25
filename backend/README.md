# Backend - OpenAI Face Analysis Service

This directory contains a self-contained Python FastAPI application that uses OpenAI's GPT-4o model to analyze a user's photo and extract facial attributes.

## Features

- **Single Endpoint (`/analyze`):** Accepts a public image URL (from Supabase Storage) and returns a structured JSON object with facial analysis.
- **Attribute Extraction:** Identifies face shape, skin tone, hair color, and hair length based on a carefully engineered prompt.
- **Data Validation:** Ensures the output strictly adheres to the predefined categories your Flutter app expects.

## How to Run Locally

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Set up a virtual environment and install dependencies:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

3.  **Set your OpenAI API Key:**
    ```bash
    export OPENAI_API_KEY='your_openai_api_key'
    ```

4.  **Run the FastAPI server:**
    ```bash
    uvicorn main:app --reload
    ```

## How to Deploy

This service is containerized with Docker, making it easy to deploy to any modern hosting platform.

**Recommended Host: Render.com**

1.  **Push to GitHub:** Ensure the `backend` directory and its contents are committed to your GitHub repository.
2.  **Create a New Web Service on Render:**
    -   Connect your GitHub account.
    -   Select your repository.
    -   Choose "Docker" as the environment.
3.  **Configure Environment Variables:**
    -   Add a secret file or environment variable named `OPENAI_API_KEY` and set its value to your OpenAI API key.
4.  **Deploy:** Click "Create Web Service". Render will build and deploy the container.

## API Usage

-   **Endpoint:** `/analyze`
-   **Method:** `POST`
-   **Body (JSON):**
    ```json
    {
      "image_url": "https://your-supabase-bucket/public/path/to/image.jpg"
    }
    ```
-   **Successful Response (200 OK):**
    ```json
    {
      "face_shape": "oval",
      "skin_tone": "light",
      "hair_color": "brown",
      "hair_length": "short"
    }
    ``` 