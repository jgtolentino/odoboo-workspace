# Custom Security - Hide Vendor Names

Odoo 18 module to hide vendor/supplier names from Account Managers while keeping product rates visible.

## Use Case

**Account Managers need to:**

- See service products (roles/expertise) WITH rates
- Search and add products to sales orders
- Build client estimates using product rates

**Account Managers should NOT see:**

- Vendor/supplier names
- Vendor contact information
- Supplier records in Contacts app

**Finance team sees everything:**

- All product details
- Vendor names and contact information
- Full supplier management

## Example

### Account Manager View

```
Product: Senior Developer
Rate: $150/hr
Description: Full-stack development services
```

### Finance View

```
Product: Senior Developer
Rate: $150/hr
Description: Full-stack development services
Vendor: TechStaff Corp
Contact: john@techstaffcorp.com
Vendor Code: TS-001
```

## Installation

1. Copy module to `addons/custom_security/`
2. Update apps list: Settings → Apps → Update Apps List
3. Install: Search "Custom Security" → Install

## Configuration

### 1. Assign Users to Group

Settings → Users & Companies → Users

- Select Account Manager user
- Access Rights tab
- Sales section: Check "Account Manager (Limited)"

### 2. Verify Access

**As Account Manager:**

- Navigate to: Sales → Products → Products
- ✅ Can see product name and rate
- ❌ Cannot see "Purchase" tab
- ❌ Cannot see vendor fields

**Test in Contacts:**

- Navigate to: Contacts
- ✅ Can see customers
- ❌ Cannot see vendors (supplier_rank > 0)

## Technical Details

### Security Rules

**ir.rule: Hide Vendors**

```xml
Domain: [('supplier_rank', '=', 0)]
Model: res.partner
Effect: Only shows partners with supplier_rank = 0 (customers)
```

**ir.rule: Allow All Products**

```xml
Domain: [(1, '=', 1)]
Model: product.template
Effect: All products visible (but vendor fields hidden in views)
```

### View Modifications

- Hides "Purchase" tab on product form (contains vendor info)
- Hides supplier_taxes_id field
- Disables create/edit/delete on product list for AMs

### Access Rights

- Read-only access to products
- Can create/edit sale orders
- Can create/edit sale order lines
- No access to purchase orders

## Workflow

### Creating a Sale Order (AM)

1. Sales → Orders → Create
2. Add customer
3. Add Order Lines:
   - Select product: "Senior Developer"
   - See rate: $150/hr ✅
   - Don't see vendor: (hidden) ❌
4. Confirm order
5. Finance approves and creates purchase order with actual vendor

### Purchase Request Flow

1. AM creates sale order with service products
2. Finance receives notification
3. Finance opens sale order
4. Finance sees vendor information
5. Finance creates purchase order with vendor
6. Finance approves and processes

## Troubleshooting

**AM can still see vendors:**

- Check user has "Account Manager (Limited)" group
- Check user does NOT have "Purchase / Manager" or admin rights
- Refresh browser

**AM cannot see products:**

- Check ir.rule is active: Settings → Technical → Security → Record Rules
- Search for "AM: Can See All Products"
- Verify domain: `[(1, '=', 1)]`

**Vendor fields still visible:**

- Check view inheritance is correct
- Update apps list
- Upgrade module

## License

LGPL-3
