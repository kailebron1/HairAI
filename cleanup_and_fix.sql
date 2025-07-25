-- Clean up duplicate hairstyles (keep only the most recent one)
WITH duplicate_hairstyles AS (
    SELECT 
        id,
        name,
        ROW_NUMBER() OVER (PARTITION BY name ORDER BY created_at DESC) as rn
    FROM hairstyles
    WHERE name = 'Buzz Cut'
)
DELETE FROM hairstyles 
WHERE id IN (
    SELECT id FROM duplicate_hairstyles WHERE rn > 1
);

-- Clean up any orphaned hairstyle_images records
DELETE FROM hairstyle_images 
WHERE hairstyle_id NOT IN (SELECT id FROM hairstyles);

-- Update the main hairstyles table with a working image URL
UPDATE hairstyles 
SET image_url = 'https://whybphphnjchcbnuxeph.supabase.co/storage/v1/object/public/hairstyle-images/ChatGPT%20Image%20Jul%2012,%202025,%2012_06_02%20AM.png'
WHERE name = 'Buzz Cut';

-- Check final result
SELECT 
    id,
    name,
    image_url,
    created_at
FROM hairstyles 
ORDER BY created_at DESC; 