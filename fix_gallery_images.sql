-- Fix gallery images for Buzz Cut (hairstyle_id = 7)
-- This will add the missing images so the gallery works

INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
VALUES 
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_front.png', 'front', 'light', 1),
  (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_side.png', 'side', 'light', 2);

-- Verify the images were added
SELECT * FROM hairstyle_images WHERE hairstyle_id = 7 ORDER BY display_order; 