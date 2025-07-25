-- CREW CUT DATABASE SETUP - COMPLETE REPLACEMENT
-- Clean start with crew cut hairstyle

-- 1. Clear all existing data
DELETE FROM hairstyle_images;
DELETE FROM hairstyles;

-- 2. Insert crew cut hairstyle record
INSERT INTO hairstyles (id, name, description, image_url, styling_time_minutes, difficulty_level, hair_type, face_shape, hair_length)
VALUES (
  7, 
  'Crew Cut', 
  'A classic short hairstyle with slightly more length on top than a buzz cut.',
  'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/crewcut--//crewcut_light_front.png',
  5,
  'Easy',
  'All Types',
  'All Shapes', 
  'Very Short'
);

-- 3. Insert crew cut gallery images (light skin tone only for now)
INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
VALUES 
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/crewcut--//crewcut_light_front.png', 'front', 'light', 1),
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/crewcut--//crewcut_light_side.png', 'side', 'light', 2);

-- 4. Verify the setup
SELECT 'HAIRSTYLES COUNT:' as info, COUNT(*) as value FROM hairstyles
UNION ALL
SELECT 'GALLERY IMAGES COUNT:', COUNT(*) FROM hairstyle_images;

-- 5. Show the complete setup
SELECT 'MAIN HAIRSTYLE:' as type, name, image_url FROM hairstyles WHERE id = 7
UNION ALL
SELECT 'GALLERY IMAGE:', view_type, image_url FROM hairstyle_images WHERE hairstyle_id = 7 ORDER BY display_order;

-- 6. Test the exact queries your app will use
SELECT 'APP QUERY TEST - WITH SKIN TONE:' as test, COUNT(*) as count
FROM hairstyle_images WHERE hairstyle_id = 7 AND skin_tone = 'light'
UNION ALL
SELECT 'APP QUERY TEST - WITHOUT SKIN TONE:', COUNT(*)
FROM hairstyle_images WHERE hairstyle_id = 7; 