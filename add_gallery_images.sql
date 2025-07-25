-- Add gallery images for Buzz Cut hairstyle
-- Copy and paste this entire script into SQLTools and run it

INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
VALUES 
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_front.png', 'front', 'light', 1),
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_side.png', 'side', 'light', 2);

-- Check if it worked
SELECT * FROM hairstyle_images WHERE hairstyle_id = 7; 