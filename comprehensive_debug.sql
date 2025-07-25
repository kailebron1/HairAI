-- COMPREHENSIVE DEBUG - Let's see what's really happening

-- 1. Check if the table exists and has data
SELECT COUNT(*) as total_rows FROM hairstyle_images;

-- 2. See ALL data in the table
SELECT * FROM hairstyle_images ORDER BY id;

-- 3. Check specifically for hairstyle_id = 7
SELECT COUNT(*) as rows_for_hairstyle_7 FROM hairstyle_images WHERE hairstyle_id = 7;

-- 4. See the exact data for hairstyle_id = 7  
SELECT id, hairstyle_id, view_type, skin_tone, display_order, 
       LENGTH(view_type) as view_type_length,
       LENGTH(skin_tone) as skin_tone_length
FROM hairstyle_images 
WHERE hairstyle_id = 7 
ORDER BY id;

-- 5. Test the exact query the app uses (with skin_tone filter)
SELECT COUNT(*) as with_skin_tone_filter 
FROM hairstyle_images 
WHERE hairstyle_id = 7 AND skin_tone = 'light';

-- 6. Test the fallback query (without skin_tone filter)
SELECT COUNT(*) as without_skin_tone_filter 
FROM hairstyle_images 
WHERE hairstyle_id = 7;

-- 7. Check for any weird characters in skin_tone
SELECT DISTINCT 
  skin_tone,
  ASCII(skin_tone) as ascii_value,
  LENGTH(skin_tone) as length
FROM hairstyle_images 
WHERE hairstyle_id = 7; 