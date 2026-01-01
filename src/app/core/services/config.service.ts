import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { EnvironmentConfig } from '../models/environment.model';
import { firstValueFrom } from 'rxjs';

/**
 * ConfigService
 * Loads and provides runtime environment configuration
 * Loaded via APP_INITIALIZER before app starts
 */
@Injectable({
  providedIn: 'root',
})
export class ConfigService {
  private config: EnvironmentConfig | null = null;
  private readonly CONFIG_PATH = '/assets/config/environment.json';

  constructor(private http: HttpClient) {}

  /**
   * Load configuration from JSON file
   * Called by APP_INITIALIZER before app bootstrap
   */
  async loadConfig(): Promise<void> {
    try {
      this.config = await firstValueFrom(this.http.get<EnvironmentConfig>(this.CONFIG_PATH));

      // Validate configuration
      this.validateConfig(this.config);

      console.warn(`[ConfigService] Configuration loaded for environment: ${this.config.name}`);
    } catch (error) {
      console.error('[ConfigService] Failed to load configuration:', error);
      throw new Error('Failed to load application configuration');
    }
  }

  /**
   * Get current configuration
   * Throws error if config not loaded
   */
  getConfig(): EnvironmentConfig {
    if (!this.config) {
      throw new Error('Configuration not loaded. APP_INITIALIZER may have failed.');
    }
    return this.config;
  }

  /**
   * Get specific config value with type safety
   */
  get apiUrl(): string {
    return this.getConfig().apiUrl;
  }

  get authUrl(): string {
    return this.getConfig().authUrl;
  }

  get isProduction(): boolean {
    return this.getConfig().production;
  }

  get environmentName(): string {
    return this.getConfig().name;
  }

  get features() {
    return this.getConfig().features;
  }

  /**
   * Validate configuration structure
   * Fail fast if required fields missing
   */
  private validateConfig(config: EnvironmentConfig): void {
    const requiredFields: (keyof EnvironmentConfig)[] = [
      'name',
      'production',
      'apiUrl',
      'authUrl',
      'features',
    ];

    for (const field of requiredFields) {
      if (config[field] === undefined || config[field] === null) {
        throw new Error(`Missing required configuration field: ${field}`);
      }
    }

    // Validate URLs
    if (!this.isValidUrl(config.apiUrl)) {
      throw new Error(`Invalid API URL: ${config.apiUrl}`);
    }

    if (!this.isValidUrl(config.authUrl)) {
      throw new Error(`Invalid Auth URL: ${config.authUrl}`);
    }

    console.warn('[ConfigService] Configuration validation passed');
  }

  /**
   * Simple URL validation
   */
  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }
}
