-- Invoice Knowledge Schema
-- Invoice management with vendor documents and knowledge links

-- Invoices (extended)
CREATE TABLE IF NOT EXISTS account_invoice (
  id BIGSERIAL PRIMARY KEY,
  invoice_number VARCHAR(50) NOT NULL UNIQUE,
  vendor_id BIGINT NOT NULL,
  vendor_name VARCHAR(255),
  invoice_date DATE NOT NULL,
  due_date DATE,
  amount DECIMAL(12, 2) NOT NULL,
  tax_amount DECIMAL(12, 2),
  total_amount DECIMAL(12, 2),
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(50) DEFAULT 'draft', -- draft, submitted, approved, paid, rejected
  payment_status VARCHAR(50) DEFAULT 'unpaid', -- unpaid, partial, paid
  payment_date DATE,
  days_overdue INT DEFAULT 0,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Invoice Line Items
CREATE TABLE IF NOT EXISTS invoice_line_item (
  id BIGSERIAL PRIMARY KEY,
  invoice_id BIGINT NOT NULL REFERENCES account_invoice(id) ON DELETE CASCADE,
  description VARCHAR(255),
  quantity DECIMAL(12, 2),
  unit_price DECIMAL(12, 2),
  line_amount DECIMAL(12, 2),
  gl_account_id BIGINT,
  tax_code VARCHAR(50),
  sequence INT DEFAULT 0
);

-- Invoice Templates
CREATE TABLE IF NOT EXISTS invoice_template (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  template_content TEXT,
  default_terms TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Invoice Attachments
CREATE TABLE IF NOT EXISTS invoice_attachment (
  id BIGSERIAL PRIMARY KEY,
  invoice_id BIGINT NOT NULL REFERENCES account_invoice(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500),
  file_size BIGINT,
  mime_type VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES auth.users(id)
);

-- Invoice Knowledge Links
CREATE TABLE IF NOT EXISTS invoice_knowledge_link (
  id BIGSERIAL PRIMARY KEY,
  invoice_id BIGINT NOT NULL REFERENCES account_invoice(id) ON DELETE CASCADE,
  knowledge_page_id BIGINT NOT NULL REFERENCES knowledge_page(id) ON DELETE CASCADE,
  link_type VARCHAR(50), -- reference, related, policy, procedure
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (invoice_id, knowledge_page_id)
);

CREATE INDEX idx_account_invoice_vendor ON account_invoice(vendor_id);
CREATE INDEX idx_account_invoice_status ON account_invoice(status);
CREATE INDEX idx_account_invoice_payment_status ON account_invoice(payment_status);
CREATE INDEX idx_invoice_line_item_invoice ON invoice_line_item(invoice_id);
CREATE INDEX idx_invoice_attachment_invoice ON invoice_attachment(invoice_id);
