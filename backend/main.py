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

def _normalize_keys(obj):
    """Recursively strip leading newlines (and any surrounding whitespace) from all dict keys.
    The GPT model sometimes prefixes keys with a stray newline which survives json.loads
    and breaks downstream validation. This helper makes the structure usable without
    changing values.
    """
    if isinstance(obj, dict):
        return {k.lstrip("\n").strip(): _normalize_keys(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_normalize_keys(v) for v in obj]
    return obj


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
    Fetch hairstyles, pre-filter by skin-tone, then let GPT-4o (via function-calling) pick
    the top 5 and write uplifting explanations. Function calling guarantees valid JSON.
    """
    try:
        # 1. Fetch hairstyles
        sb_resp = supabase.from_("hairstyles").select("*").execute()
        all_styles = sb_resp.data or []
        if not all_styles:
            raise HTTPException(status_code=404, detail="No hairstyles found in database.")

        # 2. Pre-filter by user skin-tone (rule confirmed by user)
        user_skin = request.analysis_result.skin_tone
        filtered = []
        for h in all_styles:
            h_copy = h.copy()
            h_copy["skin_tones"] = parse_json_field(h.get("skin_tones"))
            h_copy["face_shape"] = parse_json_field(h.get("face_shape"))
            h_copy["hair_texture"] = parse_json_field(h.get("hair_texture"))
            h_copy["tags"] = parse_json_field(h.get("tags"))
            if user_skin in h_copy["skin_tones"]:
                filtered.append(h_copy)

        if not filtered:
            raise HTTPException(status_code=404, detail=f"No styles match skin tone '{user_skin}'.")

        # 3. Build function schema for OpenAI
        recommend_schema = {
            "name": "recommend",
            "description": "Return the top 5 hairstyle recommendations with explanations.",
            "parameters": {
                "type": "object",
                "properties": {
                    "recommendations": {
                        "type": "array",
                        "minItems": 5,
                        "maxItems": 5,
                        "items": {
                            "type": "object",
                            "properties": {
                                "id": {"type": "integer"},
                                "explanation": {"type": "string"}
                            },
                            "required": ["id", "explanation"]
                        }
                    }
                },
                "required": ["recommendations"]
            }
        }

        # 4. Craft messages – keep concise to reduce token usage
        system_msg = "You are an expert AI stylist. Use the provided function to return exactly five recommendations."
        user_payload = {
            "analysis": request.analysis_result.dict(),
            "quiz": request.quiz_data,
            "hairstyles": filtered  # send pre-filtered list
        }

        completion = openai_client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": json.dumps(user_payload)}
            ],
            functions=[recommend_schema],
            function_call={"name": "recommend"}
        )

        fc = completion.choices[0].message.function_call
        if not fc or not fc.arguments:
            raise HTTPException(status_code=500, detail="OpenAI returned no function arguments.")

        args = json.loads(fc.arguments)
        recs = args.get("recommendations", [])

        # Validate and convert to Pydantic list
        validated = [RecommendationResponse(**rec) for rec in recs]
        return validated

    except (ValidationError, ValueError, json.JSONDecodeError) as e:
        print(f"ERROR: Failed to process AI response: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process AI response: {e}")
    except Exception as e:
        print(f"FATAL: Unhandled error in /recommend: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected server error: {e}")


@app.get("/")
def read_root():
    return {"message": "Server is running"}