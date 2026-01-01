import { ConfigService } from './config.service';

/**
 * APP_INITIALIZER Factory
 * Ensures configuration is loaded before Angular app bootstraps
 * Returns a Promise that Angular waits for
 */
export function initializeApp(configService: ConfigService) {
  return (): Promise<void> => {
    return configService.loadConfig();
  };
}
