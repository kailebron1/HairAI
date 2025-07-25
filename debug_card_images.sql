-- Debug script to check both card and gallery images

-- 1. Check the main hairstyles table (this is what shows in the cards)
SELECT 
    id,
    name,
    description,
    image_url as card_image_url,
    styling_time_minutes,
    difficulty_level,
    hair_type,
    face_shape,
    hair_length,
    created_at
FROM hairstyles 
ORDER BY created_at DESC;

-- 2. Check what's currently in hairstyle_images table (gallery images)
SELECT 
    hi.id,
    hi.hairstyle_id,
    h.name as hairstyle_name,
    hi.image_url as gallery_image_url,
    hi.view_type,
    hi.skin_tone,
    hi.display_order,
    hi.created_at
FROM hairstyle_images hi
LEFT JOIN hairstyles h ON hi.hairstyle_id = h.id
ORDER BY hi.hairstyle_id, hi.display_order;

-- 3. Count images per hairstyle
SELECT 
    h.id,
    h.name,
    h.image_url as main_card_image,
    COUNT(hi.id) as gallery_image_count
FROM hairstyles h
LEFT JOIN hairstyle_images hi ON h.id = hi.hairstyle_id
GROUP BY h.id, h.name, h.image_url
ORDER BY h.created_at DESC; 