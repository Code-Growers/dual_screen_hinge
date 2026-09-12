import { expect, test } from '@playwright/test';

test('docs load with responsive navigation and interactive simulator', async ({ page }) => {
  await page.goto('');
  await expect(page.getByRole('heading', { name: 'Foldable APIs for Flutter' })).toBeVisible();
  await expect(page.getByRole('navigation', { name: 'Primary navigation' })).toBeVisible();

  const slider = page.getByRole('slider');
  await slider.fill('45');
  await expect(page.getByText('45° · halfOpened')).toBeVisible();
  await expect(page.getByText(/"hingeAngle": 45/)).toBeVisible();
});

test('dark mode and guide routes work under the GitHub Pages base path', async ({ page }) => {
  await page.goto('guides/getting-started');
  await expect(page.getByRole('heading', { name: 'Getting started' })).toBeVisible();
  await page.getByRole('button', { name: /theme/i }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', /dark|light/);
});
