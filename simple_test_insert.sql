-- Simple test - insert one clean record to test app connectivity
-- This will help us see if the app can read ANY gallery images

DELETE FROM hairstyle_images WHERE hairstyle_id = 7;

INSERT INTO hairstyle_images (hairstyle_id, image_url, view_type, skin_tone, display_order)
VALUES (7, 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/buzzcut_light_front.png', 'front', 'light', 1);

-- Verify it was inserted
SELECT * FROM hairstyle_images WHERE hairstyle_id = 7; 