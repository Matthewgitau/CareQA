-- Phase 9: Competency Notification System
-- Automates reminders for expiring competencies and pending assessments

-- Create notification table if not exists
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  notification_type TEXT,
  expiry_date DATE,
  is_read BOOLEAN DEFAULT FALSE,
  is_actioned BOOLEAN DEFAULT FALSE,
  related_entity_id UUID,
  related_entity_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add columns if they don't exist (for existing tables)
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS expiry_date DATE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS notification_type TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS is_actioned BOOLEAN DEFAULT FALSE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS related_entity_id UUID;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS related_entity_type TEXT;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_expiry ON notifications(expiry_date);

-- Trigger function for expiring competencies
CREATE OR REPLACE FUNCTION check_competency_expiry()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if competency is expiring within 30 days
  IF NEW.next_review_date IS NOT NULL AND NEW.next_review_date <= CURRENT_DATE + INTERVAL '30 days' THEN
    INSERT INTO notifications (
      user_id,
      title,
      body,
      notification_type,
      expiry_date,
      related_entity_id,
      related_entity_type
    )
    VALUES (
      NEW.staff_id,
      'Competency Expiring Soon',
      'Your competency assessment expires on ' || NEW.next_review_date::TEXT || '. Please schedule a renewal assessment.',
      'expiry_reminder',
      NEW.next_review_date,
      NEW.id,
      'competency_assessment'
    );
  END IF;

  -- Check for failed competencies (gaps)
  IF NEW.overall_rating = 'not_competent' OR (NEW.passed = FALSE AND NEW.status = 'approved') THEN
    -- Alert the staff member
    INSERT INTO notifications (
      user_id,
      title,
      body,
      notification_type,
      related_entity_id,
      related_entity_type
    )
    VALUES (
      NEW.staff_id,
      'Competency Assessment - Further Training Required',
      'Your recent competency assessment identified areas for improvement. Please review your development plan.',
      'gap_alert',
      NEW.id,
      'competency_assessment'
    );

    -- Also notify managers (via organisation admin)
    INSERT INTO notifications (
      user_id,
      title,
      body,
      notification_type,
      related_entity_id,
      related_entity_type
    )
    SELECT
      p.id,
      'Staff Competency Gap Identified',
      (SELECT full_name FROM profiles WHERE id = NEW.staff_id) || ' requires further training in competencies. Review their development plan.',
      'manager_gap_alert',
      NEW.id,
      'competency_assessment'
    FROM profiles p
    WHERE p.organisation_id = NEW.organisation_id
      AND p.role = 'manager';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for competency expiry and gaps
CREATE TRIGGER competency_expiry_trigger
  AFTER INSERT OR UPDATE ON staff_competency_assessments
  FOR EACH ROW
  EXECUTE FUNCTION check_competency_expiry();

-- Trigger function for development plan reminders
CREATE OR REPLACE FUNCTION check_development_plan_reminders()
RETURNS TRIGGER AS $$
BEGIN
  -- Notify staff when a development plan is created or updated
  IF TG_OP = 'INSERT' THEN
    INSERT INTO notifications (
      user_id,
      title,
      body,
      notification_type,
      expiry_date,
      related_entity_id,
      related_entity_type
    )
    VALUES (
      NEW.staff_id,
      'New Development Plan Assigned',
      'A new development plan has been created for you. Review your goals and target dates.',
      'development_plan_created',
      NEW.review_date,
      NEW.id,
      'development_plan'
    );
  END IF;

  -- Notify staff when a goal is approaching its target date
  IF NEW.review_date IS NOT NULL AND NEW.review_date <= CURRENT_DATE + INTERVAL '14 days' THEN
    INSERT INTO notifications (
      user_id,
      title,
      body,
      notification_type,
      expiry_date,
      related_entity_id,
      related_entity_type
    )
    VALUES (
      NEW.staff_id,
      'Development Plan Review Due',
      'Your development plan review is due soon. Please update your progress.',
      'development_plan_reminder',
      NEW.review_date,
      NEW.id,
      'development_plan'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for development plan reminders
CREATE TRIGGER development_plan_reminder_trigger
  AFTER INSERT OR UPDATE ON staff_development_plans
  FOR EACH ROW
  EXECUTE FUNCTION check_development_plan_reminders();

-- Function to clean up old notifications (run via cron or scheduled job)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS VOID AS $$
BEGIN
  DELETE FROM notifications
  WHERE is_read = TRUE
    AND created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;