import { Component, OnInit } from '@angular/core';
import { PerformanceService } from './core/services/performance.service';
import { RouterTestingModule } from '@angular/router/testing';

/**
 * Root AppComponent
 *
 * Responsibilities:
 * - Initialize performance tracking
 * - Render router outlet
 */
@Component({
  selector: 'app-root',
  imports: [RouterTestingModule],
  template: `
    <div class="app-container">
      <h1>Angular Release & Deployment</h1>
      <p>Environment: {{ environment }}</p>
      <router-outlet></router-outlet>
    </div>
  `,
  styles: [
    `
      .app-container {
        padding: 20px;
        font-family: Arial, sans-serif;
      }
      h1 {
        color: #333;
      }
    `,
  ],
})
export class AppComponent implements OnInit {
  environment = 'Loading...';

  constructor(private performanceService: PerformanceService) {}

  ngOnInit(): void {
    // Initialize Web Vitals tracking
    // This will track LCP, INP, CLS, FCP, TTFB
    this.performanceService.initWebVitals();

    // Set environment (in real app, this would come from ConfigService)
    this.environment = 'Development';

    // Log performance summary in console
    if (typeof ngDevMode !== 'undefined' && ngDevMode) {
      console.log(this.performanceService.getPerformanceSummary());
    }
  }
}
