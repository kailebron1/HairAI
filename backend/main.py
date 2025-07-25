import os
import json
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field, ValidationError
from typing import Literal

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

# --- Configuration ---
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY environment variable not set")

client = OpenAI(api_key=OPENAI_API_KEY)

# --- Pydantic Models for Strict Data Validation ---
class AnalysisResult(BaseModel):
    face_shape: Literal["oval", "round", "square", "heart", "diamond"]
    skin_tone: Literal["light", "olive", "dark", "asian"]
    hair_color: Literal["blonde", "brown", "black", "grey", "red"]
    hair_length: Literal["short", "medium", "long"]

class ImageAnalysisRequest(BaseModel):
    image_url: str = Field(..., description="Publicly accessible URL of the image to analyze")

# --- FastAPI Application ---
app = FastAPI(
    title="HairStyle AI Face Analysis Service",
    description="Analyzes a user's photo to determine facial attributes for hairstyle recommendations.",
)

# --- System Prompt for OpenAI ---
SYSTEM_PROMPT = """
You are an expert AI assistant specializing in analyzing human faces from images for hairstyle recommendations.
Your task is to analyze the user-provided image and determine the following attributes: face shape, skin tone, hair color, and hair length.

You MUST respond with a valid JSON object that strictly adheres to the following structure and available options:
{
  "face_shape": "one of 'oval', 'round', 'square', 'heart', 'diamond'",
  "skin_tone": "one of 'light', 'olive', 'dark', 'asian'",
  "hair_color": "one of 'blonde', 'brown', 'black', 'grey', 'red'",
  "hair_length": "one of 'short', 'medium', 'long'"
}

- Analyze the most prominent person in the image.
- If an attribute is unclear, make your best professional assessment.
- Do not include any additional text, explanations, or apologies in your response. Only the JSON object.
"""

@app.post("/analyze", response_model=AnalysisResult)
async def analyze_image(request: ImageAnalysisRequest):
    """
    Accepts an image URL, analyzes it with OpenAI's vision model,
    and returns a structured JSON object with facial attributes.
    """
    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "system",
                    "content": SYSTEM_PROMPT,
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Please analyze the person in this image."},
                        {
                            "type": "image_url",
                            "image_url": {"url": request.image_url},
                        },
                    ],
                },
            ],
            max_tokens=300,
            response_format={"type": "json_object"},
        )

        # Extract and parse the JSON response from OpenAI
        raw_json = response.choices[0].message.content
        if not raw_json:
            raise HTTPException(status_code=500, detail="OpenAI returned an empty response.")

        analysis_data = json.loads(raw_json)

        # Validate the data against our Pydantic model
        validated_data = AnalysisResult(**analysis_data)
        return validated_data

    except ValidationError as e:
        raise HTTPException(
            status_code=500,
            detail=f"OpenAI response did not match expected format: {e}",
        )
    except Exception as e:
        # Catch-all for other potential errors (e.g., OpenAI API down)
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Face Analysis Service is running."}