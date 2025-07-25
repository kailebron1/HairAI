-- Check if gallery images were added
-- Run this to see what's in the hairstyle_images table

SELECT * FROM hairstyle_images;

-- Check specifically for hairstyle ID 7 (Buzz Cut)
SELECT * FROM hairstyle_images WHERE hairstyle_id = 7;

-- Count total images
SELECT COUNT(*) as total_gallery_images FROM hairstyle_images; 