-- Replace Layered Bob with Buzz Cut
-- First, delete the existing Layered Bob record
DELETE FROM hairstyles WHERE name = 'Layered Bob';

-- Insert the new Buzz Cut record with the uploaded image
INSERT INTO hairstyles (
    name, 
    description, 
    image_url, 
    styling_time_minutes, 
    difficulty_level, 
    hair_type, 
    face_shape, 
    hair_length
) VALUES (
    'Buzz Cut',
    'A classic, low-maintenance haircut that''s perfect for busy lifestyles. This ultra-short cut is timeless, versatile, and works great for all face shapes. Easy to maintain and professional-looking.',
    'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images//ChatGPT%20Image%20Jul%2012,%202025,%2012_06_02%20AM.png',
    2,
    'Easy',
    'All hair types',
    'All face shapes',
    'Very short'
); 