/**
 * Environment Configuration Model
 * Defines the structure of runtime environment configuration
 */

export type EnvironmentType = 'development' | 'qa' | 'staging' | 'production';

export interface EnvironmentConfig {
  // Environment identification
  name: EnvironmentType;
  production: boolean;

  // API Configuration
  apiUrl: string;
  apiTimeout: number; // milliseconds

  // Authentication
  authUrl: string;
  authTokenKey: string;

  // Feature Flags
  features: {
    enableNewCheckout: boolean;
    enableAnalytics: boolean;
    enableLogging: boolean;
  };

  // Analytics
  analytics?: {
    googleAnalyticsId?: string;
    enableTracking: boolean;
  };

  // Performance
  cacheTimeout: number; // seconds
  retryAttempts: number;
}
