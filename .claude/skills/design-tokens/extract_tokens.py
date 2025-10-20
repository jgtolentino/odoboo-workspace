#!/usr/bin/env python3
"""Design Token Extractor"""
import asyncio
import json
import logging
import re
from typing import Dict, Any, List
from playwright.async_api import async_playwright

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DesignTokenExtractor:
    def __init__(self):
        self.playwright = None
        self.browser = None
        
    async def __aenter__(self):
        self.playwright = await async_playwright().start()
        self.browser = await self.playwright.chromium.launch()
        return self
        
    async def __aexit__(self, *args):
        if self.browser:
            await self.browser.close()
        if self.playwright:
            await self.playwright.stop()
            
    async def extract(
        self,
        url: str,
        categories: List[str] = None
    ) -> Dict[str, Any]:
        """Extract design tokens from website"""
        if categories is None:
            categories = ["colors", "spacing", "typography"]
            
        page = await self.browser.new_page()
        await page.goto(url)
        
        # Extract CSS variables
        css_vars = await page.evaluate("""() => {
            const styles = getComputedStyle(document.documentElement);
            const vars = {};
            for (let prop of Array.from(document.styleSheets)
                .flatMap(sheet => Array.from(sheet.cssRules || []))
                .filter(rule => rule.selectorText === ':root')
                .flatMap(rule => Array.from(rule.style))) {
                if (prop.startsWith('--')) {
                    vars[prop] = styles.getPropertyValue(prop).trim();
                }
            }
            return vars;
        }""")
        
        await page.close()
        
        # Categorize tokens
        tokens = {"colors": {}, "spacing": {}, "typography": {}}
        for key, value in css_vars.items():
            if "color" in key or re.match(r'#[0-9a-fA-F]{3,6}', value):
                tokens["colors"][key] = value
            elif any(unit in value for unit in ["px", "rem", "em"]):
                if any(t in key for t in ["font", "text", "line-height"]):
                    tokens["typography"][key] = value
                else:
                    tokens["spacing"][key] = value
                    
        return {k: v for k, v in tokens.items() if k in categories}

if __name__ == "__main__":
    async def main():
        async with DesignTokenExtractor() as extractor:
            tokens = await extractor.extract("https://tailwindcss.com")
            print(json.dumps(tokens, indent=2))
    asyncio.run(main())
