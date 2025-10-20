#!/usr/bin/env python3
"""
Computer Use Skill - Browser automation and computer control
Integrates Anthropic's Computer Use with Playwright for Odoo workflows
"""

import asyncio
import base64
import os
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

from playwright.async_api import async_playwright, Page, Browser
import anthropic


class ComputerUseClient:
    """Client for computer use automation with Anthropic + Playwright"""

    def __init__(self):
        self.anthropic_client = anthropic.Anthropic(
            api_key=os.getenv('ANTHROPIC_API_KEY')
        )
        self.browser: Optional[Browser] = None
        self.page: Optional[Page] = None

    async def __aenter__(self):
        """Async context manager entry"""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self.close()

    async def close(self):
        """Close browser and cleanup"""
        if self.page:
            await self.page.close()
        if self.browser:
            await self.browser.close()

    async def execute(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute computer use automation request

        Args:
            request: Automation request with action, target, value, etc.

        Returns:
            dict: Execution result with status, result data, screenshot
        """
        action = request.get('action')
        start_time = time.time()

        try:
            if action == 'browser_workflow':
                result = await self._execute_browser_workflow(request)
            elif action == 'browser_navigate':
                result = await self._navigate(request.get('target'))
            elif action == 'click':
                result = await self._click(request.get('target'))
            elif action == 'type':
                result = await self._type(
                    request.get('target'),
                    request.get('value')
                )
            elif action == 'screenshot':
                result = await self._screenshot()
            elif action == 'odoo_approval_flow':
                result = await self._odoo_approval_flow(request)
            elif action == 'portal_download':
                result = await self._portal_download(request)
            elif action == 'odoo_automation':
                result = await self._odoo_automation(request)
            else:
                raise ValueError(f"Unknown action: {action}")

            execution_time = time.time() - start_time

            return {
                'status': 'success',
                'action': action,
                'result': result,
                'execution_time_ms': int(execution_time * 1000),
                'timestamp': datetime.utcnow().isoformat() + 'Z',
            }

        except Exception as e:
            # Capture error screenshot
            screenshot_b64 = None
            try:
                if self.page:
                    screenshot_b64 = await self._screenshot()
            except:
                pass

            return {
                'status': 'error',
                'action': action,
                'error': str(e),
                'error_type': type(e).__name__,
                'screenshot_base64': screenshot_b64,
                'timestamp': datetime.utcnow().isoformat() + 'Z',
            }

    async def _ensure_browser(self):
        """Ensure browser and page are initialized"""
        if not self.browser:
            playwright = await async_playwright().start()
            self.browser = await playwright.chromium.launch(
                headless=True,
                args=['--disable-blink-features=AutomationControlled']
            )

        if not self.page:
            context = await self.browser.new_context(
                viewport={'width': 1920, 'height': 1080},
                user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                          'AppleWebKit/537.36 (KHTML, like Gecko) '
                          'Chrome/120.0.0.0 Safari/537.36'
            )
            self.page = await context.new_page()

    async def _navigate(self, url: str) -> Dict[str, Any]:
        """Navigate to URL"""
        await self._ensure_browser()
        response = await self.page.goto(url, wait_until='networkidle', timeout=30000)

        return {
            'final_url': self.page.url,
            'status_code': response.status if response else None,
            'title': await self.page.title(),
        }

    async def _click(self, selector: str) -> Dict[str, Any]:
        """Click element by selector"""
        await self._ensure_browser()
        await self.page.wait_for_selector(selector, timeout=10000)
        await self.page.click(selector)
        await self.page.wait_for_load_state('networkidle', timeout=5000)

        return {
            'clicked': True,
            'selector': selector,
            'current_url': self.page.url,
        }

    async def _type(self, selector: str, value: str) -> Dict[str, Any]:
        """Type text into element"""
        await self._ensure_browser()
        await self.page.wait_for_selector(selector, timeout=10000)
        await self.page.fill(selector, value)

        return {
            'typed': True,
            'selector': selector,
            'value_length': len(value),
        }

    async def _screenshot(self) -> str:
        """Capture screenshot and return base64"""
        await self._ensure_browser()
        screenshot_bytes = await self.page.screenshot(full_page=False)
        return base64.b64encode(screenshot_bytes).decode()

    async def _execute_browser_workflow(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Execute multi-step browser workflow"""
        steps = request.get('steps', [])
        results = []
        screenshot_b64 = None

        for i, step in enumerate(steps):
            action = step.get('action')

            if action == 'navigate':
                result = await self._navigate(step.get('target'))
            elif action == 'click':
                result = await self._click(step.get('target'))
            elif action == 'type':
                result = await self._type(step.get('target'), step.get('value'))
            elif action == 'wait':
                await asyncio.sleep(step.get('duration', 1) / 1000)
                result = {'waited_ms': step.get('duration', 1000)}
            else:
                raise ValueError(f"Unknown workflow step action: {action}")

            results.append({
                'step': i + 1,
                'action': action,
                'result': result,
            })

            # Capture screenshot if requested
            if step.get('screenshot'):
                screenshot_b64 = await self._screenshot()

        return {
            'steps_completed': len(results),
            'final_url': self.page.url,
            'results': results,
            'screenshot_base64': screenshot_b64,
        }

    async def _odoo_approval_flow(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Automate Odoo approval workflow

        Args:
            request: {
                "model": "odoobo.budget.request",
                "record_id": 5,
                "approval_steps": [...]
            }
        """
        model = request.get('model')
        record_id = request.get('record_id')
        odoo_url = os.getenv('ODOO_URL', 'http://localhost:8069')

        # Navigate to record
        record_url = f"{odoo_url}/web#id={record_id}&model={model}&view_type=form"
        await self._navigate(record_url)

        # Wait for form to load
        await asyncio.sleep(2)

        # Click approve button
        await self._click("button[name='action_approve']")

        # Wait for state change
        await asyncio.sleep(1)

        # Verify state
        state_element = await self.page.query_selector("span.o_stat_text")
        state_text = await state_element.inner_text() if state_element else None

        screenshot_b64 = await self._screenshot()

        return {
            'model': model,
            'record_id': record_id,
            'budget_state': state_text,
            'approver': request.get('approval_steps', [{}])[0].get('user'),
            'approved_at': datetime.utcnow().isoformat() + 'Z',
            'screenshot_base64': screenshot_b64,
        }

    async def _portal_download(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Download file from Odoo portal"""
        portal_url = request.get('portal_url')
        login_email = request.get('login_email')
        login_password = request.get('login_password')
        download_target = request.get('download_target')
        output_path = request.get('output_path', '/tmp/download.pdf')

        # Navigate to portal
        await self._navigate(portal_url)

        # Login if needed
        if await self.page.query_selector("input[name='login']"):
            await self._type("input[name='login']", login_email)
            await self._type("input[name='password']", login_password)
            await self._click("button[type='submit']")
            await asyncio.sleep(2)

        # Find and click download link
        async with self.page.expect_download() as download_info:
            await self.page.click(f"text={download_target}")

        download = await download_info.value
        await download.save_as(output_path)

        file_size = Path(output_path).stat().st_size

        return {
            'file_downloaded': True,
            'file_path': output_path,
            'file_size_bytes': file_size,
        }

    async def _odoo_automation(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generic Odoo automation using Anthropic Computer Use

        Uses Claude to understand the UI and perform actions
        """
        model = request.get('model')
        record_id = request.get('record_id')
        workflow = request.get('workflow')
        odoo_url = os.getenv('ODOO_URL', 'http://localhost:8069')

        # Navigate to record
        record_url = f"{odoo_url}/web#id={record_id}&model={model}&view_type=form"
        await self._navigate(record_url)

        # Get screenshot for Claude
        screenshot_b64 = await self._screenshot()

        # Ask Claude what to do using Computer Use
        prompt = f"""
        You are viewing an Odoo record (model: {model}, id: {record_id}).
        Workflow to execute: {workflow}

        What actions should be taken? Please respond with specific CSS selectors
        and actions in JSON format.
        """

        # Note: Actual Computer Use API integration would go here
        # This is a simplified version for demonstration
        message = self.anthropic_client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/png",
                            "data": screenshot_b64,
                        },
                    },
                    {
                        "type": "text",
                        "text": prompt,
                    }
                ],
            }],
        )

        claude_response = message.content[0].text

        return {
            'model': model,
            'record_id': record_id,
            'workflow': workflow,
            'claude_suggestion': claude_response,
            'screenshot_base64': screenshot_b64,
        }


# Async wrapper for HTTP endpoint
async def execute_computer_use(request: Dict[str, Any]) -> Dict[str, Any]:
    """Execute computer use request (called by FastAPI endpoint)"""
    async with ComputerUseClient() as client:
        return await client.execute(request)


if __name__ == '__main__':
    # Test the skill
    import sys

    async def test():
        async with ComputerUseClient() as client:
            result = await client.execute({
                'action': 'browser_navigate',
                'target': 'https://www.odoo.com',
            })
            print(result)

    asyncio.run(test())
