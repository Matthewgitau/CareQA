-- Create shift_rotas table
CREATE TABLE IF NOT EXISTS shift_rotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_user_id UUID REFERENCES service_users(id) ON DELETE CASCADE,
    carer_id UUID REFERENCES carers(id) ON DELETE CASCADE,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    shift_type VARCHAR(50) NOT NULL CHECK (shift_type IN ('Morning', 'Lunch', 'Tea', 'Evening')),
    day_of_week VARCHAR(20) NOT NULL CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
    week_range VARCHAR(50) NOT NULL,
    notes TEXT DEFAULT '',
    is_recurring BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    status VARCHAR(20) DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'Swapped')),
    created_by_carer_id UUID REFERENCES carers(id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_shift_rotas_service_user ON shift_rotas (service_user_id);
CREATE INDEX IF NOT EXISTS idx_shift_rotas_carer ON shift_rotas (carer_id);
CREATE INDEX IF NOT EXISTS idx_shift_rotas_week_range ON shift_rotas (week_range);
CREATE INDEX IF NOT EXISTS idx_shift_rotas_date_range ON shift_rotas (start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_shift_rotas_status ON shift_rotas (status);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_shift_rota_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_shift_rota_updated_at ON shift_rotas;
CREATE TRIGGER update_shift_rota_updated_at
    BEFORE UPDATE ON shift_rotas
    FOR EACH ROW
    EXECUTE FUNCTION update_shift_rota_updated_at();

-- Enable Row Level Security
ALTER TABLE shift_rotas ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shift_rotas
-- Admins can view all shift rotas
DROP POLICY IF EXISTS "Admins can view all shift rotas" ON shift_rotas;
CREATE POLICY "Admins can view all shift rotas" ON shift_rotas
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Admins can insert shift rotas
DROP POLICY IF EXISTS "Admins can insert shift rotas" ON shift_rotas;
CREATE POLICY "Admins can insert shift rotas" ON shift_rotas
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Admins can update shift rotas
DROP POLICY IF EXISTS "Admins can update shift rotas" ON shift_rotas;
CREATE POLICY "Admins can update shift rotas" ON shift_rotas
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Admins can delete shift rotas
DROP POLICY IF EXISTS "Admins can delete shift rotas" ON shift_rotas;
CREATE POLICY "Admins can delete shift rotas" ON shift_rotas
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Carers can view their own shift rotas
DROP POLICY IF EXISTS "Carers can view their own shift rotas" ON shift_rotas;
CREATE POLICY "Carers can view their own shift rotas" ON shift_rotas
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'carer'
            AND profiles.id = shift_rotas.carer_id
        )
    );

-- Carers can update their own shift rotas (for status changes)
DROP POLICY IF EXISTS "Carers can update their own shift rotas" ON shift_rotas;
CREATE POLICY "Carers can update their own shift rotas" ON shift_rotas
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'carer'
            AND profiles.id = shift_rotas.carer_id
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'carer'
            AND profiles.id = shift_rotas.carer_id
        )
    );

-- Function to check for shift conflicts
CREATE OR REPLACE FUNCTION check_shift_conflicts(
    p_carer_id UUID,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_exclude_shift_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conflict_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO conflict_count
    FROM shift_rotas
    WHERE carer_id = p_carer_id
    AND status = 'Scheduled'
    AND start_date < p_end_date
    AND end_date > p_start_date
    AND (p_exclude_shift_id IS NULL OR id != p_exclude_shift_id);

    RETURN conflict_count > 0;
END;
$$;

-- Function to get available carers for a time slot
CREATE OR REPLACE FUNCTION get_available_carers(
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_required_qualifications TEXT[] DEFAULT '{}'
)
RETURNS TABLE (
    carer_id UUID,
    name TEXT,
    qualifications TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.qualifications
    FROM carers c
    WHERE NOT EXISTS (
        SELECT 1 FROM shift_rotas s
        WHERE s.carer_id = c.id
        AND s.status = 'Scheduled'
        AND s.start_date < p_end_date
        AND s.end_date > p_start_date
    )
    AND (
        array_length(p_required_qualifications, 1) IS NULL
        OR c.qualifications && p_required_qualifications
    );
END;
$$;

-- Function to get week range from date
CREATE OR REPLACE FUNCTION get_week_range(p_date DATE)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    start_of_week DATE;
    end_of_week DATE;
BEGIN
    start_of_week := p_date - EXTRACT(DOW FROM p_date)::INTEGER + 1;
    end_of_week := start_of_week + 6;
    
    RETURN 'w/c ' || EXTRACT(DAY FROM start_of_week)::TEXT || ' ' || 
           TO_CHAR(start_of_week, 'Mon YYYY');
END;
$$;

-- Function to create recurring shifts
CREATE OR REPLACE FUNCTION create_recurring_shifts(
    p_service_user_id UUID,
    p_carer_id UUID,
    p_start_date TIMESTAMP WITH TIME ZONE,
    p_end_date TIMESTAMP WITH TIME ZONE,
    p_shift_type VARCHAR(50),
    p_day_of_week VARCHAR(20),
    p_notes TEXT,
    p_weeks INTEGER,
    p_created_by UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    i INTEGER;
    shift_date TIMESTAMP WITH TIME ZONE;
    new_shift_id UUID;
    week_range TEXT;
BEGIN
    FOR i IN 0..(p_weeks - 1) LOOP
        shift_date := p_start_date + (i * 7 || ' days')::INTERVAL;
        week_range := get_week_range(shift_date::DATE);
        
        INSERT INTO shift_rotas (
            service_user_id,
            carer_id,
            start_date,
            end_date,
            shift_type,
            day_of_week,
            week_range,
            notes,
            is_recurring,
            created_by,
            status
        ) VALUES (
            p_service_user_id,
            p_carer_id,
            shift_date,
            p_end_date + (i * 7 || ' days')::INTERVAL,
            p_shift_type,
            p_day_of_week,
            week_range,
            p_notes,
            true,
            p_created_by,
            'Scheduled'
        ) RETURNING id INTO new_shift_id;
    END LOOP;
    
    RETURN p_weeks;
END;
$$;

-- Function to optimize routes for a carer
CREATE OR REPLACE FUNCTION optimize_carer_routes(
    p_carer_id UUID,
    p_date DATE
)
RETURNS TABLE (
    shift_id UUID,
    service_user_id UUID,
    service_user_name TEXT,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    address TEXT,
    optimized_order INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    week_range TEXT;
BEGIN
    week_range := get_week_range(p_date);
    
    RETURN QUERY
    SELECT 
        s.id,
        s.service_user_id,
        su.name,
        s.start_date,
        s.end_date,
        su.address,
        ROW_NUMBER() OVER (ORDER BY s.start_date) as optimized_order
    FROM shift_rotas s
    JOIN service_users su ON s.service_user_id = su.id
    WHERE s.carer_id = p_carer_id
    AND s.week_range = week_range
    AND s.status = 'Scheduled'
    ORDER BY s.start_date;
END;
$$;

-- Insert sample data for testing
INSERT INTO shift_rotas (
    service_user_id,
    carer_id,
    start_date,
    end_date,
    shift_type,
    day_of_week,
    week_range,
    notes,
    is_recurring,
    created_by,
    status
) VALUES 
(
    (SELECT id FROM service_users LIMIT 1),
    (SELECT id FROM carers LIMIT 1),
    NOW() + INTERVAL '1 day 09:00:00',
    NOW() + INTERVAL '1 day 13:00:00',
    'Morning',
    'Monday',
    get_week_range((NOW() + INTERVAL '1 day')::DATE),
    'Regular morning care',
    false,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    'Scheduled'
),
(
    (SELECT id FROM service_users LIMIT 1),
    (SELECT id FROM carers LIMIT 1),
    NOW() + INTERVAL '1 day 14:00:00',
    NOW() + INTERVAL '1 day 18:00:00',
    'Tea',
    'Monday',
    get_week_range((NOW() + INTERVAL '1 day')::DATE),
    'Afternoon care',
    false,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    'Scheduled'
),
(
    (SELECT id FROM service_users OFFSET 1 LIMIT 1),
    (SELECT id FROM carers OFFSET 1 LIMIT 1),
    NOW() + INTERVAL '2 days 09:00:00',
    NOW() + INTERVAL '2 days 13:00:00',
    'Morning',
    'Tuesday',
    get_week_range((NOW() + INTERVAL '2 days')::DATE),
    'Weekly morning visit',
    true,
    (SELECT id FROM profiles WHERE role = 'admin' LIMIT 1),
    'Scheduled'
)
ON CONFLICT DO NOTHING;