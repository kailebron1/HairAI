import os
import json
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field, ValidationError
from typing import List, Literal, Dict, Any
from supabase import create_client, Client

# --- Configuration ---
from dotenv import load_dotenv
load_dotenv()

# OpenAI Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("OPENAI_API_KEY environment variable not set")
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    raise ValueError("Supabase URL or Anon Key not set")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)


# --- Pydantic Models for Strict Data Validation ---
class ImageAnalysisResult(BaseModel):
    face_shape: Literal["oval", "round", "square", "heart", "diamond"]
    skin_tone: Literal["light", "olive", "dark", "asian"]
    hair_color: Literal["blonde", "brown", "black", "grey", "red"]
    hair_length: Literal["short", "medium", "long"]

class QuizData(BaseModel):
    hairTexture: str
    hairPorosity: str
    timeAvailable: float
    style: str
    hairGoals: str
    featuresHighlight: str

class RecommendationRequest(BaseModel):
    analysis_result: ImageAnalysisResult
    quiz_data: QuizData

class Hairstyle(BaseModel):
    id: int
    name: str
    description: str
    face_shape: List[str]
    skin_tones: List[str]
    hair_texture: List[str]
    hair_length: str
    tags: List[str]


# --- FastAPI Application ---
app = FastAPI(
    title="HairStyle AI Service",
    description="Provides AI-powered face analysis and hairstyle recommendations.",
)


# --- System Prompts for OpenAI ---
IMAGE_ANALYSIS_PROMPT = """
You are an expert AI assistant specializing in analyzing human faces from images for hairstyle recommendations.
Your task is to analyze the user-provided image and determine the following attributes.
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

RECOMMENDATION_PROMPT_TEMPLATE = """
You are an expert AI stylist. Your task is to provide personalized hairstyle recommendations based on a user's facial analysis and personal preferences from a quiz.

You will be given the user's data and a list of available hairstyles. You MUST return a JSON array of the top 5 hairstyle IDs, ranked from best to worst fit.

**User Data:**
- Image Analysis: {analysis_result}
- Quiz Responses: {quiz_data}

**Available Hairstyles (JSON format):**
{hairstyles}

Analyze the user's data and compare it against the attributes of each available hairstyle. Consider all factors, especially `skin_tone`, `face_shape`, and how the hairstyle's `tags` and `description` align with the user's `hairGoals` and `style` preferences.

Return ONLY a JSON array of the top 5 integer IDs for the best-fitting hairstyles. For example: [3, 1, 8, 5, 2]
"""


# --- API Endpoints ---
@app.post("/analyze", response_model=ImageAnalysisResult)
async def analyze_image(request: BaseModel):
    """
    Accepts an image URL, analyzes it with OpenAI's vision model,
    and returns a structured JSON object with facial attributes.
    """
    image_url = getattr(request, 'image_url', None)
    if not image_url:
        raise HTTPException(status_code=400, detail="image_url is required")
        
    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": IMAGE_ANALYSIS_PROMPT},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Please analyze the person in this image."},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ],
                },
            ],
            max_tokens=300,
            response_format={"type": "json_object"},
        )
        raw_json = response.choices[0].message.content
        if not raw_json:
            raise HTTPException(status_code=500, detail="OpenAI returned an empty response.")
        
        analysis_data = json.loads(raw_json)
        validated_data = ImageAnalysisResult(**analysis_data)
        return validated_data
    except ValidationError as e:
        raise HTTPException(status_code=500, detail=f"OpenAI response did not match expected format: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")


@app.post("/recommend", response_model=List[int])
async def get_recommendations(request: RecommendationRequest):
    """
    Accepts user analysis and quiz data, fetches all hairstyles,
    and uses an AI language model to return a ranked list of the top 5 hairstyle IDs.
    """
    try:
        # 1. Fetch all hairstyles from Supabase
        response = supabase.table('hairstyles').select('*').execute()
        hairstyles_data = response.data
        if not hairstyles_data:
            raise HTTPException(status_code=404, detail="No hairstyles found in the database.")

        # 2. Format data for the prompt
        hairstyles_json_str = json.dumps([Hairstyle(**h).dict() for h in hairstyles_data])
        
        # 3. Construct the prompt for the AI
        prompt = RECOMMENDATION_PROMPT_TEMPLATE.format(
            analysis_result=request.analysis_result.dict(),
            quiz_data=request.quiz_data.dict(),
            hairstyles=hairstyles_json_str
        )

        # 4. Call the AI model for recommendations
        completion = openai_client.chat.completions.create(
            model="gpt-3.5-turbo", # Cheaper, faster model for ranking
            messages=[
                {"role": "system", "content": "You are an expert AI stylist."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"},
        )
        
        raw_response = completion.choices[0].message.content
        if not raw_response:
            raise HTTPException(status_code=500, detail="AI recommendation model returned an empty response.")

        # The prompt asks for a JSON array, but the model might wrap it in a JSON object.
        # We need to robustly parse the returned IDs.
        try:
            # First, assume the response is a JSON object like {"ranked_ids": [1, 2, 3]}
            ranked_ids = json.loads(raw_response)
            if isinstance(ranked_ids, dict):
                # Look for any key that contains a list of integers
                for key, value in ranked_ids.items():
                    if isinstance(value, list) and all(isinstance(i, int) for i in value):
                        return value
            
            # If it's a direct list like [1, 2, 3]
            if isinstance(ranked_ids, list) and all(isinstance(i, int) for i in ranked_ids):
                return ranked_ids

            raise ValueError("No valid list of integer IDs found in the AI response.")

        except (json.JSONDecodeError, ValueError) as e:
            raise HTTPException(status_code=500, detail=f"Failed to parse AI recommendation response: {e}")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")


@app.get("/")
def read_root():
    return {"status": "ok", "message": "HairStyle AI Service is running."}