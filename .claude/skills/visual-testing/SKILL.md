---
name: visual-testing
description: Captures screenshots and compares them against baselines to detect UI regressions using Playwright. Use when verifying visual consistency of UI changes.
allowed-tools: Bash, Read, Write
model: sonnet
user-invocable: true
---

# Visual Regression Testing

Capture and compare UI screenshots to detect visual regressions using Playwright.

## Prerequisites

- Playwright installed: `npm install -D @playwright/test`
- Browsers installed: `npx playwright install`

## Workflow

### Step 1: Start Application
```bash
# Ensure dev server is running
npm run dev &
DEV_PID=$!

# Wait for server to be ready
npx wait-on http://localhost:3000
```

### Step 2: Capture Screenshots

#### Using Playwright Test
```typescript
// tests/visual/homepage.spec.ts
import { test, expect } from '@playwright/test';

test('homepage visual regression', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png');
});

test('dashboard visual regression', async ({ page }) => {
  // Login first if needed
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixels: 100,  // Allow minor differences
  });
});
```

#### Manual Screenshot
```bash
# Take a screenshot for a specific URL
npx playwright screenshot http://localhost:3000 screenshot.png
```

### Step 3: Run Visual Tests
```bash
# First run: Create baselines
npx playwright test --update-snapshots tests/visual/

# Subsequent runs: Compare against baselines
npx playwright test tests/visual/
```

### Step 4: Analyze Results

If differences detected:
1. View the diff images in `test-results/` directory
2. Compare: `expected`, `actual`, and `diff` images
3. Determine if change is:
   - **Intentional**: Update baseline
   - **Regression**: Report and fix

### Step 5: Update Baselines (if intentional)
```bash
# Update specific test
npx playwright test tests/visual/homepage.spec.ts --update-snapshots

# Update all snapshots
npx playwright test --update-snapshots
```

## Configuration

### playwright.config.ts
```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  snapshotDir: './tests/visual/snapshots',
  expect: {
    toHaveScreenshot: {
      maxDiffPixels: 100,
      threshold: 0.2,  // 20% threshold per pixel
    },
  },
  projects: [
    {
      name: 'chromium',
      use: { viewport: { width: 1280, height: 720 } },
    },
    {
      name: 'mobile',
      use: { viewport: { width: 375, height: 667 } },
    },
  ],
});
```

## Common Scenarios

### Full Page Screenshot
```typescript
await expect(page).toHaveScreenshot('full-page.png', {
  fullPage: true,
});
```

### Component Screenshot
```typescript
const button = page.getByRole('button', { name: 'Submit' });
await expect(button).toHaveScreenshot('submit-button.png');
```

### Mask Dynamic Content
```typescript
await expect(page).toHaveScreenshot('page.png', {
  mask: [
    page.locator('.timestamp'),
    page.locator('.random-avatar'),
  ],
});
```

### Different Viewports
```typescript
test('responsive design', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/');
  await expect(page).toHaveScreenshot('mobile.png');

  await page.setViewportSize({ width: 1920, height: 1080 });
  await expect(page).toHaveScreenshot('desktop.png');
});
```

## Report Format

When visual regression detected:
```markdown
## Visual Regression Report

### Test: homepage visual regression
- **Status**: FAILED
- **Diff Pixels**: 1,247 (threshold: 100)
- **Location**: Top navigation area

### Analysis
The navigation bar height changed by 2px, causing cascading layout shifts.

### Recommendation
- If intentional: Update baseline with `--update-snapshots`
- If regression: Check recent CSS changes to `.nav` class
```

## Rules

- ALWAYS mask dynamic content (timestamps, avatars, etc.)
- ALWAYS test multiple viewports for responsive designs
- ALWAYS clean up dev server after testing
- NEVER commit failing visual tests without review
- ALWAYS version control baseline snapshots
