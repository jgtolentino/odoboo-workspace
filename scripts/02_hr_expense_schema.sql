-- HR Expense Documents Schema
-- Expense tracking with Concur integration

-- Vendor Rate Cards
CREATE TABLE IF NOT EXISTS vendor_rate_card (
  id BIGSERIAL PRIMARY KEY,
  vendor_id BIGINT NOT NULL,
  vendor_name VARCHAR(255),
  effective_from DATE NOT NULL,
  effective_to DATE,
  role VARCHAR(100),
  region VARCHAR(100),
  unit VARCHAR(50),
  rate DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  version INT DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Concur Mappings
CREATE TABLE IF NOT EXISTS concur_mapping (
  id BIGSERIAL PRIMARY KEY,
  mapping_type VARCHAR(100) NOT NULL, -- expense_type, cost_center, gl_account, tax_code, project, vendor
  odoo_id VARCHAR(255) NOT NULL,
  odoo_name VARCHAR(255),
  concur_id VARCHAR(255) NOT NULL,
  concur_name VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(mapping_type, odoo_id, concur_id)
);

-- HR Expenses (extended with Concur fields)
CREATE TABLE IF NOT EXISTS hr_expense (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  employee_id BIGINT NOT NULL,
  employee_name VARCHAR(255),
  expense_date DATE NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  category VARCHAR(100),
  description TEXT,
  status VARCHAR(50) DEFAULT 'draft', -- draft, submitted, approved, rejected, exported
  
  -- Concur fields
  concur_expense_id VARCHAR(255),
  concur_status VARCHAR(50),
  fx_rate DECIMAL(12, 6),
  fx_rate_locked BOOLEAN DEFAULT FALSE,
  tax_amount DECIMAL(12, 2),
  net_amount DECIMAL(12, 2),
  gross_amount DECIMAL(12, 2),
  tax_code VARCHAR(50),
  
  -- Accounting fields
  gl_account_id BIGINT,
  cost_center_id BIGINT,
  project_id BIGINT,
  
  -- Export tracking
  export_queue_id BIGINT,
  export_status VARCHAR(50),
  export_error TEXT,
  idempotency_key VARCHAR(255) UNIQUE,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id),
  updated_by UUID REFERENCES auth.users(id)
);

-- Expense Attachments
CREATE TABLE IF NOT EXISTS expense_attachment (
  id BIGSERIAL PRIMARY KEY,
  expense_id BIGINT NOT NULL REFERENCES hr_expense(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500),
  file_size BIGINT,
  mime_type VARCHAR(100),
  ocr_text TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Export Queue (for batch Concur export)
CREATE TABLE IF NOT EXISTS export_queue (
  id BIGSERIAL PRIMARY KEY,
  batch_id VARCHAR(255) UNIQUE,
  status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
  total_records INT DEFAULT 0,
  processed_records INT DEFAULT 0,
  failed_records INT DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMP
);

-- Export Queue Items
CREATE TABLE IF NOT EXISTS export_queue_item (
  id BIGSERIAL PRIMARY KEY,
  queue_id BIGINT NOT NULL REFERENCES export_queue(id) ON DELETE CASCADE,
  expense_id BIGINT NOT NULL REFERENCES hr_expense(id),
  status VARCHAR(50) DEFAULT 'pending',
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hr_expense_employee ON hr_expense(employee_id);
CREATE INDEX idx_hr_expense_status ON hr_expense(status);
CREATE INDEX idx_hr_expense_concur_id ON hr_expense(concur_expense_id);
CREATE INDEX idx_vendor_rate_card_vendor ON vendor_rate_card(vendor_id);
CREATE INDEX idx_concur_mapping_type ON concur_mapping(mapping_type);
CREATE INDEX idx_export_queue_status ON export_queue(status);
