-- Seed training courses with the 12 standard courses (global courses with NULL organisation_id)
INSERT INTO training_courses (name, description, is_mandatory, default_renewal_interval_months, category, is_active, organisation_id) VALUES
(
  'Mental Capacity Act (MCA)',
  'Understanding the principles of the Mental Capacity Act 2005, including capacity assessments, best interests decisions, and Deprivation of Liberty Safeguards (DoLS).',
  true,
  24,
  'Legal & Compliance',
  true,
  NULL
),
(
  'Dementia Awareness',
  'Understanding different types of dementia, person-centred approaches, communication strategies, and supporting individuals living with dementia.',
  true,
  24,
  'Clinical',
  true,
  NULL
),
(
  'Safeguarding Adults',
  'Identifying and responding to abuse, neglect, and safeguarding concerns. Understanding the Care Act 2014, reporting procedures, and multi-agency working.',
  true,
  12,
  'Safeguarding',
  true,
  NULL
),
(
  'Diversity, Equality and Inclusion (DEI)',
  'Understanding equality, diversity, and inclusion principles. Recognizing and challenging discrimination. Supporting diverse needs of service users and staff.',
  true,
  24,
  'Compliance',
  true,
  NULL
),
(
  'Life Support (Basic Life Support / CPR)',
  'CPR techniques, use of AEDs, recovery position, and responding to choking incidents. Includes practical skills assessment.',
  true,
  12,
  'Emergency',
  true,
  NULL
),
(
  'Medication Administration',
  'Safe handling, administering, and recording of medications. Understanding the 6 rights, MAR charts, controlled drugs, and medication errors.',
  true,
  12,
  'Clinical',
  true,
  NULL
),
(
  'Catheter Care',
  'Safe insertion, management, and removal of urinary catheters. Infection prevention, patient comfort, and troubleshooting.',
  false,
  12,
  'Clinical',
  true,
  NULL
),
(
  'Informatics / Digital Literacy',
  'Using digital care systems, electronic care records, mobile apps, and basic IT skills. Data protection awareness.',
  false,
  24,
  'Digital',
  true,
  NULL
),
(
  'First Aid',
  'Emergency first aid, treating injuries, burns, falls, and sudden illness. Includes practical skills and assessment.',
  true,
  36,
  'Emergency',
  true,
  NULL
),
(
  'Health and Safety, Welfare (including COSHH & RIDDOR)',
  'Workplace safety, risk assessments, COSHH (hazardous substances), RIDDOR (incident reporting), fire safety, and staff welfare.',
  true,
  12,
  'Health & Safety',
  true,
  NULL
),
(
  'Medication Administration (Advanced / Refresher)',
  'Advanced medication administration, insulin administration, controlled drugs, and medication reviews.',
  false,
  24,
  'Clinical',
  true,
  NULL
),
(
  'Infection Prevention and Control',
  'Hand hygiene, PPE use, waste management, cleaning protocols, and outbreak management. Understanding infection risks and control measures.',
  true,
  12,
  'Clinical',
  true,
  NULL
);
