-- Audio-Only Drama — Automated FX Engine
-- Database initialization script

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS audio;
CREATE SCHEMA IF NOT EXISTS fx;
CREATE SCHEMA IF NOT EXISTS jobs;

-- Set default search path
ALTER DATABASE fx SET search_path TO public, audio, fx, jobs;

-- Create basic tables for development
CREATE TABLE IF NOT EXISTS audio.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audio.audio_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES audio.projects(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    duration_seconds FLOAT,
    sample_rate INTEGER,
    channels INTEGER,
    file_size_bytes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fx.effects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    effect_type VARCHAR(100) NOT NULL,
    parameters JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS jobs.processing_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audio_file_id UUID REFERENCES audio.audio_files(id) ON DELETE CASCADE,
    job_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    parameters JSONB,
    result JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_audio_files_project_id ON audio.audio_files(project_id);
CREATE INDEX IF NOT EXISTS idx_processing_jobs_audio_file_id ON jobs.processing_jobs(audio_file_id);
CREATE INDEX IF NOT EXISTS idx_processing_jobs_status ON jobs.processing_jobs(status);
CREATE INDEX IF NOT EXISTS idx_processing_jobs_created_at ON jobs.processing_jobs(created_at);

-- Insert sample data for development
INSERT INTO audio.projects (name, description) VALUES 
    ('Sample Drama Project', 'A sample audio drama project for testing'),
    ('Test Project', 'Another test project')
ON CONFLICT DO NOTHING;

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for projects table
CREATE TRIGGER update_projects_updated_at 
    BEFORE UPDATE ON audio.projects 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
