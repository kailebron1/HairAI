-- Test if SQLTools connection is working
-- Copy and paste this and run it first

SELECT 'Connection working!' as test_message;

-- Check what tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check current hairstyles
SELECT id, name FROM hairstyles; 