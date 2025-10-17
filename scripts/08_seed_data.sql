-- Seed Data for Odoo Notion Workspace

-- Insert Knowledge Categories
INSERT INTO knowledge_category (name, description, color, icon, sequence) VALUES
('HR & Payroll', 'Human Resources and Payroll Documentation', '#FF6B6B', 'users', 1),
('Finance & Accounting', 'Financial Policies and Accounting Procedures', '#4ECDC4', 'dollar-sign', 2),
('Projects', 'Project Management Guidelines', '#45B7D1', 'briefcase', 3),
('Vendors', 'Vendor Management and Contracts', '#FFA07A', 'truck', 4),
('Policies', 'Company Policies and Procedures', '#98D8C8', 'file-text', 5);

-- Insert Knowledge Tags
INSERT INTO knowledge_tag (name, color) VALUES
('urgent', '#FF6B6B'),
('important', '#FFD93D'),
('reference', '#6BCB77'),
('procedure', '#4D96FF'),
('policy', '#9D84B7');

-- Insert Knowledge Pages
INSERT INTO knowledge_page (title, content, category_id, status, access_level, created_by) VALUES
('Expense Policy', 'Guidelines for submitting and approving expenses...', 1, 'published', 'team', NULL),
('Invoice Processing', 'Step-by-step guide for processing vendor invoices...', 2, 'published', 'team', NULL),
('Project Kickoff Checklist', 'Essential items to complete before project start...', 3, 'published', 'team', NULL),
('Vendor Onboarding', 'Process for adding new vendors to the system...', 4, 'published', 'team', NULL),
('Code of Conduct', 'Company code of conduct and ethics policy...', 5, 'published', 'public', NULL);

-- Insert Projects
INSERT INTO project (name, description, status, start_date, end_date, budget) VALUES
('Website Redesign', 'Complete redesign of company website', 'active', '2025-01-15', '2025-06-30', 50000.00),
('Mobile App Development', 'Native iOS and Android app development', 'active', '2025-02-01', '2025-12-31', 150000.00),
('Data Migration', 'Migrate legacy systems to cloud infrastructure', 'on_hold', '2025-03-01', '2025-08-31', 75000.00),
('Customer Portal', 'Build self-service customer portal', 'active', '2025-01-20', '2025-05-31', 60000.00);

-- Insert Project Tasks
INSERT INTO project_task (project_id, title, description, status, priority, due_date, estimated_hours) VALUES
(1, 'Design Mockups', 'Create UI/UX mockups for new website', 'in_progress', 'high', '2025-02-15', 40),
(1, 'Frontend Development', 'Implement responsive frontend', 'todo', 'high', '2025-04-15', 120),
(1, 'Backend API', 'Build REST API endpoints', 'todo', 'high', '2025-04-30', 80),
(2, 'iOS Development', 'Develop iOS native app', 'todo', 'high', '2025-09-30', 200),
(2, 'Android Development', 'Develop Android native app', 'todo', 'high', '2025-09-30', 200),
(3, 'Data Audit', 'Audit existing data for migration', 'todo', 'medium', '2025-03-31', 60),
(4, 'Portal Design', 'Design customer portal interface', 'todo', 'medium', '2025-02-28', 50);

-- Insert Vendor Profiles
INSERT INTO vendor_profile (vendor_name, contact_person, email, phone, website, city, country, payment_terms, status, rating) VALUES
('Tech Solutions Inc', 'John Smith', 'john@techsolutions.com', '+1-555-0101', 'www.techsolutions.com', 'San Francisco', 'USA', 'Net 30', 'active', 4.5),
('Global Supplies Ltd', 'Maria Garcia', 'maria@globalsupplies.com', '+1-555-0102', 'www.globalsupplies.com', 'New York', 'USA', 'Net 45', 'active', 4.0),
('Premium Services Co', 'David Chen', 'david@premiumservices.com', '+1-555-0103', 'www.premiumservices.com', 'Los Angeles', 'USA', 'Net 30', 'active', 4.8),
('International Trade Group', 'Sophie Martin', 'sophie@intltrade.com', '+33-1-555-0104', 'www.intltrade.com', 'Paris', 'France', 'Net 60', 'active', 3.9),
('Local Contractors LLC', 'Mike Johnson', 'mike@localcontractors.com', '+1-555-0105', 'www.localcontractors.com', 'Chicago', 'USA', 'Net 15', 'active', 4.2);

-- Insert Vendor Contacts
INSERT INTO vendor_contact (vendor_id, contact_name, contact_title, email, phone, is_primary) VALUES
(1, 'John Smith', 'Account Manager', 'john@techsolutions.com', '+1-555-0101', TRUE),
(1, 'Sarah Wilson', 'Technical Support', 'sarah@techsolutions.com', '+1-555-0106', FALSE),
(2, 'Maria Garcia', 'Sales Director', 'maria@globalsupplies.com', '+1-555-0102', TRUE),
(3, 'David Chen', 'CEO', 'david@premiumservices.com', '+1-555-0103', TRUE),
(4, 'Sophie Martin', 'International Sales', 'sophie@intltrade.com', '+33-1-555-0104', TRUE);

-- Insert Vendor Rate Cards
INSERT INTO vendor_rate_card (vendor_id, vendor_name, effective_from, effective_to, role, region, unit, rate, currency) VALUES
(1, 'Tech Solutions Inc', '2025-01-01', '2025-12-31', 'Senior Developer', 'North America', 'hour', 150.00, 'USD'),
(1, 'Tech Solutions Inc', '2025-01-01', '2025-12-31', 'Junior Developer', 'North America', 'hour', 75.00, 'USD'),
(2, 'Global Supplies Ltd', '2025-01-01', '2025-12-31', 'Standard', 'North America', 'unit', 25.00, 'USD'),
(3, 'Premium Services Co', '2025-01-01', '2025-12-31', 'Consulting', 'North America', 'day', 2000.00, 'USD'),
(4, 'International Trade Group', '2025-01-01', '2025-12-31', 'Standard', 'Europe', 'unit', 30.00, 'EUR');

-- Insert Concur Mappings
INSERT INTO concur_mapping (mapping_type, odoo_id, odoo_name, concur_id, concur_name) VALUES
('expense_type', '1', 'Travel', 'TRAVEL', 'Travel Expenses'),
('expense_type', '2', 'Meals', 'MEALS', 'Meals & Entertainment'),
('expense_type', '3', 'Office', 'OFFICE', 'Office Supplies'),
('cost_center', '100', 'Engineering', 'CC100', 'Engineering Department'),
('cost_center', '200', 'Sales', 'CC200', 'Sales Department'),
('cost_center', '300', 'HR', 'CC300', 'Human Resources'),
('gl_account', '4100', 'Travel Expense', 'GL4100', 'Travel Expense Account'),
('gl_account', '4200', 'Meals Expense', 'GL4200', 'Meals & Entertainment Account');

-- Insert Sample Invoices
INSERT INTO account_invoice (invoice_number, vendor_id, vendor_name, invoice_date, due_date, amount, tax_amount, total_amount, status, payment_status) VALUES
('INV-2025-001', 1, 'Tech Solutions Inc', '2025-01-15', '2025-02-14', 5000.00, 500.00, 5500.00, 'approved', 'paid'),
('INV-2025-002', 2, 'Global Supplies Ltd', '2025-01-20', '2025-03-06', 2500.00, 250.00, 2750.00, 'approved', 'unpaid'),
('INV-2025-003', 3, 'Premium Services Co', '2025-01-25', '2025-02-24', 8000.00, 800.00, 8800.00, 'submitted', 'unpaid'),
('INV-2025-004', 4, 'International Trade Group', '2025-02-01', '2025-03-31', 3500.00, 350.00, 3850.00, 'draft', 'unpaid'),
('INV-2025-005', 5, 'Local Contractors LLC', '2025-02-05', '2025-02-20', 1500.00, 150.00, 1650.00, 'approved', 'partial');

-- Insert Workspace Metrics
INSERT INTO workspace_metric (metric_name, metric_type, module_name, value) VALUES
('Total Knowledge Pages', 'count', 'knowledge', 5),
('Active Projects', 'count', 'projects', 3),
('Pending Invoices', 'count', 'accounting', 3),
('Total Vendors', 'count', 'vendors', 5),
('Open Tasks', 'count', 'projects', 7),
('Total Invoice Amount', 'sum', 'accounting', 21550.00),
('Average Vendor Rating', 'average', 'vendors', 4.28);

-- Insert User Preferences (sample for demo)
INSERT INTO user_preference (user_id, theme, language, timezone, notifications_enabled, email_digest, default_view) 
SELECT id, 'light', 'en', 'UTC', TRUE, 'daily', 'dashboard' 
FROM auth.users LIMIT 1;
