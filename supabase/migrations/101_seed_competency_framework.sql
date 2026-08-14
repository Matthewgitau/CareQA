-- ============================================
-- SEED COMPETENCY FRAMEWORK - PHASE 2
-- CQC-Aligned Competency Data
-- ============================================

-- Seed competencies aligned with CQC requirements
INSERT INTO competency_framework (competency_code, competency_name, category, description, required_level, assessment_method, evidence_requirements, regulatory_reference) VALUES
('CLIN-001', 'Medication Administration', 'clinical', 
 'Safe administration of medications including the 6 rights, MAR chart completion, and medication error reporting.', 4,
 '{"observation", "test"}', 
 '{"MAR chart completion", "Witnessed administration", "Medication safety test"}', 
 'CQC Regulation 13'),

('CLIN-002', 'Catheter Care', 'clinical',
 'Safe catheter management, infection prevention, and patient comfort.', 3,
 '{"observation"}',
 '{"Witnessed procedure", "Catheter care checklist"}',
 'CQC Regulation 12'),

('CLIN-003', 'Wound Care and Pressure Ulcer Prevention', 'clinical',
 'Assessment, prevention, and management of pressure ulcers. Waterlow scoring.', 3,
 '{"observation", "portfolio"}',
 '{"Waterlow score completion", "Wound assessment documentation"}',
 'CQC Regulation 12'),

('CLIN-004', 'Diabetes Management', 'clinical',
 'Blood glucose monitoring, insulin administration, and hypoglycaemia management.', 3,
 '{"observation", "test"}',
 '{"Blood glucose reading", "Insulin administration witnessed"}',
 'CQC Regulation 13'),

('CLIN-005', 'Epilepsy and Seizure Management', 'clinical',
 'Seizure recognition, emergency response, and post-seizure care.', 3,
 '{"observation"}',
 '{"Seizure response witnessed"}',
 'CQC Regulation 12'),

('CLIN-006', 'Mental Capacity Assessment', 'clinical',
 'Conducting mental capacity assessments under the Mental Capacity Act 2005.', 4,
 '{"observation", "portfolio"}',
 '{"MCA assessment documentation"}',
 'Mental Capacity Act 2005'),

('CLIN-007', 'DoLS and Safeguarding', 'clinical',
 'Understanding Deprivation of Liberty Safeguards and safeguarding reporting.', 4,
 '{"observation", "test"}',
 '{"Safeguarding referral documentation"}',
 'CQC Regulation 13'),

('CLIN-008', 'End of Life Care', 'clinical',
 'Providing compassionate end of life care, including pain management and family support.', 3,
 '{"observation"}',
 '{"Care plan review"}',
 'CQC Regulation 9'),

('CLIN-009', 'Infection Prevention and Control', 'clinical',
 'Hand hygiene, PPE use, waste management, and outbreak protocols.', 4,
 '{"observation"}',
 '{"Hand hygiene audit", "PPE competency check"}',
 'CQC Regulation 12'),

('CLIN-010', 'Nutrition and Hydration', 'clinical',
 'Assessing nutritional needs, MUST score, and supporting eating and drinking.', 3,
 '{"observation"}',
 '{"MUST score calculation"}',
 'CQC Regulation 14'),

('COMM-001', 'Person-Centred Communication', 'communication',
 'Effective communication with service users, families, and colleagues.', 4,
 '{"observation"}',
 '{"Service user feedback"}',
 'CQC Regulation 9'),

('COMM-002', 'Dementia Communication', 'communication',
 'Communication strategies for service users living with dementia.', 3,
 '{"observation"}',
 '{"Dementia care plan review"}',
 'CQC Regulation 9'),

('COMM-003', 'Conflict Resolution', 'communication',
 'Managing difficult conversations, complaints, and conflict situations.', 3,
 '{"observation"}',
 '{"Complaint handling documentation"}',
 'CQC Regulation 16'),

('COMM-004', 'Cultural and Religious Sensitivity', 'communication',
 'Understanding and respecting diverse cultural, religious, and spiritual needs.', 3,
 '{"observation"}',
 '{"Care plan evidence"}',
 'Equality Act 2010'),

('SAFE-001', 'Manual Handling', 'safety',
 'Safe moving and handling techniques for staff and service users.', 4,
 '{"observation"}',
 '{"Moving and handling assessment"}',
 'Manual Handling Operations Regulations'),

('SAFE-002', 'Fire Safety', 'safety',
 'Fire prevention, evacuation procedures, and use of fire equipment.', 4,
 '{"observation", "test"}',
 '{"Fire drill participation"}',
 'Regulatory Reform (Fire Safety) Order 2005'),

('SAFE-003', 'Health and Safety', 'safety',
 'Health and safety at work, risk assessments, and COSHH.', 3,
 '{"observation"}',
 '{"Risk assessment completion"}',
 'Health and Safety at Work Act'),

('SAFE-004', 'Lone Working', 'safety',
 'Safe lone working practices and emergency procedures.', 3,
 '{"observation"}',
 '{"Lone working policy acknowledgment"}',
 'Health and Safety at Work Act'),

('SAFE-005', 'First Aid', 'safety',
 'Emergency first aid, CPR, and AED use.', 3,
 '{"observation"}',
 '{"First aid certificate"}',
 'Health and Safety (First Aid) Regulations'),

('PROF-001', 'Dignity and Respect', 'professional',
 'Maintaining dignity, privacy, and respect for all service users.', 4,
 '{"observation"}',
 '{"Dignity audit"}',
 'CQC Regulation 10'),

('PROF-002', 'Duty of Candour', 'professional',
 'Open and transparent communication with service users and families.', 3,
 '{"observation"}',
 '{"Duty of candour documentation"}',
 'CQC Regulation 20'),

('PROF-003', 'Data Protection and GDPR', 'professional',
 'Handling personal data in compliance with GDPR and UK data protection law.', 3,
 '{"test"}',
 '{"GDPR training certificate"}',
 'UK GDPR'),

('PROF-004', 'Whistleblowing and Speaking Up', 'professional',
 'Understanding and using whistleblowing procedures to raise concerns.', 3,
 '{"observation"}',
 '{"Whistleblowing policy acknowledgment"}',
 'Public Interest Disclosure Act'),

('PROF-005', 'Equality, Diversity and Inclusion', 'professional',
 'Understanding and promoting equality, diversity, and inclusion.', 3,
 '{"observation"}',
 '{"EDI training certificate"}',
 'Equality Act 2010'),

('MGT-001', 'Supervision and Appraisal', 'management',
 'Conducting effective supervision and appraisal sessions.', 4,
 '{"observation", "portfolio"}',
 '{"Supervision records"}',
 'CQC Regulation 18'),

('MGT-002', 'Rota and Resource Management', 'management',
 'Managing staff rotas and resources efficiently.', 3,
 '{"observation"}',
 '{"Rota completion"}',
 'CQC Regulation 18'),

('MGT-003', 'Incident and Complaint Management', 'management',
 'Managing and investigating incidents and complaints.', 4,
 '{"observation", "portfolio"}',
 '{"Incident investigation records"}',
 'CQC Regulation 16'),

('DIG-001', 'Digital Care Records', 'digital',
 'Using digital care records and ensuring data quality.', 3,
 '{"observation"}',
 '{"Digital record completion"}',
 'CQC Regulation 17'),

('DIG-002', 'Video Consultation and Telecare', 'digital',
 'Conducting video consultations and using telecare equipment.', 2,
 '{"observation"}',
 '{"Video consultation record"}',
 'CQC Regulation 9');

-- Seed role requirements
INSERT INTO role_competency_requirements (role_type, competency_id, required_level, is_mandatory)
SELECT 'care_worker', id, required_level, true
FROM competency_framework
WHERE category IN ('clinical', 'communication', 'safety', 'professional')
AND competency_code NOT LIKE '%supervision%' 
AND competency_code NOT LIKE '%rota%'
AND competency_code NOT LIKE '%appraisal%'
AND competency_code NOT LIKE '%incident%'
AND competency_code NOT LIKE '%digital%';

-- Add manager-specific competencies
INSERT INTO role_competency_requirements (role_type, competency_id, required_level, is_mandatory)
SELECT 'manager', id, required_level, true
FROM competency_framework
WHERE category IN ('management', 'professional')
AND competency_code IN ('MGT-001', 'MGT-002', 'MGT-003');

-- Add nurse-specific competencies
INSERT INTO role_competency_requirements (role_type, competency_id, required_level, is_mandatory)
SELECT 'nurse', id, required_level, true
FROM competency_framework
WHERE category IN ('clinical')
AND competency_code IN ('CLIN-001', 'CLIN-002', 'CLIN-003', 'CLIN-004', 'CLIN-005', 'CLIN-006', 'CLIN-007', 'CLIN-008', 'CLIN-009', 'CLIN-010');