-- FIX TABLE STRUCTURE AND ADD CREW CUT DATA
-- First check what columns exist, then fix the structure

-- 1. Check current table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'hairstyle_images' 
ORDER BY column_name;

-- 2. Add missing display_order column if it doesn't exist
ALTER TABLE hairstyle_images 
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 1;

-- 3. Clear all existing data
DELETE FROM hairstyle_images;
DELETE FROM hairstyles;

-- 4. Insert crew cut hairstyle record
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

-- 5. Insert crew cut gallery images (without display_order first, then update)
INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone)
VALUES 
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/crewcut--//crewcut_light_front.png', 'front', 'light'),
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/crewcut--//crewcut_light_side.png', 'side', 'light');

-- 6. Update display_order values
UPDATE hairstyle_images SET display_order = 1 WHERE view_type = 'front' AND hairstyle_id = 7;
UPDATE hairstyle_images SET display_order = 2 WHERE view_type = 'side' AND hairstyle_id = 7;

-- 7. Verify everything worked
SELECT 'FINAL CHECK:' as info, 
       COUNT(*) as hairstyles_count
FROM hairstyles
UNION ALL
SELECT 'GALLERY IMAGES:', COUNT(*) FROM hairstyle_images;

-- 8. Show the complete setup
SELECT * FROM hairstyles WHERE id = 7;
SELECT * FROM hairstyle_images WHERE hairstyle_id = 7 ORDER BY display_order; 