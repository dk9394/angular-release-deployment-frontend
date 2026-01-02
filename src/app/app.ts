import { Component, signal } from '@angular/core';
import { ConfigService } from './core/services/config.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  standalone: false,
  styleUrl: './app.scss',
})
export class App {
  protected readonly title = signal('Angular Release & Deployment');
  protected readonly environment = signal('');
  protected readonly apiUrl = signal('');
  protected readonly isProduction = signal(false);

  constructor(private configService: ConfigService) {
    // Configuration is already loaded by APP_INITIALIZER
    const config = this.configService.getConfig();
    console.warn('Current Environment: ', config.name);
    this.environment.set(config.name);
    this.apiUrl.set(config.apiUrl);
    this.isProduction.set(config.production);
  }
}
