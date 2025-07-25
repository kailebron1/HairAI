-- Create hairstyle_images table for multiple images per hairstyle
CREATE TABLE hairstyle_images (
    id SERIAL PRIMARY KEY,
    hairstyle_id INTEGER REFERENCES hairstyles(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    view_type TEXT NOT NULL, -- 'front', 'side', 'back', etc.
    skin_tone TEXT NOT NULL, -- 'light', 'tan', 'medium', 'dark', etc.
    display_order INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better query performance
CREATE INDEX idx_hairstyle_images_hairstyle_id ON hairstyle_images(hairstyle_id);
CREATE INDEX idx_hairstyle_images_skin_tone ON hairstyle_images(skin_tone);
CREATE INDEX idx_hairstyle_images_view_type ON hairstyle_images(view_type); 