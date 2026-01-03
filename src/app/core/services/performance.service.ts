import { Injectable } from '@angular/core';
import { onCLS, onFCP, onINP, onLCP, onTTFB, Metric } from 'web-vitals';

/**
 * PerformanceService
 *
 * Tracks Core Web Vitals and reports performance metrics.
 *
 * Core Web Vitals (Google's official performance metrics):
 * - LCP (Largest Contentful Paint): Loading performance
 * - INP (Interaction to Next Paint): Interactivity
 * - CLS (Cumulative Layout Shift): Visual stability
 *
 * Additional metrics:
 * - FCP (First Contentful Paint): First paint
 * - TTFB (Time to First Byte): Server response time
 *
 * Usage:
 * - Automatically initialized in AppComponent
 * - Logs metrics to console in development
 * - Can send to analytics in production (future enhancement)
 */
@Injectable({
  providedIn: 'root',
})
export class PerformanceService {
  private isDevelopment = !this.isProduction();

  /**
   * Initialize Web Vitals tracking
   * Call this in AppComponent.ngOnInit()
   */
  initWebVitals(): void {
    // Track Largest Contentful Paint (LCP)
    // Measures loading performance
    // Good: < 2.5s | Needs Improvement: 2.5s - 4s | Poor: > 4s
    onLCP(this.handleMetric.bind(this), { reportAllChanges: false });

    // Track Interaction to Next Paint (INP)
    // Measures interactivity
    // Good: < 200ms | Needs Improvement: 200ms - 500ms | Poor: > 500ms
    onINP(this.handleMetric.bind(this), { reportAllChanges: false });

    // Track Cumulative Layout Shift (CLS)
    // Measures visual stability
    // Good: < 0.1 | Needs Improvement: 0.1 - 0.25 | Poor: > 0.25
    onCLS(this.handleMetric.bind(this), { reportAllChanges: false });

    // Track First Contentful Paint (FCP)
    // Measures when first content appears
    // Good: < 1.8s | Needs Improvement: 1.8s - 3s | Poor: > 3s
    onFCP(this.handleMetric.bind(this), { reportAllChanges: false });

    // Track Time to First Byte (TTFB)
    // Measures server response time
    // Good: < 800ms | Needs Improvement: 800ms - 1800ms | Poor: > 1800ms
    onTTFB(this.handleMetric.bind(this), { reportAllChanges: false });

    if (this.isDevelopment) {
      console.warn('[PerformanceService] Web Vitals tracking initialized');
    }
  }

  /**
   * Handle metric callback from web-vitals
   */
  private handleMetric(metric: Metric): void {
    const { name, value, rating } = metric;

    // Round value to 2 decimal places
    const roundedValue = Math.round(value * 100) / 100;

    // Format value based on metric type
    const formattedValue = this.formatMetricValue(name, roundedValue);

    // Get emoji based on rating
    const emoji = this.getRatingEmoji(rating);

    if (this.isDevelopment) {
      // Log to console in development
      console.warn(`[Performance] ${name}: ${formattedValue} ${emoji} (${rating})`);
    } else {
      // In production, send to analytics
      // Future enhancement: Send to Google Analytics, CloudWatch, etc.
      this.sendToAnalytics(metric);
    }
  }

  /**
   * Format metric value with appropriate units
   */
  private formatMetricValue(name: string, value: number): string {
    switch (name) {
      case 'CLS':
        // CLS is unitless
        return value.toFixed(3);
      case 'TTFB':
      case 'FCP':
      case 'LCP':
      case 'INP':
        // Time-based metrics in milliseconds
        if (value < 1000) {
          return `${value.toFixed(0)}ms`;
        } else {
          return `${(value / 1000).toFixed(2)}s`;
        }
      default:
        return value.toString();
    }
  }

  /**
   * Get emoji based on rating
   */
  private getRatingEmoji(rating: string): string {
    switch (rating) {
      case 'good':
        return '✅';
      case 'needs-improvement':
        return '⚠️';
      case 'poor':
        return '❌';
      default:
        return '';
    }
  }

  /**
   * Send metric to analytics endpoint
   * Future enhancement: Implement actual analytics integration
   */
  private sendToAnalytics(metric: Metric): void {
    // Example: Send to Google Analytics
    // if (typeof gtag !== 'undefined') {
    //   gtag('event', metric.name, {
    //     value: Math.round(metric.value),
    //     metric_id: metric.id,
    //     metric_value: metric.value,
    //     metric_delta: metric.delta,
    //   });
    // }

    // Example: Send to custom API
    // fetch('/api/performance-metrics', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({
    //     name: metric.name,
    //     value: metric.value,
    //     rating: metric.rating,
    //     timestamp: Date.now(),
    //   }),
    // });

    // For now, just log that we would send to analytics
    if (!this.isDevelopment) {
      console.log(`[Analytics] Would send ${metric.name}: ${metric.value}`);
    }
  }

  /**
   * Check if running in production
   */
  private isProduction(): boolean {
    // Check if Angular is in production mode
    // This is set by the Angular compiler during build
    return typeof ngDevMode === 'undefined' || !ngDevMode;
  }

  /**
   * Get performance summary
   * Useful for debugging or displaying in UI
   */
  getPerformanceSummary(): string {
    return `
Web Vitals Tracking Active:
- LCP: Largest Contentful Paint (loading)
- INP: Interaction to Next Paint (interactivity)
- CLS: Cumulative Layout Shift (visual stability)
- FCP: First Contentful Paint (first paint)
- TTFB: Time to First Byte (server response)

Check browser console for real-time metrics.
    `.trim();
  }
}
