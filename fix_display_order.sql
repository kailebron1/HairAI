-- Fix duplicate display_order values
-- Each image should have a unique display_order

-- First, let's see the current state
SELECT id, view_type, skin_tone, display_order FROM hairstyle_images 
WHERE hairstyle_id = 7 ORDER BY id;

-- Update display_order to be unique sequential values
-- This will set them to 1, 2, 3, 4, 5, 6 based on their ID order

UPDATE hairstyle_images 
SET display_order = (
  SELECT row_number 
  FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) as row_number
    FROM hairstyle_images 
    WHERE hairstyle_id = 7
  ) ranked 
  WHERE ranked.id = hairstyle_images.id
)
WHERE hairstyle_id = 7;

-- Verify the fix
SELECT id, view_type, skin_tone, display_order FROM hairstyle_images 
WHERE hairstyle_id = 7 ORDER BY display_order; 