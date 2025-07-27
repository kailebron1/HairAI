import os
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from pydantic import BaseModel, Field, ValidationError
from typing import List, Literal, Dict, Any, Optional
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


# --- Helper Functions ---
def parse_json_field(value: Any) -> list:
    """Safely parse a string field that could be a JSON list or a comma-separated string."""
    if isinstance(value, list):
        return value
    if not isinstance(value, str):
        return []
    try:
        # It might be a proper JSON array string, e.g., '["oval", "square"]'
        return json.loads(value)
    except json.JSONDecodeError:
        # It might be a comma-separated string, e.g., 'fine, medium, coarse'
        return [item.strip() for item in value.split(',') if item.strip()]


# --- Pydantic Models for Strict Data Validation ---
class ImageAnalysisRequest(BaseModel):
    image_url: str

class ImageAnalysisResult(BaseModel):
    face_shape: Literal["oval", "round", "square", "heart", "diamond"]
    skin_tone: Literal["light", "olive", "dark", "asian"]
    hair_color: Literal["blonde", "brown", "black", "grey", "red"]
    hair_length: Literal["short", "medium", "long"]
    assumed_race: Literal["asian", "black", "caucasian", "hispanic", "other"]
    raw_analysis_data: Dict[str, Any]

class QuizData(BaseModel):
    hairTexture: str
    hairPorosity: str
    timeAvailable: float
    style: str
    hairGoals: str
    featuresHighlight: str

class RecommendationRequest(BaseModel):
    analysis_result: ImageAnalysisResult
    quiz_data: Dict[str, Any]

class Hairstyle(BaseModel):
    id: int
    name: str
    description: str
    face_shape: List[str]
    skin_tones: List[str]
    hair_texture: List[str]
    hair_length: str
    tags: List[str]
    image_gallery: List[Dict[str, Any]] = []
    tags: Optional[List[str]] = None


# --- FastAPI Application ---
app = FastAPI(
    title="HairStyle AI Service",
    description="Provides AI-powered face analysis and hairstyle recommendations.",
)

# --- CORS Middleware ---
# This allows the Flutter app (or any other web client) to make requests
# to this backend server, which is hosted on a different domain.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
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
  "hair_length": "one of 'short', 'medium', 'long'",
  "assumed_race": "one of 'asian', 'black', 'caucasian', 'hispanic', 'other'"
}
- Analyze the most prominent person in the image.
- If an attribute is unclear, make your best professional assessment.
- Do not include any additional text, explanations, or apologies in your response. Only the JSON object.
"""

RECOMMENDATION_PROMPT_TEMPLATE = """
You are an expert AI stylist. Your task is to provide personalized hairstyle recommendations based on a user's facial analysis and personal preferences from a quiz.

**INPUTS:**
1. **User Data:**
- Image Analysis: {analysis_result}
- Quiz Responses: {quiz_data}
2. **Available Hairstyles:**
- A JSON list of hairstyle objects: {hairstyles}

**TASK:**
1. Analyze the user data.
2. Compare the user data to the attributes of each hairstyle in the provided list.
3. Select the top 5 best-fitting hairstyles for the user, ranked from best to worst.
4. For each of the 5 selected hairstyles, write a personalized and uplifting explanation for why it's a good choice.
5. Format your entire response as a single JSON object.

**OUTPUT FORMAT RULES (FOLLOW EXACTLY):**
- The entire output must be a single JSON object.
- The JSON object must have one key: "recommendations".
- The value of "recommendations" must be a JSON array.
- The JSON array must contain exactly 5 elements.
- Each element in the array must be a JSON object with two keys:
1. "id": The integer ID of the hairstyle.
2. "explanation": A string containing your personalized explanation.

**EXAMPLE OF THE REQUIRED OUTPUT FORMAT:**
```json
{
"recommendations": [
{
"id": 12,
"explanation": "This style is a great choice because it complements your face shape and matches your preference for a professional look."
},
{
"id": 5,
"explanation": "The texture of this cut will work well with your hair type, and it's a stylish option that highlights your features."
},
// ... 3 more objects
]
}
```

Now, generate the response based on the provided inputs and the strict output format rules. Do not include any other text, notes, or apologies in your response. Only the JSON object is allowed.
"""


# --- API Endpoints ---
@app.post("/analyze", response_model=ImageAnalysisResult)
async def analyze_image(request: ImageAnalysisRequest):
    """
    Analyzes an image from a URL to determine facial attributes using OpenAI.
    """
    image_url = request.image_url
    if not image_url:
        raise HTTPException(status_code=400, detail="image_url is required")

    print(f"DEBUG: Received image URL for analysis: {image_url}")

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
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

        if not response.choices or not response.choices[0].message:
            print(f"ERROR: OpenAI response is missing expected structure. Full response: {response.model_dump_json(indent=2)}")
            raise HTTPException(status_code=500, detail="OpenAI returned an invalid response structure.")

        raw_json = response.choices[0].message.content
        if not raw_json:
            finish_reason = response.choices[0].finish_reason
            print(f"ERROR: OpenAI returned an empty message. Finish reason: '{finish_reason}'. Full response: {response.model_dump_json(indent=2)}")
            if finish_reason == 'content_filter':
                raise HTTPException(status_code=400, detail="The provided image was flagged by our safety system and could not be processed.")
            raise HTTPException(status_code=500, detail=f"OpenAI returned an empty response. Finish reason: {finish_reason}")
        
        analysis_content = raw_json
        if not analysis_content:
            raise HTTPException(status_code=500, detail="OpenAI returned empty content.")

        analysis_data = json.loads(analysis_content)

        # Validate the data with Pydantic, while also injecting the raw data
        validated_data = ImageAnalysisResult(
            face_shape=analysis_data.get("face_shape"),
            skin_tone=analysis_data.get("skin_tone"),
            hair_color=analysis_data.get("hair_color"),
            hair_length=analysis_data.get("hair_length"),
            assumed_race=analysis_data.get("assumed_race"),
            raw_analysis_data=analysis_data
        )
        return validated_data
    except json.JSONDecodeError:
        print(f"ERROR: Failed to decode JSON from OpenAI: {analysis_content}")
        raise HTTPException(status_code=500, detail=f"Failed to decode JSON from OpenAI: {analysis_content}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")


class RecommendationResponse(BaseModel):
    id: int
    explanation: str

@app.post("/recommend", response_model=List[RecommendationResponse])
async def get_recommendations(request: RecommendationRequest):
    """
    Accepts user analysis and quiz data, fetches and filters hairstyles,
    and uses OpenAI to rank them, returning an ordered list of hairstyle IDs with explanations.
    """
    try:
        # 1. Fetch all hairstyles from Supabase
        response = supabase.from_("hairstyles").select("*").execute()
        hairstyles_data = response.data
        if not hairstyles_data:
            raise HTTPException(status_code=404, detail="No hairstyles found in the database.")

        # 2. Pre-process data and filter based on skin tone
        user_skin_tone = request.analysis_result.skin_tone
        processed_hairstyles = []
        for h in hairstyles_data:
            h_copy = h.copy()
            # Parse string fields into lists
            h_copy['face_shape'] = parse_json_field(h.get('face_shape'))
            h_copy['skin_tones'] = parse_json_field(h.get('skin_tones'))
            h_copy['hair_texture'] = parse_json_field(h.get('hair_texture'))
            h_copy['tags'] = parse_json_field(h.get('tags'))

            # Filter hairstyles to only include those compatible with the user's skin tone
            if user_skin_tone in h_copy['skin_tones']:
                processed_hairstyles.append(h_copy)

        # If no hairstyles match the skin tone, we can't proceed.
        if not processed_hairstyles:
             raise HTTPException(status_code=404, detail=f"No hairstyles found matching the skin tone: {user_skin_tone}")

        # 3. Convert to list of Pydantic models for structured data and validation
        hairstyles = [Hairstyle(**h) for h in processed_hairstyles]

        # 4. Prepare data for OpenAI prompt
        # Convert Pydantic models to a list of dictionaries for JSON serialization
        hairstyles_json = [h.model_dump() for h in hairstyles]
        hairstyles_json_str = json.dumps(hairstyles_json, indent=2)

        # 5. Create the prompt for OpenAI
        prompt = RECOMMENDATION_PROMPT_TEMPLATE.format(
            analysis_result=request.analysis_result.dict(),
            quiz_data=request.quiz_data,
            hairstyles=hairstyles_json_str
        )

        # 6. Call the AI model for recommendations
        completion = openai_client.chat.completions.create(
            model="gpt-4o-mini", 
            messages=[
                {"role": "system", "content": "You are an expert AI stylist."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"},
        )
        
        raw_response = completion.choices[0].message.content or ""
        if not raw_response:
            raise HTTPException(status_code=500, detail="AI recommendation model returned an empty response.")

        # Clean up the response: remove leading/trailing whitespace and optional ```json fencing
        clean_response = raw_response.strip()
        if clean_response.startswith("```"):
            # remove the first ``` line and the last ``` if present
            clean_response = clean_response.lstrip("` ").lstrip("json").strip()
            if clean_response.endswith("```"):
                clean_response = clean_response[: -3].strip()

        # The prompt asks for a JSON object with a 'recommendations' key.
        try:
            response_data = json.loads(clean_response)
            
            # Defensive check: ensure response_data is a dictionary
            if not isinstance(response_data, dict):
                raise ValueError(f"AI response was not a JSON object (dictionary). Got: {type(response_data)}")

            # Find the key that matches "recommendations" ignoring whitespace/case
            recommendations = None
            for key, value in response_data.items():
                if key.strip().lower() == "recommendations":
                    recommendations = value
                    break

            if recommendations is None or not isinstance(recommendations, list):
                raise ValueError("AI response did not contain a valid 'recommendations' list.")

            # Validate each item in the list with the Pydantic model
            validated_recommendations = [RecommendationResponse(**item) for item in recommendations]
            return validated_recommendations

        except (json.JSONDecodeError, ValidationError, ValueError) as e:
            # Log the problematic response for debugging
            print(f"ERROR: Failed to parse or validate AI response. Error: {e}")
            print(f"ERROR: Raw AI response was: {raw_response}")
            raise HTTPException(status_code=500, detail=f"Failed to process AI recommendation response: {e}")

    except Exception as e:
        # Log unexpected errors for debugging
        print(f"FATAL: An unexpected error occurred in /recommend: {e}")
        raise HTTPException(status_code=500, detail=f"An unexpected server error occurred: {e}")


@app.get("/")
def read_root():
    return {"message": "Server is running"}