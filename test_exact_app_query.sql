-- Test the EXACT query your Flutter app is running
-- This is what should return your 6 images

-- Query 1: With skin_tone filter (what app tries first)
SELECT * FROM hairstyle_images 
WHERE hairstyle_id = 7 AND skin_tone = 'light'
ORDER BY display_order ASC;

-- Query 2: Without skin_tone filter (what app tries as fallback)
SELECT * FROM hairstyle_images 
WHERE hairstyle_id = 7
ORDER BY display_order ASC; 