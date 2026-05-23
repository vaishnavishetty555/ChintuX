-- Supabase Database Schema for Pawly App - With Anonymous Access

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables

-- Pets table
CREATE TABLE pets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    species_raw TEXT NOT NULL,
    breed TEXT DEFAULT '',
    date_of_birth TIMESTAMP WITH TIME ZONE,
    weight_kg DOUBLE PRECISION,
    sex_raw TEXT DEFAULT 'unknown',
    neutered BOOLEAN DEFAULT FALSE,
    allergies_text TEXT DEFAULT '',
    ongoing_conditions_text TEXT DEFAULT '',
    accent_hex TEXT DEFAULT '#2D5F4E',
    photo_url TEXT,
    status_raw TEXT DEFAULT 'active',
    marked_passed_at TIMESTAMP WITH TIME ZONE,
    marked_lost_at TIMESTAMP WITH TIME ZONE,
    vet_name TEXT DEFAULT '',
    vet_phone TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reminders table
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type_raw TEXT NOT NULL,
    dosage TEXT,
    recurrence_raw TEXT NOT NULL,
    first_due_at TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT DEFAULT '',
    prescription_photo_url TEXT,
    quiet_start_hour INTEGER DEFAULT -1,
    quiet_end_hour INTEGER DEFAULT -1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reminder instances table
CREATE TABLE reminder_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reminder_id UUID REFERENCES reminders(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status_raw TEXT DEFAULT 'upcoming',
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Log entries table
CREATE TABLE log_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
    kind_raw TEXT NOT NULL,
    detail TEXT DEFAULT '',
    numeric_value DOUBLE PRECISION,
    at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mood entries table
CREATE TABLE mood_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
    mood_raw TEXT NOT NULL,
    note TEXT DEFAULT '',
    at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pet documents table
CREATE TABLE pet_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    document_type_raw TEXT NOT NULL,
    file_url TEXT NOT NULL,
    expiry_date TIMESTAMP WITH TIME ZONE,
    is_encrypted BOOLEAN DEFAULT FALSE,
    ocr_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminder_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_documents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies that allow anonymous access (for development/testing)
-- In production, you should require authentication

-- Pets policies - Allow anonymous access
CREATE POLICY "Allow anonymous select on pets" ON pets
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on pets" ON pets
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on pets" ON pets
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on pets" ON pets
    FOR DELETE USING (true);

-- Reminders policies - Allow anonymous access
CREATE POLICY "Allow anonymous select on reminders" ON reminders
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on reminders" ON reminders
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on reminders" ON reminders
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on reminders" ON reminders
    FOR DELETE USING (true);

-- Reminder instances policies - Allow anonymous access
CREATE POLICY "Allow anonymous select on reminder_instances" ON reminder_instances
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on reminder_instances" ON reminder_instances
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on reminder_instances" ON reminder_instances
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on reminder_instances" ON reminder_instances
    FOR DELETE USING (true);

-- Log entries policies - Allow anonymous access
CREATE POLICY "Allow anonymous select on log_entries" ON log_entries
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on log_entries" ON log_entries
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on log_entries" ON log_entries
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on log_entries" ON log_entries
    FOR DELETE USING (true);

-- Mood entries policies - Allow anonymous access
CREATE POLICY "Allow anonymous select on mood_entries" ON mood_entries
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on mood_entries" ON mood_entries
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on mood_entries" ON mood_entries
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on mood_entries" ON mood_entries
    FOR DELETE USING (true);

-- Pet documents policies - Allow anonymous access
CREATE POLICY "Allow anonymous select on pet_documents" ON pet_documents
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert on pet_documents" ON pet_documents
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update on pet_documents" ON pet_documents
    FOR UPDATE USING (true);

CREATE POLICY "Allow anonymous delete on pet_documents" ON pet_documents
    FOR DELETE USING (true);

-- Create storage bucket for pet files
INSERT INTO storage.buckets (id, name, public) 
VALUES ('pet-files', 'pet-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies - Allow anonymous access
CREATE POLICY "Allow anonymous upload" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'pet-files');

CREATE POLICY "Allow anonymous view" ON storage.objects
    FOR SELECT USING (bucket_id = 'pet-files');

CREATE POLICY "Allow anonymous delete" ON storage.objects
    FOR DELETE USING (bucket_id = 'pet-files');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_pets_updated_at BEFORE UPDATE ON pets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
