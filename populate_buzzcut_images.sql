-- Populate hairstyle_images table with buzz cut images
-- First, get the hairstyle_id for "Buzz Cut"
-- Replace the URLs below with your actual uploaded image URLs

-- Insert buzz cut images (replace URLs with your actual image URLs)
INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
SELECT 
    h.id,
    'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_front.png',
    'front',
    'light',
    1
FROM hairstyles h WHERE h.name = 'Buzz Cut';

INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
SELECT 
    h.id,
    'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_side.png',
    'side',
    'light',
    2
FROM hairstyles h WHERE h.name = 'Buzz Cut';

-- Add more images as needed (replace URLs with your actual uploaded image URLs)
-- INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
-- SELECT 
--     h.id,
--     'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_back.png',
--     'back',
--     'light',
--     3
-- FROM hairstyles h WHERE h.name = 'Buzz Cut';

-- Verify the data was inserted correctly
SELECT 
    hi.id,
    h.name as hairstyle_name,
    hi.image_url,
    hi.view_type,
    hi.skin_tone,
    hi.display_order
FROM hairstyle_images hi
JOIN hairstyles h ON hi.hairstyle_id = h.id
ORDER BY hi.display_order; 