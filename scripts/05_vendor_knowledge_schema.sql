-- Vendor Knowledge Base Schema
-- Centralized vendor information, contracts, communications

-- Vendor Profiles (extended)
CREATE TABLE IF NOT EXISTS vendor_profile (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT NOT NULL,
  vendor_name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(20),
  website VARCHAR(255),
  address TEXT,
  city VARCHAR(100),
  country VARCHAR(100),
  payment_terms VARCHAR(100),
  tax_id VARCHAR(50),
  status VARCHAR(50) DEFAULT 'active', -- active, inactive, blocked
  total_spent DECIMAL(12, 2) DEFAULT 0,
  average_lead_time_days INT DEFAULT 0,
  rating DECIMAL(3, 1),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Vendor Documents
CREATE TABLE IF NOT EXISTS vendor_document (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT NOT NULL REFERENCES vendor_profile(id) ON DELETE CASCADE,
  document_type VARCHAR(100), -- contract, certification, insurance, tax_form, agreement
  document_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500),
  file_size BIGINT,
  expiry_date DATE,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Vendor Communications
CREATE TABLE IF NOT EXISTS vendor_communication (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT NOT NULL REFERENCES vendor_profile(id) ON DELETE CASCADE,
  communication_type VARCHAR(50), -- email, call, meeting, message
  subject VARCHAR(255),
  content TEXT,
  communication_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Vendor Contacts
CREATE TABLE IF NOT EXISTS vendor_contact (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT NOT NULL REFERENCES vendor_profile(id) ON DELETE CASCADE,
  contact_name VARCHAR(255) NOT NULL,
  contact_title VARCHAR(100),
  email VARCHAR(255),
  phone VARCHAR(20),
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vendor_profile_status ON vendor_profile(status);
CREATE INDEX idx_vendor_document_vendor ON vendor_document(vendor_id);
CREATE INDEX idx_vendor_document_type ON vendor_document(document_type);
CREATE INDEX idx_vendor_communication_vendor ON vendor_communication(vendor_id);
CREATE INDEX idx_vendor_contact_vendor ON vendor_contact(vendor_id);
