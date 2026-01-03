# ============================================================================
# MULTI-STAGE DOCKERFILE FOR ANGULAR APPLICATION
# ============================================================================
#
# PURPOSE:
# This Dockerfile creates a production-ready Docker image for an Angular
# application using a multi-stage build approach.
#
# MENTAL MODEL - THE RESTAURANT KITCHEN ANALOGY:
#
# Traditional Single-Stage Build (The Old Way):
# - You have ONE kitchen with ALL equipment:
#   • Professional oven (Node.js)
#   • Mixer, blender, food processor (npm, build tools)
#   • Raw ingredients (source code, dependencies)
#   • Final plated dish (production app)
# - Problem: Kitchen stays cluttered with all equipment even after cooking
# - Result: 500MB+ image with build tools you don't need at runtime
#
# Multi-Stage Build (The Smart Way):
# - STAGE 1 - Prep Kitchen (Builder):
#   • Has all equipment (Node.js, npm, build tools)
#   • Prepares the dish (compiles Angular app)
#   • Creates final product (dist/ folder)
#
# - STAGE 2 - Service Counter (Production):
#   • Only has serving equipment (nginx)
#   • Takes ONLY the final dish from prep kitchen (dist/ folder)
#   • Serves to customers (browsers)
#
# - Result: Tiny 40MB image with just nginx + compiled files
#
# WHY MULTI-STAGE BUILDS MATTER:
# 1. Size: 500MB (single-stage) → 40MB (multi-stage) = 92% smaller
# 2. Security: Fewer tools = smaller attack surface
# 3. Speed: Smaller images download and deploy faster
# 4. Cost: Less storage, less bandwidth
#
# REAL-WORLD COMPARISON:
# Single-Stage Image:
# - Node.js runtime: 180MB
# - npm + build tools: 250MB
# - node_modules (dev): 500MB
# - Source code: 5MB
# - Compiled app: 3MB
# TOTAL: ~938MB
#
# Multi-Stage Image:
# - nginx: 40MB
# - Compiled app: 3MB
# TOTAL: ~43MB
#
# ============================================================================

# ============================================================================
# STAGE 1: BUILD STAGE (The Prep Kitchen)
# ============================================================================
#
# PURPOSE: Compile the Angular application
# LIFESPAN: Exists only during docker build, thrown away after
# RESULT: Creates dist/ folder with production-optimized files
#
# WHY "AS builder":
# - Names this stage "builder" so we can reference it later
# - COPY --from=builder means "copy from this stage"
#
FROM node:20-alpine AS builder

# ----------------------------------------------------------------------------
# Why node:20-alpine?
# ----------------------------------------------------------------------------
#
# node:20 = Node.js version 20 (LTS - Long Term Support)
# - Stable, production-ready
# - Matches your local development environment
# - Angular 17+ works best with Node 18+
#
# alpine = Lightweight Linux distribution
# - Regular node:20 image: 1GB
# - Alpine node:20 image: 180MB
# - Same functionality, 82% smaller
# - Based on Alpine Linux (minimalist distro)
#
# ALTERNATIVES:
# - node:20-slim (Debian-based, ~250MB, more compatible)
# - node:20-bullseye (Full Debian, ~900MB, maximum compatibility)
#
# TRADE-OFFS:
# - alpine: Smallest, but some npm packages might have issues (native modules)
# - slim: Good middle ground
# - bullseye: Largest, but best compatibility
#
# For Angular: alpine works great (no native dependencies in most cases)
#

# ----------------------------------------------------------------------------
# Set working directory
# ----------------------------------------------------------------------------
#
# WHAT: All subsequent commands run from this directory
# WHY: Keeps container filesystem organized
#
WORKDIR /app
#
# WHAT HAPPENS:
# - Docker creates /app directory inside container
# - All COPY, RUN commands now use /app as base path
#
# MENTAL MODEL:
# Think of WORKDIR like 'cd /app' that persists for all future commands
#
# EXAMPLE:
# WORKDIR /app
# COPY package.json ./    ← Copies to /app/package.json
# RUN npm install         ← Runs in /app directory
#

# ----------------------------------------------------------------------------
# Copy package files first (for layer caching)
# ----------------------------------------------------------------------------
#
# DOCKER LAYER CACHING EXPLAINED:
#
# Docker builds images in layers, like a stack of transparent sheets:
# - Layer 1: Base image (node:20-alpine)
# - Layer 2: WORKDIR /app
# - Layer 3: COPY package*.json ./
# - Layer 4: RUN npm ci
# - Layer 5: COPY . .
# - Layer 6: RUN npm run build
#
# CACHING MAGIC:
# - If a layer hasn't changed, Docker reuses cached version
# - If a layer changes, all subsequent layers are rebuilt
#
# WHY COPY package.json SEPARATELY:
#
# Scenario A (WRONG - Bad Caching):
# COPY . .                    ← Copies ALL files
# RUN npm ci                  ← Installs dependencies
#
# Problem:
# - You change src/app/app.component.ts (source code)
# - COPY . . layer changes (because file changed)
# - RUN npm ci re-runs (even though dependencies didn't change!)
# - Wastes 2-3 minutes reinstalling same packages
#
# Scenario B (RIGHT - Good Caching):
# COPY package*.json ./       ← Only copy dependency list
# RUN npm ci                  ← Install dependencies
# COPY . .                    ← Copy source code
#
# Benefit:
# - You change src/app/app.component.ts
# - package.json hasn't changed → npm ci layer cached! ✓
# - Only COPY . . and RUN npm run build re-run
# - Saves 2-3 minutes per build
#
COPY package*.json ./

# ----------------------------------------------------------------------------
# Install dependencies
# ----------------------------------------------------------------------------
#
# npm ci vs npm install - CRITICAL DIFFERENCE:
#
# npm install:
# - Reads package.json
# - Installs latest compatible versions
# - Updates package-lock.json
# - Different installs might get different versions (bad for reproducibility)
#
# npm ci (Continuous Integration):
# - Reads package-lock.json (exact versions)
# - Deletes node_modules first
# - Installs EXACT versions from lock file
# - Fails if package.json and package-lock.json are out of sync
# - Faster and more reliable
#
# WHY npm ci IN DOCKER:
# 1. Reproducibility: Same build every time
# 2. Speed: 2x faster than npm install
# 3. Reliability: No version drift
# 4. CI/CD: Standard for production builds
#
# WHEN TO USE WHICH:
# - Local development: npm install (updates lock file)
# - Docker builds: npm ci (reproducible builds)
# - CI/CD pipelines: npm ci (fast, reliable)
#
RUN npm ci

# Additional optimization: Remove npm cache after install
# This reduces the image layer size
# npm cache can be 100MB+
RUN npm cache clean --force

# ----------------------------------------------------------------------------
# Copy application source code
# ----------------------------------------------------------------------------
#
# WHAT: Copy everything except files listed in .dockerignore
# WHY: Now that dependencies are installed, we need the source code to build
#
COPY . .
#
# WHAT GETS COPIED:
# ✓ src/
# ✓ angular.json
# ✓ tsconfig.json
# ✓ public/
#
# WHAT DOESN'T GET COPIED (.dockerignore):
# ✗ node_modules/ (we already installed via npm ci)
# ✗ dist/ (we'll build fresh)
# ✗ .git/ (not needed)
# ✗ *.spec.ts (tests not needed in production)
#

# ----------------------------------------------------------------------------
# Build the Angular application for production
# ----------------------------------------------------------------------------
#
# WHAT: Compiles TypeScript, optimizes bundles, creates dist/ folder
# HOW: Runs the build script defined in package.json
#
RUN npm run build
#
# WHAT HAPPENS INSIDE 'npm run build':
# (Typically runs: ng build --configuration production)
#
# 1. TypeScript Compilation:
#    - Converts .ts files → .js files
#    - Type checking
#    - Produces ES2020 or ES2022 JavaScript
#
# 2. Bundling:
#    - Combines multiple files into chunks
#    - main.js (your app code)
#    - polyfills.js (browser compatibility)
#    - vendor.js (Angular framework + libraries)
#
# 3. Optimization:
#    - Minification: Remove whitespace, shorten variable names
#      • Before: function calculateTotal(items) { return items.reduce(...) }
#      • After: function c(i){return i.reduce(...)}
#    - Tree-shaking: Remove unused code
#      • If you import { Observable } but never use it, it's removed
#    - Dead code elimination: Remove unreachable code
#
# 4. Asset Optimization:
#    - Images: Copy to dist/
#    - CSS: Minify and extract
#    - Fonts: Copy to dist/
#
# 5. Cache Busting:
#    - Add hash to filenames: main.a1b2c3d4.js
#    - When you deploy new version, filename changes
#    - Browser sees new filename → downloads fresh file
#    - Old filename no longer exists → cache invalidated
#
# 6. Output:
#    - Creates dist/angular-release-deployment-frontend/browser/
#    - Contains: index.html, *.js, *.css, assets/
#
# SIZE COMPARISON:
# - Source code (src/): ~5MB (with formatting, comments)
# - Built output (dist/): ~3MB (minified, optimized)
# - Gzipped on network: ~500KB
#
# BUILD TIME:
# - First build: 2-3 minutes
# - Cached build (no changes): 10-20 seconds
#

# ----------------------------------------------------------------------------
# Build stage complete!
# ----------------------------------------------------------------------------
# At this point, we have:
# - /app/node_modules/ (500MB - build dependencies)
# - /app/src/ (5MB - source code)
# - /app/dist/ (3MB - compiled output) ← THIS is what we need!
#
# Next stage will take ONLY the dist/ folder and throw away everything else.
#

# ============================================================================
# STAGE 2: PRODUCTION STAGE (The Service Counter)
# ============================================================================
#
# PURPOSE: Serve the compiled Angular application with nginx
# LIFESPAN: This becomes the final image
# SIZE: ~40MB (nginx + compiled app)
# RESULT: Lightweight, production-ready container
#
FROM nginx:1.25-alpine

# ----------------------------------------------------------------------------
# Why nginx:1.25-alpine?
# ----------------------------------------------------------------------------
#
# nginx = Web server for serving static files
# - Extremely fast (C-based, event-driven)
# - Handles thousands of concurrent connections
# - Industry standard for serving SPAs
# - Lightweight (40MB Alpine image)
#
# 1.25 = nginx version
# - Stable release
# - Production-tested
# - Regular security updates
#
# alpine = Same minimalist Linux we used in build stage
# - nginx:1.25-alpine: 40MB
# - nginx:1.25: 180MB
#
# ALTERNATIVES:
# - Apache (httpd): More features, heavier, less common for SPAs
# - Caddy: Modern, automatic HTTPS, but heavier
# - Node.js serve: Overkill (don't need Node.js runtime for static files)
#
# For Angular SPA: nginx is the industry standard
#

# ----------------------------------------------------------------------------
# Copy custom nginx configuration
# ----------------------------------------------------------------------------
#
# WHY: Default nginx config doesn't handle SPA routing correctly
#
# PROBLEM WITH DEFAULT CONFIG:
# - User visits: http://localhost/products
# - nginx looks for file: /usr/share/nginx/html/products
# - File doesn't exist → 404 error
#
# SOLUTION WITH CUSTOM CONFIG:
# - User visits: http://localhost/products
# - nginx tries to find /products file → not found
# - nginx falls back to /index.html (our config: try_files $uri /index.html)
# - Browser loads index.html → Angular app starts
# - Angular router sees "/products" → displays ProductsComponent
#
COPY nginx.conf /etc/nginx/nginx.conf
#
# WHERE:
# - Source: ./nginx.conf (from build context)
# - Destination: /etc/nginx/nginx.conf (nginx config location)
#
# WHAT'S IN nginx.conf:
# - SPA routing fallback (try_files)
# - Gzip compression
# - Security headers
# - Caching rules
#

# ----------------------------------------------------------------------------
# Copy compiled application from build stage
# ----------------------------------------------------------------------------
#
# THIS IS THE MAGIC OF MULTI-STAGE BUILDS:
# - COPY --from=builder: Take files from "builder" stage
# - Don't copy: node_modules, source code, build tools
# - Only copy: Final compiled dist/ folder
#
COPY --from=builder /app/dist/angular-release-deployment-frontend/browser /usr/share/nginx/html
#
# BREAKDOWN:
# --from=builder
#   ↓ From the "builder" stage (Stage 1)
#
# /app/dist/angular-release-deployment-frontend/browser
#   ↓ Source path in builder stage
#   ↓ This is where 'ng build' puts compiled files
#
# /usr/share/nginx/html
#   ↓ Destination path in current stage
#   ↓ This is where nginx looks for files to serve
#
# RESULT:
# /usr/share/nginx/html/
# ├── index.html
# ├── main.a1b2c3d4.js
# ├── polyfills.e5f6g7h8.js
# ├── styles.i9j0k1l2.css
# └── assets/
#     └── (images, fonts, etc.)
#

# ----------------------------------------------------------------------------
# Expose port 80
# ----------------------------------------------------------------------------
#
# WHAT: Documents that this container listens on port 80
# WHY: Helps other developers understand how to run the container
#
EXPOSE 80
#
# IMPORTANT NOTES:
# - EXPOSE is documentation only, doesn't actually publish the port
# - To actually access the app, you need: docker run -p 8080:80
# - -p 8080:80 = Map host port 8080 → container port 80
#
# MENTAL MODEL:
# EXPOSE 80 = "This container has a door labeled '80'"
# docker run -p 8080:80 = "Connect my computer's port 8080 to that door"
#

# ----------------------------------------------------------------------------
# Define startup command
# ----------------------------------------------------------------------------
#
# WHAT: Command to run when container starts
# WHY: Starts the nginx web server
#
CMD ["nginx", "-g", "daemon off;"]
#
# BREAKDOWN:
# nginx = Start nginx web server
# -g "daemon off;" = Run in foreground (don't daemonize)
#
# WHY "daemon off;"?
# - By default, nginx runs as a background daemon
# - Docker needs a foreground process to keep container running
# - If main process exits, container stops
# - "daemon off;" keeps nginx in foreground → container stays alive
#
# WHAT HAPPENS WHEN CONTAINER STARTS:
# 1. Docker runs: nginx -g "daemon off;"
# 2. nginx reads config from /etc/nginx/nginx.conf
# 3. nginx starts listening on port 80
# 4. nginx serves files from /usr/share/nginx/html
# 5. Container stays running until you stop it
#

# ============================================================================
# BUILD AND RUN INSTRUCTIONS
# ============================================================================
#
# BUILD THE IMAGE:
#   docker build -t angular-frontend:latest .
#
# EXPLANATION:
#   docker build = Build a Docker image
#   -t angular-frontend:latest = Tag image as "angular-frontend" version "latest"
#   . = Use current directory as build context
#
# WHAT HAPPENS DURING BUILD:
#   [Stage 1 - Builder]
#   Step 1/10: FROM node:20-alpine AS builder
#   Step 2/10: WORKDIR /app
#   Step 3/10: COPY package*.json ./
#   Step 4/10: RUN npm ci
#   Step 5/10: RUN npm cache clean --force
#   Step 6/10: COPY . .
#   Step 7/10: RUN npm run build
#   [Stage 2 - Production]
#   Step 8/10: FROM nginx:1.25-alpine
#   Step 9/10: COPY nginx.conf /etc/nginx/nginx.conf
#   Step 10/10: COPY --from=builder /app/dist/.../browser /usr/share/nginx/html
#   Successfully built abc123def456
#   Successfully tagged angular-frontend:latest
#
# BUILD TIME: 2-5 minutes (first time), 10-30 seconds (cached)
#
# RUN THE CONTAINER:
#   docker run -d -p 8080:80 --name angular-app angular-frontend:latest
#
# EXPLANATION:
#   docker run = Create and start a container
#   -d = Detached mode (run in background)
#   -p 8080:80 = Map host port 8080 to container port 80
#   --name angular-app = Name the container "angular-app"
#   angular-frontend:latest = Use this image
#
# ACCESS THE APP:
#   Open browser: http://localhost:8080
#
# VIEW LOGS:
#   docker logs angular-app
#   docker logs -f angular-app  (follow mode, like tail -f)
#
# STOP CONTAINER:
#   docker stop angular-app
#
# START STOPPED CONTAINER:
#   docker start angular-app
#
# REMOVE CONTAINER:
#   docker rm angular-app
#   docker rm -f angular-app  (force remove running container)
#
# INSPECT CONTAINER:
#   docker exec -it angular-app sh
#   (Opens shell inside running container)
#
# REMOVE IMAGE:
#   docker rmi angular-frontend:latest
#
# ============================================================================
# DEBUGGING TIPS
# ============================================================================
#
# Build fails at npm ci:
#   - Check that package.json and package-lock.json are in sync
#   - Try: npm install locally, commit updated package-lock.json
#   - Try: docker build --no-cache (force full rebuild)
#
# Build fails at npm run build:
#   - Check that build script exists in package.json
#   - Check for TypeScript errors: npm run build locally first
#   - Check Node.js version compatibility
#
# Container starts but shows nginx 404:
#   - Check that dist path matches in COPY command
#   - Check Angular build output directory in angular.json
#   - Run: docker exec -it angular-app ls /usr/share/nginx/html
#
# Angular routes show 404 on refresh:
#   - Check nginx.conf has try_files $uri $uri/ /index.html
#   - Restart container after changing nginx.conf
#
# Container stops immediately after starting:
#   - Check logs: docker logs angular-app
#   - nginx might have config error
#   - Check: docker run -it angular-frontend:latest sh (debug)
#
# Changes not reflected after rebuild:
#   - Docker is caching old layers
#   - Try: docker build --no-cache
#   - Or: docker system prune (clean everything)
#
# ============================================================================
# OPTIMIZATION TIPS
# ============================================================================
#
# 1. Use .dockerignore:
#    - Prevents copying unnecessary files to build context
#    - Reduces build time and image size
#
# 2. Order matters:
#    - Put least-changing layers first (dependencies)
#    - Put most-changing layers last (source code)
#    - Maximizes cache hits
#
# 3. Combine RUN commands:
#    - Each RUN creates a new layer
#    - RUN npm ci && npm cache clean reduces layers
#
# 4. Use specific versions:
#    - node:20-alpine (not node:latest)
#    - Prevents unexpected breaking changes
#
# 5. Multi-stage is key:
#    - Don't ship build tools to production
#    - Smaller image = faster deployments
#
# ============================================================================
# SECURITY CONSIDERATIONS
# ============================================================================
#
# 1. Don't run as root (Advanced):
#    - Default: nginx runs as root
#    - Better: Create non-root user
#    - Add before CMD:
#      RUN chown -R nginx:nginx /usr/share/nginx/html
#      USER nginx
#
# 2. Scan for vulnerabilities:
#    - docker scan angular-frontend:latest
#    - Use Snyk, Trivy, or similar tools
#
# 3. Keep images updated:
#    - Regularly update base images
#    - nginx:1.25-alpine gets security patches
#
# 4. Don't bake secrets:
#    - Never COPY .env files into image
#    - Use environment variables or secrets management
#
# 5. Minimize attack surface:
#    - Multi-stage builds help (fewer tools in production)
#    - Alpine images help (minimal packages)
#
# ============================================================================
# FINAL IMAGE SIZE BREAKDOWN
# ============================================================================
#
# Layer 1: nginx:1.25-alpine base          ~40MB
# Layer 2: nginx.conf                      ~2KB
# Layer 3: Compiled Angular app            ~3MB
# ----------------------------------------
# TOTAL FINAL IMAGE:                       ~43MB
#
# Compare to single-stage:
# - Node.js + build tools + app:           ~900MB
#
# Size reduction: 95% smaller! 🎉
#
# ============================================================================
