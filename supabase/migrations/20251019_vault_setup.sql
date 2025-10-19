-- Supabase Vault Setup for AI Agent Secret Management
-- Enables secure secret storage accessible by Edge Functions and AI agents

-- Enable vault extension if not already enabled
CREATE EXTENSION IF NOT EXISTS vault WITH SCHEMA vault;

-- Create secrets table if it doesn't exist (should be auto-created by extension)
-- vault.secrets is managed by Supabase

-- Create helper functions for AI agents to access secrets

-- Function: Get secret by name (restricted to service_role)
CREATE OR REPLACE FUNCTION public.get_secret(secret_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  secret_value TEXT;
BEGIN
  -- Only allow service_role to access secrets
  IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied: Only service_role can access secrets';
  END IF;

  -- Get secret from vault
  SELECT decrypted_secret INTO secret_value
  FROM vault.decrypted_secrets
  WHERE name = secret_name;

  IF secret_value IS NULL THEN
    RAISE EXCEPTION 'Secret not found: %', secret_name;
  END IF;

  RETURN secret_value;
END;
$$;

-- Function: List available secret names (for debugging, service_role only)
CREATE OR REPLACE FUNCTION public.list_secret_names()
RETURNS TABLE(secret_name TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only allow service_role to list secrets
  IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied: Only service_role can list secrets';
  END IF;

  RETURN QUERY
  SELECT name, vault.secrets.created_at
  FROM vault.secrets
  ORDER BY vault.secrets.created_at DESC;
END;
$$;

-- Function: Store secret (service_role only)
CREATE OR REPLACE FUNCTION public.store_secret(
  secret_name TEXT,
  secret_value TEXT,
  secret_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  secret_id UUID;
BEGIN
  -- Only allow service_role to store secrets
  IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied: Only service_role can store secrets';
  END IF;

  -- Insert secret into vault
  INSERT INTO vault.secrets (name, secret, description)
  VALUES (secret_name, secret_value, secret_description)
  RETURNING id INTO secret_id;

  RETURN secret_id;
END;
$$;

-- Function: Rotate secret (service_role only)
CREATE OR REPLACE FUNCTION public.rotate_secret(
  secret_name TEXT,
  new_secret_value TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only allow service_role to rotate secrets
  IF current_setting('request.jwt.claims', true)::json->>'role' != 'service_role' THEN
    RAISE EXCEPTION 'Access denied: Only service_role can rotate secrets';
  END IF;

  -- Update secret in vault
  UPDATE vault.secrets
  SET secret = new_secret_value,
      updated_at = NOW()
  WHERE name = secret_name;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Secret not found: %', secret_name;
  END IF;

  RETURN TRUE;
END;
$$;

-- Create audit log table for secret access
CREATE TABLE IF NOT EXISTS public.secret_access_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  secret_name TEXT NOT NULL,
  accessed_by TEXT NOT NULL,
  access_type TEXT NOT NULL CHECK (access_type IN ('read', 'write', 'rotate', 'delete')),
  success BOOLEAN NOT NULL DEFAULT TRUE,
  error_message TEXT,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_secret_access_log_created_at ON public.secret_access_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_secret_access_log_secret_name ON public.secret_access_log(secret_name);

-- Enable RLS on audit log
ALTER TABLE public.secret_access_log ENABLE ROW LEVEL SECURITY;

-- Policy: Only service_role can access audit logs
CREATE POLICY "service_role_access_audit_log" ON public.secret_access_log
  FOR ALL
  TO service_role
  USING (TRUE)
  WITH CHECK (TRUE);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA vault TO service_role;
GRANT SELECT ON vault.secrets TO service_role;
GRANT SELECT ON vault.decrypted_secrets TO service_role;
GRANT ALL ON public.secret_access_log TO service_role;

-- Comments for documentation
COMMENT ON FUNCTION public.get_secret IS 'Retrieve decrypted secret value by name (service_role only)';
COMMENT ON FUNCTION public.list_secret_names IS 'List all available secret names (service_role only)';
COMMENT ON FUNCTION public.store_secret IS 'Store a new encrypted secret in Vault (service_role only)';
COMMENT ON FUNCTION public.rotate_secret IS 'Update an existing secret with new value (service_role only)';
COMMENT ON TABLE public.secret_access_log IS 'Audit log for secret access operations';
