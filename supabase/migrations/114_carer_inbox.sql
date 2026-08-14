-- Create messages table
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Sender & Recipient
  sender_id UUID REFERENCES profiles(id),
  sender_name TEXT,
  sender_role TEXT CHECK (sender_role IN ('admin', 'manager', 'carer', 'client', 'family', 'system')),
  recipient_id UUID REFERENCES profiles(id),
  recipient_name TEXT,
  recipient_role TEXT CHECK (recipient_role IN ('admin', 'manager', 'carer', 'client', 'family', 'system')),
  
  -- Message Content
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  
  -- Message Type
  message_type TEXT CHECK (message_type IN (
    'direct',
    'broadcast',
    'shift_notification',
    'policy_update',
    'training_reminder',
    'emergency',
    'whistleblower',
    'anonymous'
  )),
  is_anonymous BOOLEAN DEFAULT FALSE,
  anonymous_id TEXT,
  
  -- Priority
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent', 'emergency')),
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  is_replied BOOLEAN DEFAULT FALSE,
  replied_at TIMESTAMP WITH TIME ZONE,
  
  -- Parent/Thread
  parent_message_id UUID REFERENCES messages(id),
  thread_id UUID,
  is_thread_start BOOLEAN DEFAULT TRUE,
  
  -- Attachments
  attachments JSONB DEFAULT '[]',
  
  -- Action Required
  action_required BOOLEAN DEFAULT FALSE,
  action_deadline DATE,
  action_completed BOOLEAN DEFAULT FALSE,
  action_notes TEXT,
  
  -- Metadata
  metadata JSONB,
  
  -- Soft Delete
  deleted_by UUID REFERENCES profiles(id),
  deleted_at TIMESTAMP WITH TIME ZONE,
  deleted_for_all BOOLEAN DEFAULT FALSE,
  
  -- Audit
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  organisation_id UUID REFERENCES organisations(id)
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY tenant_isolation_messages ON messages
  FOR ALL USING (
    organisation_id = (SELECT organisation_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY users_can_read_their_messages ON messages
  FOR SELECT USING (
    recipient_id = auth.uid() 
    OR sender_id = auth.uid()
    OR sender_role IN ('admin', 'manager')
  );

CREATE POLICY users_can_insert_their_messages ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() 
    OR sender_role = 'system'
    OR is_anonymous = true
  );

CREATE POLICY users_can_update_their_messages ON messages
  FOR UPDATE USING (
    recipient_id = auth.uid() 
    OR sender_id = auth.uid()
  );

-- Indexes
CREATE INDEX idx_messages_recipient ON messages(recipient_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_read ON messages(is_read);
CREATE INDEX idx_messages_priority ON messages(priority);
CREATE INDEX idx_messages_thread ON messages(thread_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- Function to get unread count
CREATE OR REPLACE FUNCTION get_unread_count(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM messages
    WHERE recipient_id = user_id
    AND is_read = false
    AND deleted_at IS NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark as read
CREATE OR REPLACE FUNCTION mark_messages_read(message_ids UUID[])
RETURNS VOID AS $$
BEGIN
  UPDATE messages
  SET is_read = true,
      read_at = NOW()
  WHERE id = ANY(message_ids)
  AND recipient_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;