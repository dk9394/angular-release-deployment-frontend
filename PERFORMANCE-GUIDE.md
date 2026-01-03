# Performance Monitoring Guide

**Version**: 1.0.0
**Last Updated**: 2026-01-03
**Phase**: 8 - Performance Monitoring

---

## Overview

This project implements comprehensive performance monitoring using:

1. **Web Vitals** - Real user performance tracking
2. **Lighthouse CI** - Automated performance testing in CI/CD

---

## Table of Contents

1. [Core Web Vitals](#core-web-vitals)
2. [Web Vitals Tracking](#web-vitals-tracking)
3. [Lighthouse CI](#lighthouse-ci)
4. [Performance Budgets](#performance-budgets)
5. [Lighthouse PR Comments](#lighthouse-pr-comments)
6. [Reading Lighthouse Reports](#reading-lighthouse-reports)
7. [Common Performance Issues](#common-performance-issues)
8. [Optimization Tips](#optimization-tips)
9. [Troubleshooting](#troubleshooting)

---

## Core Web Vitals

Google's official metrics for measuring user experience:

### 1. LCP (Largest Contentful Paint)

**What it measures:** Loading performance - when main content appears

**Thresholds:**

- ✅ Good: < 2.5 seconds
- ⚠️ Needs Improvement: 2.5s - 4s
- ❌ Poor: > 4 seconds

**What counts as LCP:**

- Large images
- Video thumbnails
- Block-level elements with background images
- Text blocks

**How to improve:**

- Optimize images (WebP, compression, lazy loading)
- Use CDN for assets
- Preload critical resources
- Minimize server response time

---

### 2. INP (Interaction to Next Paint)

**What it measures:** Interactivity - time between user action and visual response

**Thresholds:**

- ✅ Good: < 200 milliseconds
- ⚠️ Needs Improvement: 200ms - 500ms
- ❌ Poor: > 500 milliseconds

**What counts:**

- Button clicks
- Form inputs
- Menu interactions

**How to improve:**

- Reduce JavaScript execution time
- Break up long tasks
- Use web workers for heavy computation
- Optimize event handlers

---

### 3. CLS (Cumulative Layout Shift)

**What it measures:** Visual stability - unexpected layout shifts

**Thresholds:**

- ✅ Good: < 0.1
- ⚠️ Needs Improvement: 0.1 - 0.25
- ❌ Poor: > 0.25

**Common causes:**

- Images without dimensions
- Ads/embeds/iframes without reserved space
- Dynamically injected content
- Web fonts causing FOIT/FOUT

**How to improve:**

- Set explicit width/height for images
- Reserve space for dynamic content
- Use `font-display: swap` for web fonts
- Avoid inserting content above existing content

---

### 4. FCP (First Contentful Paint)

**What it measures:** When first content appears (any content)

**Thresholds:**

- ✅ Good: < 1.8 seconds
- ⚠️ Needs Improvement: 1.8s - 3s
- ❌ Poor: > 3 seconds

**How to improve:**

- Eliminate render-blocking resources
- Minify CSS and JavaScript
- Remove unused CSS
- Inline critical CSS

---

### 5. TTFB (Time to First Byte)

**What it measures:** Server response time

**Thresholds:**

- ✅ Good: < 800 milliseconds
- ⚠️ Needs Improvement: 800ms - 1.8s
- ❌ Poor: > 1.8 seconds

**How to improve:**

- Use CDN (CloudFront for S3)
- Optimize server processing
- Use HTTP/2 or HTTP/3
- Enable compression (Gzip/Brotli)

---

## Web Vitals Tracking

### How It Works

1. **PerformanceService** tracks metrics using `web-vitals` library
2. Metrics logged to console in development
3. Can send to analytics in production

### Implementation

```typescript
// src/app/core/services/performance.service.ts
export class PerformanceService {
  initWebVitals(): void {
    onLCP(this.handleMetric.bind(this));
    onINP(this.handleMetric.bind(this));
    onCLS(this.handleMetric.bind(this));
    onFCP(this.handleMetric.bind(this));
    onTTFB(this.handleMetric.bind(this));
  }
}
```

### Viewing Metrics

**Development:**

```bash
npm start
# Open http://localhost:4200
# Open browser console
# Look for [Performance] logs
```

**Example Output:**

```
[Performance] LCP: 1.8s ✅ (good)
[Performance] INP: 120ms ✅ (good)
[Performance] CLS: 0.05 ✅ (good)
[Performance] FCP: 1.2s ✅ (good)
[Performance] TTFB: 150ms ✅ (good)
```

---

## Lighthouse CI

### What is Lighthouse?

Automated tool that audits:

- **Performance** (speed)
- **Accessibility** (usability for disabled users)
- **Best Practices** (web standards)
- **SEO** (search engine optimization)
- **PWA** (progressive web app features)

Each category scored 0-100.

### How Lighthouse CI Works

**On Every PR:**

1. GitHub Actions triggers
2. Builds Angular app
3. Serves app locally
4. Runs Lighthouse 3 times (takes median)
5. Checks against budgets
6. ✅ Pass or ❌ Fail

### Configuration

**File**: `lighthouserc.json`

```json
{
  "ci": {
    "collect": {
      "url": ["http://localhost:4200"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }]
      }
    }
  }
}
```

### Assertion Levels

- **"error"**: Fail build if violated
- **"warn"**: Show warning but allow merge
- **"off"**: Don't check

---

## Performance Budgets

### Current Budgets

| Metric                        | Budget   | Level |
| ----------------------------- | -------- | ----- |
| **Performance Score**         | ≥ 90     | Error |
| **LCP**                       | ≤ 2.5s   | Error |
| **FCP**                       | ≤ 1.8s   | Error |
| **CLS**                       | ≤ 0.1    | Error |
| **TBT** (Total Blocking Time) | ≤ 300ms  | Warn  |
| **JavaScript Bundle**         | ≤ 500 KB | Error |
| **CSS Bundle**                | ≤ 50 KB  | Warn  |
| **Images**                    | ≤ 500 KB | Warn  |
| **Total Size**                | ≤ 1 MB   | Warn  |

### Why Budgets Matter

**Without Budgets:**

```
PR #1: Add library (+100KB) → Merged
PR #2: Add images (+200KB) → Merged
PR #3: Add animation (+150KB) → Merged
Result: App slow, users complain
```

**With Budgets:**

```
PR #1: Add library (+100KB)
  → Lighthouse: ❌ Bundle size 600KB (budget: 500KB)
  → Dev: Switches to lighter alternative
  → Lighthouse: ✅ Bundle size 450KB
  → Merged!
```

---

## Lighthouse PR Comments

### Overview

Starting from 2026-01-03, Lighthouse results are **automatically posted as PR comments**. You no longer need to download artifacts manually.

### What You'll See

**Success Example:**

When your PR passes performance budgets, you'll see:

```markdown
## 🎉 Lighthouse CI Passed!

### 📊 Performance Scores
| Category | Score | Status |
|----------|-------|--------|
| Performance | 95 | ✅ |
| Accessibility | 92 | ✅ |
| Best Practices | 98 | ✅ |
| SEO | 100 | ✅ |

### ⚡ Core Web Vitals
| Metric | Value | Budget | Status |
|--------|-------|--------|--------|
| LCP (Largest Contentful Paint) | 2.1s | ≤2.5s | ✅ |
| FCP (First Contentful Paint) | 1.6s | ≤1.8s | ✅ |
| CLS (Cumulative Layout Shift) | 0.050 | ≤0.1 | ✅ |
| TBT (Total Blocking Time) | 120ms | ≤300ms | ✅ |
| SI (Speed Index) | 2.8s | ≤3.4s | ✅ |
```

**Failure Example:**

When performance budgets are violated:

```markdown
## ❌ Lighthouse CI Failed

### 📊 Performance Scores
| Category | Score | Status |
|----------|-------|--------|
| Performance | 85 | ❌ |
| LCP | 3.2s | ≤2.5s | ❌ |
```

### How It Works

1. **Lighthouse CI runs** on every PR
2. **Parses JSON results** from `.lighthouseci/manifest.json`
3. **Extracts metrics** (performance scores, LCP, FCP, CLS, TBT, SI)
4. **Formats as markdown** with emojis (✅/❌)
5. **Posts comment** on the PR automatically
6. **Updates comment** on subsequent runs (no duplicates)

**Implementation:** `.github/workflows/performance-check.yml:186-300`

### Benefits

**Before (Manual):**
- Go to PR → Checks → Performance Check → Scroll to Artifacts → Download ZIP → Extract → Open HTML
- Time: ~2-3 minutes

**After (Automated):**
- Open PR → Scroll to comments → See results instantly
- Time: ~5 seconds

### Metrics Displayed

**Performance Scores:**
- Performance (≥90)
- Accessibility (≥90)
- Best Practices (≥90)
- SEO (≥90)

**Core Web Vitals:**
- LCP: Largest Contentful Paint (≤2.5s)
- FCP: First Contentful Paint (≤1.8s)
- CLS: Cumulative Layout Shift (≤0.1)
- TBT: Total Blocking Time (≤300ms)
- SI: Speed Index (≤3.4s)

### When Comments Appear

✅ **Comments posted:**
- Pull requests to `develop`, `staging`, or `main`

❌ **Comments NOT posted:**
- Manual workflow triggers
- Direct pushes to branches (not PRs)
- Markdown-only changes (workflow skipped)

### Troubleshooting PR Comments

**Comment not appearing?**

1. Verify it's a pull request (not a direct push)
2. Check workflow completed: PR → Checks → Performance Check
3. Look for errors in "Post Lighthouse results to PR" step

**Common issues:**
```
Manifest file not found, skipping PR comment
→ Lighthouse CI didn't complete successfully

LHR file not found, skipping PR comment
→ JSON report missing or corrupted
```

---

## Reading Lighthouse Reports

### Accessing Reports

1. **Go to PR**
2. **Check "Performance Check" workflow**
3. **Download "lighthouse-reports" artifact**
4. **Open `.lighthouseci/lhr-*.html` in browser**

### Report Structure

**Performance Category:**

- Overall score (0-100)
- Metrics (LCP, FCP, CLS, etc.)
- Opportunities (what to fix)
- Diagnostics (why it's slow)

**Example Opportunities:**

```
🔴 Properly size images - Save 450 KB
🟡 Minify JavaScript - Save 125 KB
🟢 Serve images in next-gen formats - Save 200 KB
```

### Understanding Scores

| Score  | Rating  | Color     | Meaning    |
| ------ | ------- | --------- | ---------- |
| 90-100 | Fast    | 🟢 Green  | Excellent  |
| 50-89  | Average | 🟡 Orange | Needs work |
| 0-49   | Slow    | 🔴 Red    | Poor       |

---

## Common Performance Issues

### 1. Large Bundle Size

**Symptom:** JS bundle > 500KB

**Causes:**

- Importing entire libraries
- No code splitting
- No tree shaking

**Fixes:**

```typescript
// ❌ Bad: Imports entire library (500KB)
import * as _ from 'lodash';

// ✅ Good: Import only what you need (5KB)
import { uniq } from 'lodash-es';
```

**Tools:**

```bash
# Analyze bundle
npm install -D webpack-bundle-analyzer
npm run build -- --stats-json
npx webpack-bundle-analyzer dist/stats.json
```

---

### 2. Unoptimized Images

**Symptom:** LCP > 2.5s, large image sizes

**Fixes:**

- Use WebP format
- Compress images (TinyPNG, ImageOptim)
- Use `srcset` for responsive images
- Lazy load off-screen images

**Example:**

```html
<!-- ❌ Bad: Large PNG -->
<img src="hero.png" alt="Hero" />

<!-- ✅ Good: Optimized WebP with fallback -->
<picture>
  <source srcset="hero.webp" type="image/webp" />
  <img src="hero.jpg" alt="Hero" width="800" height="600" />
</picture>
```

---

### 3. Render-Blocking Resources

**Symptom:** FCP > 1.8s

**Causes:**

- Synchronous CSS/JS in `<head>`
- Large CSS files
- External fonts

**Fixes:**

```html
<!-- ❌ Bad: Blocks rendering -->
<link rel="stylesheet" href="styles.css" />

<!-- ✅ Good: Preload critical CSS -->
<link rel="preload" href="critical.css" as="style" />
<link rel="stylesheet" href="critical.css" />
<link rel="stylesheet" href="non-critical.css" media="print" onload="this.media='all'" />
```

---

### 4. Layout Shifts

**Symptom:** CLS > 0.1

**Causes:**

- Images without dimensions
- Dynamic content insertion
- Web fonts loading

**Fixes:**

```html
<!-- ❌ Bad: No dimensions -->
<img src="product.jpg" alt="Product" />

<!-- ✅ Good: Explicit dimensions -->
<img src="product.jpg" alt="Product" width="400" height="300" />
```

```css
/* ✅ Reserve space for dynamic content */
.placeholder {
  min-height: 200px;
}

/* ✅ Font loading */
@font-face {
  font-family: 'CustomFont';
  src: url('font.woff2') format('woff2');
  font-display: swap; /* Prevents layout shift */
}
```

---

## Optimization Tips

### Angular-Specific

**1. Lazy Loading:**

```typescript
// app-routing.module.ts
const routes: Routes = [
  {
    path: 'products',
    loadChildren: () => import('./products/products.module').then((m) => m.ProductsModule),
  },
];
```

**2. OnPush Change Detection:**

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProductComponent {}
```

**3. TrackBy in \*ngFor:**

```typescript
<div *ngFor="let item of items; trackBy: trackByFn">
  {{ item.name }}
</div>

trackByFn(index: number, item: Product): number {
  return item.id;
}
```

---

### Build Optimization

**Angular.json Configuration:**

```json
{
  "projects": {
    "app": {
      "architect": {
        "build": {
          "configurations": {
            "production": {
              "optimization": true,
              "buildOptimizer": true,
              "aot": true,
              "extractLicenses": true,
              "sourceMap": false,
              "namedChunks": false,
              "vendorChunk": false
            }
          }
        }
      }
    }
  }
}
```

---

## Troubleshooting

### Lighthouse CI Failing

**Issue**: Performance score below 90

**Steps**:

1. Download lighthouse-reports artifact
2. Open HTML report
3. Check "Opportunities" section
4. Fix top 3 issues
5. Re-run

---

### Web Vitals Not Showing

**Issue**: No console logs in development

**Checks**:

1. Verify web-vitals installed: `npm list web-vitals`
2. Check PerformanceService initialized in AppComponent
3. Open browser console (F12)
4. Reload page (Ctrl+R)
5. Look for `[Performance]` logs

---

### Build Artifact Too Large

**Issue**: Bundle exceeds 500KB

**Analysis**:

```bash
# Build with source maps
npm run build -- --source-map

# Analyze
npx source-map-explorer dist/**/*.js
```

**Common Culprits**:

- RxJS operators (use pipeable operators)
- Moment.js (replace with date-fns)
- Lodash (use lodash-es)
- Large UI libraries

---

## Next Steps

**Phase 9: Security Hardening** (Coming Next)

- HTTPS & SSL certificates
- Content Security Policy
- Authentication (AWS Cognito)
- Dependency security scanning

---

## References

- [Web Vitals](https://web.dev/vitals/)
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci)
- [Angular Performance Guide](https://angular.io/guide/performance-best-practices)
- [Core Web Vitals Report](https://web.dev/vitals-measurement/)

---

**Last Updated**: 2026-01-03
**Phase**: 8 - Performance Monitoring Complete ✅
