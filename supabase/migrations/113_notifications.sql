-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Recipient
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Notification Details
  type TEXT CHECK (type IN (
    'shift_assigned',
    'shift_cancelled',
    'shift_swap_request',
    'shift_swap_approved',
    'time_off_approved',
    'time_off_rejected',
    'document_expiring',
    'document_expired',
    'training_due',
    'training_overdue',
    'competency_expiring',
    'incident_reported',
    'safeguarding_alert',
    'complaint_raised',
    'action_plan_assigned',
    'action_plan_overdue',
    'invoice_generated',
    'payment_received',
    'message_received',
    'announcement',
    'system_alert',
    'other'
  )),
  
  -- Content
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  
  -- Priority
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('urgent', 'high', 'normal', 'low')),
  
  -- Status
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  delivered BOOLEAN DEFAULT FALSE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  
  -- Actions
  action_required BOOLEAN DEFAULT FALSE,
  action_url TEXT,
  action_label TEXT,
  
  -- Expiry
  expires_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policy
CREATE POLICY tenant_isolation_notifications ON notifications
  FOR ALL USING (organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid()));

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created ON notifications(created_at);
CREATE INDEX idx_notifications_priority ON notifications(priority);

-- Auto-delete old notifications (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications 
  WHERE created_at < NOW() - INTERVAL '90 days' 
  AND read = true;
END;
$$ LANGUAGE plpgsql;