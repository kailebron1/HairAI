-- Test the exact same query that Flutter app is running
-- This should help us find the discrepancy

-- Query 1: What Flutter tries first (with skin tone filter)
SELECT * FROM hairstyle_images 
WHERE hairstyle_id = 7 AND skin_tone = 'light'
ORDER BY display_order ASC;

-- Query 2: What Flutter tries as fallback (no skin tone filter)  
SELECT * FROM hairstyle_images 
WHERE hairstyle_id = 7
ORDER BY display_order ASC;

-- Query 3: Check what skin_tone values actually exist
SELECT DISTINCT skin_tone FROM hairstyle_images WHERE hairstyle_id = 7;

-- Query 4: Check data types and exact values
SELECT 
  id,
  hairstyle_id,
  skin_tone,
  view_type,
  display_order,
  LENGTH(skin_tone) as skin_tone_length,
  ASCII(SUBSTRING(skin_tone, 1, 1)) as first_char_ascii
FROM hairstyle_images 
WHERE hairstyle_id = 7; 