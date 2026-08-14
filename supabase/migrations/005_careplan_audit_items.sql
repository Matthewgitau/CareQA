-- Create careplan_audit_items table (72 documents)
CREATE TABLE careplan_audit_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  document_name TEXT NOT NULL,
  category TEXT,
  display_order INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert 72 documents from careplan_audit.html
INSERT INTO careplan_audit_items (document_name, display_order, category) VALUES
('consent', 1, 'Legal'),
('personal contacts and emergency information', 2, 'Personal'),
('grabsheet', 3, 'Operational'),
('RESPECT form', 4, 'Clinical'),
('about me', 5, 'Personal'),
('preadmission forms', 6, 'Admission'),
('relationship circle', 7, 'Social'),
('likes and dislikes', 8, 'Personal'),
('Aims visions and goals', 9, 'Care Planning'),
('Routines and support 1-page profile', 10, 'Care Planning'),
('my routines and how I like to be supported', 11, 'Care Planning'),
('Support plans and risk assessments', 12, 'Risk'),
('Communication care/support plan', 13, 'Communication'),
('communication passport/SALT guidance', 14, 'Communication'),
('Communication risk assessment', 15, 'Risk'),
('General health and well-being including medical history', 16, 'Health'),
('risk assessment-health issues', 17, 'Risk'),
('mental state/cognition decision making', 18, 'Mental Health'),
('information on DoLS best interest decisions and capacity assessments', 19, 'Legal'),
('psychological care/support plan', 20, 'Mental Health'),
('risk assessment cognition', 21, 'Risk'),
('personal hygiene care/support plan', 22, 'Personal Care'),
('risk assessment-personal hygiene', 23, 'Risk'),
('continence - including stoma care/support/aids/pad details/catheters', 24, 'Continence'),
('risk assessment- continence', 25, 'Risk'),
('mobility - including aids and environment', 26, 'Mobility'),
('risk assessments - mobility moving and handling', 27, 'Risk'),
('falls risk assessment', 28, 'Risk'),
('behaviour - positive behaviour support', 29, 'Behaviour'),
('specialist support plans eg outreach', 30, 'Specialist'),
('risk assessment - behaviour', 31, 'Risk'),
('nutrition', 32, 'Nutrition'),
('nutritional screening tool risk assessment', 33, 'Risk'),
('medication', 34, 'Medication'),
('medication profile - if no HAP', 35, 'Medication'),
('PRN protocols may be kept with the MAR charts', 36, 'Medication'),
('risk assessments- medication', 37, 'Risk'),
('skin care/integrity - including body maps pressure care/support management', 38, 'Skin'),
('waterlow risk assessment', 39, 'Risk'),
('finance', 40, 'Finance'),
('finance risk assessment', 41, 'Risk'),
('documentation on power of attorney etc', 42, 'Legal'),
('cultural/lifestyle needs - spirituality/sexuality relationships', 43, 'Cultural'),
('education/community involvement and activity', 44, 'Social'),
('personal safety', 45, 'Safety'),
('risk assessment - day activities', 46, 'Risk'),
('home environment - domestic activities risk assessment', 47, 'Risk'),
('positive risk taking', 48, 'Risk'),
('progression-goals and outcomes', 49, 'Care Planning'),
('sleeping and night plan relaxation', 50, 'Sleep'),
('risk assessments - night care/support', 51, 'Risk'),
('fire evacuation PEEP', 52, 'Safety'),
('pain management', 53, 'Clinical'),
('end of life care/support plan/wishes', 54, 'End of Life'),
('health action plans see separate audit', 55, 'Health'),
('specific care/support plans and risk assessments- diabetes epilepsy', 56, 'Specialist'),
('consider if seizure or breathing care/support plans need to be in place', 57, 'Specialist'),
('short term/risk assessments only when appropriate eg UTI', 58, 'Risk'),
('monitoring daily records', 59, 'Monitoring'),
('specific records of personal care/support', 60, 'Personal Care'),
('continence records - output and input charts', 61, 'Continence'),
('records where DoLS authorisations are in place', 62, 'Legal'),
('ABC charts or records of behavior', 63, 'Behaviour'),
('night checks', 64, 'Monitoring'),
('MAR charts', 65, 'Medication'),
('Topical MAR charts-body maps', 66, 'Medication'),
('weight charts', 67, 'Health'),
('food/fluid charts', 68, 'Nutrition'),
('repositioning charts', 69, 'Mobility'),
('Specialist monitoring eg epilepsy', 70, 'Specialist'),
('pressure care/support documentation including body map', 71, 'Skin'),
('evaluation of pressure ulcers/wound care/support plan/measuring/photos/record of healing', 72, 'Clinical');

-- Create careplan_audits table
CREATE TABLE careplan_audits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_user_id UUID REFERENCES service_users(id),
  auditor_id UUID REFERENCES profiles(id),
  audit_date DATE NOT NULL,
  care_plan_name TEXT NOT NULL,
  status TEXT DEFAULT 'draft',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create careplan_audit_answers table
CREATE TABLE careplan_audit_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  audit_id UUID REFERENCES careplan_audits(id) ON DELETE CASCADE,
  item_id UUID REFERENCES careplan_audit_items(id),
  present BOOLEAN DEFAULT FALSE,
  comment TEXT,
  action_needed TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_careplan_audit_items_updated_at 
    BEFORE UPDATE ON careplan_audit_items 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_careplan_audits_updated_at 
    BEFORE UPDATE ON careplan_audits 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_careplan_audit_answers_updated_at 
    BEFORE UPDATE ON careplan_audit_answers 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_careplan_audit_items_display_order ON careplan_audit_items(display_order);
CREATE INDEX idx_careplan_audit_items_category ON careplan_audit_items(category);
CREATE INDEX idx_careplan_audit_items_active ON careplan_audit_items(is_active);
CREATE INDEX idx_careplan_audits_service_user ON careplan_audits(service_user_id);
CREATE INDEX idx_careplan_audits_date ON careplan_audits(audit_date);
CREATE INDEX idx_careplan_audit_answers_audit ON careplan_audit_answers(audit_id);
CREATE INDEX idx_careplan_audit_answers_item ON careplan_audit_answers(item_id);