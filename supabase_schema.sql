-- Supabase Database Schema for Pawly App

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

-- Create RLS policies

-- Pets policies
CREATE POLICY "Users can view own pets" ON pets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pets" ON pets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own pets" ON pets
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own pets" ON pets
    FOR DELETE USING (auth.uid() = user_id);

-- Reminders policies (access through pet ownership)
CREATE POLICY "Users can view reminders for own pets" ON reminders
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = reminders.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert reminders for own pets" ON reminders
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = reminders.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update reminders for own pets" ON reminders
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = reminders.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete reminders for own pets" ON reminders
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = reminders.pet_id AND pets.user_id = auth.uid()
        )
    );

-- Reminder instances policies
CREATE POLICY "Users can view instances for own reminders" ON reminder_instances
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM reminders 
            JOIN pets ON pets.id = reminders.pet_id 
            WHERE reminders.id = reminder_instances.reminder_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert instances for own reminders" ON reminder_instances
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM reminders 
            JOIN pets ON pets.id = reminders.pet_id 
            WHERE reminders.id = reminder_instances.reminder_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update instances for own reminders" ON reminder_instances
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM reminders 
            JOIN pets ON pets.id = reminders.pet_id 
            WHERE reminders.id = reminder_instances.reminder_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete instances for own reminders" ON reminder_instances
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM reminders 
            JOIN pets ON pets.id = reminders.pet_id 
            WHERE reminders.id = reminder_instances.reminder_id AND pets.user_id = auth.uid()
        )
    );

-- Log entries policies
CREATE POLICY "Users can view log entries for own pets" ON log_entries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = log_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert log entries for own pets" ON log_entries
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = log_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update log entries for own pets" ON log_entries
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = log_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete log entries for own pets" ON log_entries
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = log_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

-- Mood entries policies
CREATE POLICY "Users can view mood entries for own pets" ON mood_entries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = mood_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert mood entries for own pets" ON mood_entries
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = mood_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update mood entries for own pets" ON mood_entries
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = mood_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete mood entries for own pets" ON mood_entries
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = mood_entries.pet_id AND pets.user_id = auth.uid()
        )
    );

-- Pet documents policies
CREATE POLICY "Users can view documents for own pets" ON pet_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = pet_documents.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert documents for own pets" ON pet_documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = pet_documents.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update documents for own pets" ON pet_documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = pet_documents.pet_id AND pets.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete documents for own pets" ON pet_documents
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM pets WHERE pets.id = pet_documents.pet_id AND pets.user_id = auth.uid()
        )
    );

-- Create storage bucket for pet files
INSERT INTO storage.buckets (id, name, public) 
VALUES ('pet-files', 'pet-files', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Users can upload files to own folder" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'pet-files' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view own files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'pet-files' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete own files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'pet-files' AND 
        (storage.foldername(name))[1] = auth.uid()::text
    );

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
