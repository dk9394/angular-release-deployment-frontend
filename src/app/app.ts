import { Component, OnInit, signal } from '@angular/core';
import { ConfigService } from './core/services/config.service';
import { PerformanceService } from './core/services/performance.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  standalone: false,
  styleUrl: './app.scss',
})
export class App implements OnInit {
  protected readonly title = signal('Angular Release & Deployment');
  protected readonly environment = signal('');
  protected readonly apiUrl = signal('');
  protected readonly isProduction = signal(false);

  constructor(
    private configService: ConfigService,
    private performanceService: PerformanceService,
  ) {
    // Configuration is already loaded by APP_INITIALIZER
    const config = this.configService.getConfig();
    console.warn('Current Environment: ', config.name);
    this.environment.set(config.name);
    this.apiUrl.set(config.apiUrl);
    this.isProduction.set(config.production);
  }

  ngOnInit(): void {
    // Initialize Web Vitals tracking
    // This will track LCP, INP, CLS, FCP, TTFB
    this.performanceService.initWebVitals();

    // Log performance summary in console
    if (typeof ngDevMode !== 'undefined' && ngDevMode) {
      console.warn(this.performanceService.getPerformanceSummary());
    }
  }
}
