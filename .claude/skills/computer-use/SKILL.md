# Computer Use Skill

**Skill Name**: computer-use
**Version**: 1.0.0
**Purpose**: Browser automation and computer control for Odoo workflows

## Description

Enables the odoobo-expert agent to interact with browsers and computer interfaces to automate complex workflows that require:

- Web form filling and submission
- Multi-step navigation flows
- Screenshot capture and verification
- Browser-based testing and validation
- Computer vision for UI verification

## Capabilities

### 1. Browser Automation

- Navigate to URLs and interact with web pages
- Fill forms automatically
- Click buttons and links
- Extract data from web pages
- Handle authentication flows

### 2. Screenshot & Verification

- Capture screenshots at any step
- Compare screenshots for visual regression
- Verify UI elements presence
- Extract text from screenshots (OCR)

### 3. Computer Control

- Keyboard input simulation
- Mouse click simulation
- File system operations (read/write)
- Application launch and control

### 4. Workflow Automation

- Multi-step browser workflows
- Form submission with validation
- Data extraction pipelines
- Automated testing sequences

## Use Cases

### Odoo Integration

1. **Automated Odoo Setup**: Install modules, configure settings
2. **Data Migration**: Fill forms, import CSV data
3. **Portal Testing**: Test client portal flows end-to-end
4. **Report Generation**: Navigate to reports, download PDFs
5. **Approval Workflows**: Simulate user approvals, state transitions

### External Integrations

1. **Vendor Portals**: Submit purchase orders, check order status
2. **Government Forms**: Fill tax forms, compliance submissions
3. **Banking**: Download statements, verify transactions
4. **Email**: Automate email workflows, extract attachments

## Parameters

### Input Schema

```json
{
  "action": "string (required)", // browser_navigate, click, type, screenshot, etc.
  "target": "string (optional)", // URL, element selector, file path
  "value": "string (optional)", // Text to type, data to submit
  "wait": "integer (optional)", // Wait time in milliseconds
  "screenshot": "boolean (optional)", // Capture screenshot after action
  "verify": "object (optional)" // Verification conditions
}
```

### Output Schema

```json
{
  "status": "success|error",
  "action": "string", // Action performed
  "result": "object|string", // Action result data
  "screenshot_base64": "string", // Screenshot if requested
  "timestamp": "string", // ISO 8601 timestamp
  "error": "string" // Error message if status=error
}
```

## Examples

### Example 1: Navigate and Fill Odoo Form

**Input**:

```json
{
  "action": "browser_workflow",
  "steps": [
    {
      "action": "navigate",
      "target": "https://odoo.example.com/web/login"
    },
    {
      "action": "type",
      "target": "input[name='login']",
      "value": "admin"
    },
    {
      "action": "type",
      "target": "input[name='password']",
      "value": "admin"
    },
    {
      "action": "click",
      "target": "button[type='submit']"
    },
    {
      "action": "navigate",
      "target": "/web#model=res.partner&view_type=form"
    },
    {
      "action": "type",
      "target": "input[name='name']",
      "value": "New Customer"
    },
    {
      "action": "click",
      "target": "button.o_form_button_save",
      "screenshot": true
    }
  ]
}
```

**Output**:

```json
{
  "status": "success",
  "action": "browser_workflow",
  "result": {
    "steps_completed": 7,
    "final_url": "https://odoo.example.com/web#id=42&model=res.partner",
    "record_id": 42
  },
  "screenshot_base64": "iVBORw0KGgo...",
  "timestamp": "2025-10-21T05:30:00Z"
}
```

### Example 2: Automated Budget Approval Flow

**Input**:

```json
{
  "action": "odoo_approval_flow",
  "model": "odoobo.budget.request",
  "record_id": 5,
  "approval_steps": [
    {
      "user": "finance.director@example.com",
      "action": "approve",
      "comment": "Approved based on Q4 budget allocation"
    }
  ],
  "verify_state": "approved",
  "verify_so_created": true
}
```

**Output**:

```json
{
  "status": "success",
  "action": "odoo_approval_flow",
  "result": {
    "budget_state": "approved",
    "sales_order_created": true,
    "sales_order_name": "S00042",
    "approver": "Finance Director",
    "approved_at": "2025-10-21T05:35:00Z"
  },
  "screenshot_base64": "iVBORw0KGgo...",
  "timestamp": "2025-10-21T05:35:15Z"
}
```

### Example 3: Portal Statement of Account Download

**Input**:

```json
{
  "action": "portal_download",
  "portal_url": "https://odoo.example.com/my/invoices",
  "login_email": "customer@example.com",
  "login_password": "portal123",
  "download_target": "Statement of Account",
  "output_path": "/tmp/statement.pdf"
}
```

**Output**:

```json
{
  "status": "success",
  "action": "portal_download",
  "result": {
    "file_downloaded": true,
    "file_path": "/tmp/statement.pdf",
    "file_size_bytes": 45678,
    "invoices_count": 12,
    "total_due": 15420.0
  },
  "timestamp": "2025-10-21T05:40:00Z"
}
```

## Implementation

### Technology Stack

- **Playwright**: Browser automation framework
- **Anthropic Computer Use**: Claude's computer control capability
- **OpenCV**: Computer vision for verification
- **Tesseract OCR**: Text extraction from screenshots

### Security Considerations

- **Credential Management**: All credentials via environment variables
- **Sandboxing**: Browser runs in isolated container
- **Screenshot Sanitization**: Remove sensitive data before storage
- **Audit Logging**: All actions logged with timestamps
- **Rate Limiting**: Max 10 actions per minute per user

### Error Handling

- **Retry Logic**: Up to 3 retries for transient failures
- **Timeout Management**: 30s default timeout per action
- **Graceful Degradation**: Partial results returned on failure
- **Error Screenshots**: Capture screenshot on error for debugging

## Dependencies

```txt
playwright>=1.40.0
opencv-python>=4.8.0
pytesseract>=0.3.10
anthropic>=0.5.0  # For Computer Use API
selenium>=4.15.0  # Fallback browser driver
```

## Integration with Odoo

### Server Action: "Automate with AI"

Add button to any Odoo model:

```python
def action_automate_with_ai(self):
    """Server action to trigger computer use automation"""
    agent_url = self.env['ir.config_parameter'].get_param('odoobo.agent_url')

    # Prepare automation request
    payload = {
        "skill": "computer-use",
        "action": "odoo_automation",
        "model": self._name,
        "record_id": self.id,
        "workflow": "custom_workflow_name",
    }

    response = requests.post(
        f"{agent_url}/skills/computer-use",
        json=payload,
        timeout=300,  # 5 min for complex workflows
    )

    result = response.json()

    # Post results to chatter
    self.message_post(
        body=f"<strong>Automation Complete</strong><br/>{result['summary']}",
        attachments=[(
            'screenshot.png',
            base64.b64decode(result.get('screenshot_base64', ''))
        )]
    )
```

## Testing

```python
import pytest
from computer_use import ComputerUseClient

def test_browser_navigate():
    client = ComputerUseClient()
    result = client.execute({
        "action": "navigate",
        "target": "https://odoo.com"
    })
    assert result['status'] == 'success'
    assert 'odoo.com' in result['result']['final_url']

def test_odoo_form_fill():
    client = ComputerUseClient()
    result = client.execute({
        "action": "browser_workflow",
        "steps": [
            {"action": "navigate", "target": "http://localhost:8069"},
            {"action": "type", "target": "input[name='name']", "value": "Test"},
            {"action": "click", "target": "button.o_form_button_save"}
        ]
    })
    assert result['status'] == 'success'
    assert result['result']['steps_completed'] == 3
```

## Performance Targets

- **Navigation Time**: P95 <3 seconds
- **Form Fill Time**: P95 <5 seconds per field
- **Screenshot Capture**: P95 <1 second
- **Full Workflow**: P95 <30 seconds for 10-step workflow
- **Error Rate**: <5% for well-formed requests

## Limitations

- **JavaScript-heavy sites**: May require wait times
- **CAPTCHAs**: Manual intervention required
- **Dynamic content**: May need custom selectors
- **Browser updates**: Requires Playwright updates
- **Headless limitations**: Some sites block headless browsers

## Future Enhancements

1. **Visual AI**: Use Claude vision for element detection
2. **Smart Retry**: ML-based retry strategies
3. **Workflow Templates**: Pre-built Odoo workflow templates
4. **Multi-tab Support**: Parallel browser tab automation
5. **Mobile Emulation**: Test mobile responsive designs
6. **Video Recording**: Record full workflow executions
7. **AI-powered Selectors**: Claude generates CSS selectors dynamically
