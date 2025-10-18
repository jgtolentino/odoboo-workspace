import { test, expect } from '@playwright/test';

test.describe('Notion Demo Page Styling', () => {
  test('should load the demo page with proper styling', async ({ page }) => {
    await page.goto('https://v0-odoo-notion-workspace.vercel.app/notion-demo');

    // Check page title
    await expect(page).toHaveTitle(/Notion-Style Workspace/);

    // Check that the page has proper styling
    const header = page.locator('h1');
    await expect(header).toBeVisible();
    await expect(header).toHaveText('Notion-Style Workspace Demo');

    // Check that Tailwind classes are working
    const container = page.locator('.container');
    await expect(container).toBeVisible();

    // Check that the block editor is styled
    const blockEditor = page.locator('[data-testid="block-editor"]');
    await expect(blockEditor).toBeVisible();

    // Check that buttons have proper styling
    const buttons = page.locator('button');
    await expect(buttons.first()).toBeVisible();

    // Verify background color is applied (Tailwind working)
    const body = page.locator('body');
    const backgroundColor = await body.evaluate((el) => {
      return window.getComputedStyle(el).backgroundColor;
    });
    expect(backgroundColor).not.toBe('rgba(0, 0, 0, 0)'); // Should have a background color
  });

  test('should display block editor with proper styling', async ({ page }) => {
    await page.goto('https://v0-odoo-notion-workspace.vercel.app/notion-demo');

    // Check block editor container
    const blockEditor = page.locator('[data-testid="block-editor"]');
    await expect(blockEditor).toBeVisible();

    // Check that text blocks are styled
    const textBlocks = page.locator('[data-testid="text-block"]');
    const count = await textBlocks.count();
    expect(count).toBeGreaterThan(0);

    // Check that add block button is styled
    const addButton = page.locator('[data-testid="add-block-button"]');
    await expect(addButton).toBeVisible();

    // Verify padding and margins are applied (Tailwind working)
    const blockContainer = page.locator('.block-container');
    if (await blockContainer.isVisible()) {
      const padding = await blockContainer.evaluate((el) => {
        return window.getComputedStyle(el).padding;
      });
      expect(padding).not.toBe('0px'); // Should have padding
    }
  });

  test('should have responsive design working', async ({ page }) => {
    await page.goto('https://v0-odoo-notion-workspace.vercel.app/notion-demo');

    // Test mobile view
    await page.setViewportSize({ width: 375, height: 667 });

    const container = page.locator('.container');
    await expect(container).toBeVisible();

    // Check that layout adapts to mobile
    const isMobileFriendly = await container.evaluate((el) => {
      const style = window.getComputedStyle(el);
      return style.maxWidth !== 'none' || style.padding !== '0px';
    });
    expect(isMobileFriendly).toBe(true);
  });
});
