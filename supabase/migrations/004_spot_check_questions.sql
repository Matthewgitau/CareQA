-- Create spot_check_questions table
CREATE TABLE spot_check_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_text TEXT NOT NULL,
  category TEXT,
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert all 34 questions from the list
INSERT INTO spot_check_questions (question_text, display_order, category) VALUES
('does the care worker arrive at the service users home on time?', 1, 'Punctuality'),
('does the careworker have the keys/key safe number and alert the service user upon arrival?', 2, 'Access'),
('is the careworker dressed smartly in a clean company uniform?', 3, 'Appearance'),
('does the care worker introduce themselves?', 4, 'Communication'),
('does the care worker have an ID badge that is current and valid and if they are not known to the service user do they show the ID badge?', 5, 'Identification'),
('was electronic monitoring used has the care worker logged in correctly?', 6, 'Monitoring'),
('does the care worker check the service users care plan upon arrival?', 7, 'Planning'),
('does the care worker check the service users visit notes upon arrival?', 8, 'Documentation'),
('does the care worker seek the service users consent before delivering any aspect of care?', 9, 'Consent'),
('does the care worker know what care the service user needs?', 10, 'Knowledge'),
('does the care worker wash their hands before and after providing care and support?', 11, 'Hygiene'),
('does the care worker use PPE correctly?', 12, 'PPE'),
('is the care worker vigilant for hazards in the home?', 13, 'Safety'),
('is any food handled correctly and hygienically?', 14, 'Food Safety'),
('is the working area kept clean and tidy and is any PPE disposed of correctly?', 15, 'Environment'),
('Is the MAR completed correctly?', 16, 'Medication'),
('does the care worker follow the 6 rights of medication correctly?', 17, 'Medication'),
('does the care worker communicate well with the service user and evidence compassionate care?', 18, 'Communication'),
('does the service worker respect the privacy of the service user?', 19, 'Dignity'),
('does the care worker allow the service user to make their own choices?', 20, 'Autonomy'),
('does the care worker work in an enabling way?', 21, 'Enablement'),
('does the care worker accurately record on the care records the activities that have been undertaken?', 22, 'Record Keeping'),
('does the careworker log out correctly if electronic monitoring is used?', 23, 'Monitoring'),
('do you know which care worker will be coming to visit you?', 24, 'Service User Feedback'),
('does the care worker usually wear identification?', 25, 'Service User Feedback'),
('does your care worker come on time?', 26, 'Service User Feedback'),
('does the care worker respect your privacy and treat you with dignity?', 27, 'Service User Feedback'),
('does the care worker usually wear gloves and plastic aprons for personal care?', 28, 'Service User Feedback'),
('does the care worker make you feel comfortable and safe?', 29, 'Service User Feedback'),
('do you feel in control of your care service can you make your own choices?', 30, 'Service User Feedback'),
('do you know how to make a complaint?', 31, 'Service User Feedback'),
('if you have made a complaint was it resolved?', 32, 'Service User Feedback'),
('are you happy with the care you receive from xperience care ltd?', 33, 'Service User Feedback'),
('is there anything else you want to tell me about your care?', 34, 'Service User Feedback');

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_spot_check_questions_updated_at 
    BEFORE UPDATE ON spot_check_questions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_spot_check_questions_display_order ON spot_check_questions(display_order);
CREATE INDEX idx_spot_check_questions_category ON spot_check_questions(category);
CREATE INDEX idx_spot_check_questions_active ON spot_check_questions(is_active);