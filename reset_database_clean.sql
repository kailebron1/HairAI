-- COMPLETE DATABASE RESET - CLEAN START
-- This will give you a fresh, working setup

-- 1. Clear all existing data
DELETE FROM hairstyle_images;
DELETE FROM hairstyles;

-- 2. Insert one clean hairstyle record
INSERT INTO hairstyles (id, name, description, image_url, styling_time_minutes, difficulty_level, hair_type, face_shape, hair_length)
VALUES (
  7, 
  'Buzz Cut', 
  'A clean, short hairstyle that''s easy to maintain and looks great on most face shapes.',
  'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_front.png',
  5,
  'Easy',
  'All Types',
  'All Shapes', 
  'Very Short'
);

-- 3. Insert clean gallery images with proper sequential display_order
INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
VALUES 
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_front.png', 'front', 'light', 1),
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_side.png', 'side', 'light', 2);

-- 4. Verify everything is clean and working
SELECT 'HAIRSTYLES:' as table_name, COUNT(*) as count FROM hairstyles
UNION ALL
SELECT 'HAIRSTYLE_IMAGES:', COUNT(*) FROM hairstyle_images;

-- 5. Show the clean data
SELECT h.id, h.name, 'Main hairstyle record' as type
FROM hairstyles h
UNION ALL
SELECT hi.hairstyle_id, hi.view_type, CONCAT('Gallery image #', hi.display_order) as type
FROM hairstyle_images hi
ORDER BY id, type; 