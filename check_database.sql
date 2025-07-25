-- Check what hairstyle records currently exist in the database
SELECT 
    id,
    name,
    description,
    image_url,
    styling_time_minutes,
    difficulty_level,
    hair_type,
    face_shape,
    hair_length,
    created_at
FROM hairstyles 
ORDER BY created_at DESC; 