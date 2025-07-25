-- Check what's in the hairstyles table
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

-- Check if hairstyle_images table exists and what's in it
SELECT 
    hi.id,
    hi.hairstyle_id,
    h.name as hairstyle_name,
    hi.image_url,
    hi.view_type,
    hi.skin_tone,
    hi.display_order,
    hi.created_at
FROM hairstyle_images hi
JOIN hairstyles h ON hi.hairstyle_id = h.id
ORDER BY hi.hairstyle_id, hi.display_order;

-- Check if there are any hairstyles without corresponding images
SELECT 
    h.id,
    h.name,
    h.image_url as main_image_url,
    COUNT(hi.id) as image_count
FROM hairstyles h
LEFT JOIN hairstyle_images hi ON h.id = hi.hairstyle_id
GROUP BY h.id, h.name, h.image_url
ORDER BY h.created_at DESC; 