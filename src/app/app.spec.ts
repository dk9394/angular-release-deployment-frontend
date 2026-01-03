import { TestBed } from '@angular/core/testing';
import { RouterModule } from '@angular/router';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { App } from './app';
import { ConfigService } from './core/services/config.service';

describe('App', () => {
  let mockConfigService: Partial<ConfigService>;

  beforeEach(async () => {
    // Create mock ConfigService
    mockConfigService = {
      getConfig: vi.fn().mockReturnValue({
        name: 'test',
        production: false,
        apiUrl: 'http://localhost:3000/api',
        authUrl: 'http://localhost:3000/auth',
        features: {
          enableAnalytics: false,
          enableLogging: true,
          enableDebugMode: true,
        },
      }),
    };

    await TestBed.configureTestingModule({
      imports: [RouterModule.forRoot([])],
      declarations: [App],
      providers: [{ provide: ConfigService, useValue: mockConfigService }],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should load configuration on initialization', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;

    expect(mockConfigService.getConfig).toHaveBeenCalled();
    expect(app['environment']()).toBe('test');
    expect(app['apiUrl']()).toBe('http://localhost:3000/api');
    expect(app['isProduction']()).toBe(false);
  });
});
