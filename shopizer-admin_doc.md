# Shopizer Admin Panel — Documentation

## Overview

Shopizer Admin is an Angular-based single-page application (SPA) that serves as the administration panel for the Shopizer e-commerce platform. It communicates with a Java/Spring Boot backend REST API and provides a full-featured UI for managing stores, products, orders, customers, content, shipping, payments, and taxes. The application supports multiple operation modes (STANDARD, MARKETPLACE, BTB) and includes internationalization (i18n) with English and French.

---

## Technical Perspective

### Tech Stack

| Layer | Technology |
|---|---|
| Framework | Angular 11.2.x |
| Language | TypeScript 4.0.8 |
| UI Component Library | Nebular 6.2 (`@nebular/theme`, `@nebular/auth`, `@nebular/security`, `@nebular/eva-icons`) |
| CSS Framework | Bootstrap 4.3.1, SCSS |
| State/Data Tables | ng2-smart-table, PrimeNG 8 (PickList, TreeTable, Dropdown, AutoComplete, MultiSelect) |
| Charts | ngx-echarts (ECharts 4), angular2-chartjs (Chart.js 2.9), @swimlane/ngx-charts |
| Rich Text Editor | Summernote (via ngx-summernote) |
| Internationalization | @ngx-translate/core + @ngx-translate/http-loader |
| HTTP Client | Angular HttpClient with custom interceptors |
| Notifications | ngx-toastr |
| File Upload | ngx-awesome-uploader, ngx-dropzone, fine-uploader, angular-file, ng6-file-man |
| Tree View | angular-tree-component |
| Maps | @asymmetrik/ngx-leaflet (Leaflet) |
| Modals | ngx-smart-modal, @ng-bootstrap/ng-bootstrap |
| Image Viewer | ngx-lightbox |
| Phone Validation | libphonenumber-js |
| Date Handling | date-fns, @nebular/date-fns, @nebular/moment |
| Icons | Eva Icons, Font Awesome 5, Ionicons, Socicon, Nebular Icons |
| RxJS | 6.5.x |
| Build Tool | Angular CLI 11.2.x |
| Package Manager | npm |
| Testing | Karma + Jasmine (unit), Protractor (e2e) |
| Linting | ESLint (@angular-eslint), TSLint (legacy), Stylelint |
| Documentation | @compodoc/compodoc |
| Containerization | Docker (nginx:alpine) |
| CI/CD | CircleCI |

### Architecture

```
src/
├── app/
│   ├── @core/          # Core singleton module (mock data services, utils, security)
│   ├── @theme/         # Theme module (layout, header, footer, pipes, styles)
│   ├── pages/          # Feature modules (lazy-loaded)
│   │   ├── auth/       # Authentication (login, register, forgot/reset password)
│   │   ├── home/       # Dashboard / home page
│   │   ├── catalogue/  # Product catalog management
│   │   ├── orders/     # Order management
│   │   ├── customers/  # Customer management
│   │   ├── user-management/  # Admin user management
│   │   ├── store-management/ # Store/merchant management
│   │   ├── content/    # CMS content management
│   │   ├── shipping/   # Shipping configuration
│   │   ├── payment/    # Payment gateway configuration
│   │   ├── tax-management/   # Tax classes and rates
│   │   ├── shared/     # Shared services, guards, models, components, interceptors
│   │   └── custom-component/ # Reusable custom widgets (store autocomplete)
│   ├── app.module.ts
│   ├── app-routing.module.ts
│   └── app.component.ts
├── assets/
│   ├── i18n/           # Translation files (en.json, fr.json, es.json, ru.json)
│   ├── img/            # Static images (payment/shipping provider logos)
│   ├── env.js          # Runtime environment variables
│   └── env.template.js # Docker env template (envsubst at container start)
├── environments/
│   ├── environment.ts      # Dev config
│   └── environment.prod.ts # Prod config (reads from window["env"])
└── index.html
```

The application follows a modular architecture pattern:
- `@core` module: Singleton services, mock data providers, layout/state utilities. Uses Nebular's security module with role-based access control. Guarded against multiple imports via `throwIfAlreadyLoaded`.
- `@theme` module: Provides the Nebular theme configuration (corporate theme by default), layout components (SampleLayout with sidebar + header + footer), and shared pipes (Capitalize, Plural, Round, Timing, NumberWithCommas).
- `pages` module: Container for all feature modules, each lazy-loaded via Angular router. The `PagesComponent` renders the sidebar menu (`nb-menu`) and `router-outlet` inside the `SampleLayout`.
- `shared` module: Cross-cutting concerns shared across feature modules.

### Routing

The app uses hash-based routing (`useHash: true`).

Top-level routes (`app-routing.module.ts`):
- `/auth` → AuthModule (lazy-loaded, public)
- `/pages` → PagesModule (lazy-loaded, protected by `AuthGuard`)
- `/user/:id/reset/:id` → ResetPasswordComponent
- `/gallery` → ImageBrowserComponent
- `/errorPage` → ErrorComponent
- `/` → redirects to `/pages`

Pages child routes (`pages-routing.module.ts`):
- `/pages/home` → HomeModule
- `/pages/orders` → OrdersModule
- `/pages/user-management` → UserManagementModule
- `/pages/store-management` → StoreManagementModule
- `/pages/catalogue` → CatalogueModule (guarded by `SuperadminStoreRetailCatalogueGuard`)
- `/pages/content` → ContentModule
- `/pages/shipping` → ShippingModule
- `/pages/payment` → PaymentModule
- `/pages/tax-management` → TaxManagementModule
- `/pages/customer` → CustomersModule

All feature modules are lazy-loaded using the legacy string-based `loadChildren` syntax.

### Authentication & Security

- JWT-based authentication via `AuthInterceptor` (HTTP interceptor that attaches `Bearer` token to all requests)
- Token stored in localStorage via `TokenService`
- `AuthGuard` protects all `/pages` routes — redirects to `/auth` if no token
- Token refresh mechanism implemented in the interceptor (handles 401 responses)
- `GlobalHttpInterceptorService` handles global HTTP errors
- Role-based access control with roles: `SUPERADMIN`, `ADMIN`, `ADMIN_RETAIL`, `ADMIN_CATALOGUE`, `ADMIN_STORE`, `ADMIN_ORDER`, `ADMIN_CONTENT`, `CUSTOMER`
- Menu visibility is dynamically controlled by role-checking guard functions in `pages-menu.ts`
- Multiple route guards: `AuthGuard`, `AdminGuard`, `OrdersGuard`, `MarketplaceGuard`, `RetailAdminGuard`, `StoreGuard`, `SuperadminStoreRetailCatalogueGuard`, `SuperuserAdminGuard`, `SuperuserAdminRetailGuard`, `SuperuserAdminRetailStoreGuard`, `ExitGuard`

### Shared Services

Located in `src/app/pages/shared/services/`:
- `CrudService`: Central HTTP wrapper around `HttpClient`. All API calls go through this service. Supports both the main API (`environment.apiUrl`) and a separate shipping API (`environment.shippingApi`). Methods: `get`, `post`, `put`, `patch`, `delete`, and shipping-specific variants.
- `ConfigService`: Fetches store languages, countries, zones/provinces, currencies, weights/sizes, and site configuration from the API.
- `UserService`: User CRUD, profile retrieval, role checking, merchant info. Manages role state in-memory and localStorage.
- `StorageService`: Abstraction over localStorage for userId, merchant, language, country, and roles.
- `SecurityService`: Security-related operations.
- `CountryService`: Country and zone data retrieval.
- `ListingService`: Generic listing/pagination support.
- `ManufactureService`: Manufacturer data.
- `ErrorService`: Error handling utilities.
- `ConnectionStatusService`: Backend health check — redirects to error page if API is down.

### Shared Components

Located in `src/app/pages/shared/components/`:
- `PaginatorComponent`: Reusable pagination control
- `ImageUploadingComponent`: Image upload widget
- `RightSidemenuComponent`: Slide-out side panel
- `ShowcaseDialogComponent`: Modal dialog (entry component)
- `BackButtonComponent`: Navigation back button
- `NotFoundComponent`: 404 page
- `FiveHundredComponent`: 500 error page
- `PasswordPromptComponent`: Password confirmation dialog

### Validation

Located in `src/app/pages/shared/validation/`:
- `EqualValidator`: Directive for matching field values (e.g., password confirmation)
- `MustMatch`: Reactive form validator for field matching
- `ValidateNumberDirective`: Numeric input validation directive
- `PriceValidation`: Price format validation
- `MatchPassword`: Password matching validator

### Theme Components

Located in `src/app/@theme/components/`:
- `HeaderComponent`: Top navigation bar
- `FooterComponent`: Page footer
- `SearchInputComponent`: Global search
- `SampleLayoutComponent`: Main layout shell (sidebar + content area)
- `ErrorComponent`: Global error page
- `ImageBrowserComponent`: Image gallery/browser
- `TinyMCEComponent`: Rich text editor wrapper

### Build & Deployment

- Dev server: `npm start` → `ng serve`
- Production build: `npm run build` → AOT compilation with `--prod` flag, 8GB max heap
- Output: `dist/` directory
- Docker deployment: Multi-stage build (`Dockerfile-all`) or pre-built (`Dockerfile`)
  - Stage 1: Node 12.8.0 builds the Angular app
  - Stage 2: nginx:alpine serves static files
  - Runtime environment injection via `envsubst` on `env.template.js` → `env.js`
  - Nginx configured with `try_files` for SPA routing
- Environment variables (configurable at runtime via Docker):
  - `APP_BASE_URL`: Backend API URL
  - `APP_SHIPPING_URL`: Shipping microservice URL
  - `APP_MAP_API_KEY`: Google Maps API key
  - `APP_DEFAULT_LANGUAGE`: Default UI language
- Proxy config (`proxy.conf.json`): Proxies `/api` to `http://aws-demo.shopizer.com:8080` during development
- CI: CircleCI integration (`.circleci/` directory)

### Operation Modes

Configured via `environment.mode`:
- `STANDARD`: Single-store mode. Categories and options are store-specific.
- `MARKETPLACE`: Multi-vendor marketplace. Categories and options are global (managed by superadmin).
- `BTB`: Business-to-business mode.

The mode affects menu visibility, guard behavior, and catalogue management access.

### Internationalization

- Translation files in `src/assets/i18n/` (en.json, fr.json — es.json and ru.json are stubs)
- `@ngx-translate` loads translations via HTTP at runtime
- `TranslateService` used throughout templates with the `| translate` pipe
- Menu items use translation keys (e.g., `COMPONENTS.HOME`)
- Language can be switched per-user; stored in localStorage

---

## Functional Perspective

### 1. Authentication & Registration

- Login page with username/password authentication against the backend API
- User registration with store creation (self-service signup)
- Forgot password flow (sends reset link via email)
- Password reset via token-based URL (`/user/:id/reset/:id`)
- Session management with JWT tokens and automatic refresh

### 2. Home Dashboard

- Displays store information: store name, address, city, state/province, postal code, country, phone
- Shows logged-in user info: username and last access timestamp
- System management panel with cache deletion (placeholder/disabled)
- Connection health monitoring — auto-redirects to error page if backend is unreachable

### 3. User Management

- View and edit own profile
- Create new admin users (admin-only)
- List all users with smart table (searchable, sortable)
- User detail view and editing via reusable user form
- Change password functionality
- Role assignment (SUPERADMIN, ADMIN, ADMIN_RETAIL, ADMIN_CATALOGUE, ADMIN_STORE, ADMIN_ORDER, ADMIN_CONTENT)
- Enable/disable user accounts

### 4. Store Management

- View and edit current store details (name, address, contact info, supported languages, currency)
- Store branding (logo upload)
- Store landing page configuration
- Create new stores (superadmin/admin retail)
- List all stores
- Retailer management (list retailers, retailer stores)
- Store form with country/zone selection, language configuration, currency, and weight/size measures

### 5. Catalogue Management

Guarded by role — requires admin or retail admin access.

#### 5.1 Categories
- List categories (with smart table)
- Create/edit categories with multilingual descriptions
- Category hierarchy view (tree component)
- Category detail pages

#### 5.2 Products
- List products (searchable, sortable table)
- Create/edit products with comprehensive form:
  - Basic info and multilingual descriptions
  - Product images (upload, manage, reorder)
  - Product-to-category assignment
  - Product attributes/options management
  - Inventory management
  - Pricing configuration
  - Product properties
  - Product discounts
- Product ordering (drag-and-drop reordering within categories)

#### 5.3 Options / Properties
- List product options/properties
- Create/edit options with multilingual support
- Option values management (list, create, edit)
- Option value images
- Option sets (grouping options together)
- Product variations management

#### 5.4 Brands
- List brands
- Create/edit brands with multilingual descriptions
- Brand detail pages

#### 5.5 Product Groups
- List product groups
- Create/edit product groups
- Assign products to groups

#### 5.6 Product Types
- List product types
- Create/edit product types

#### 5.7 Catalogues
- List catalogues
- Create/edit catalogues
- Assign products to catalogues

### 6. Order Management

Visible to SUPERADMIN, ADMIN, ADMIN_RETAIL, and ADMIN_ORDER roles.

- Order list with pagination, filtering, and sorting
- Order detail view showing:
  - Customer billing and shipping addresses
  - Order items with quantities and prices
  - Order totals
  - Order status
- Order history tracking (status changes with comments)
- Order status updates (add history entries)
- Order invoice view
- Payment transaction management:
  - View transactions
  - Capture payments
  - Process refunds
  - View next available transaction type

### 7. Customer Management

- List customers (searchable table with pagination)
- Create/edit customer profiles with:
  - Personal information
  - Billing and shipping addresses
  - Country/zone selection
- Set customer credentials (username/password)
- Customer options and option values management

### 8. Content Management (CMS)

- Content Pages: Create/edit HTML content pages with rich text editor (Summernote), multilingual support
- Content Boxes: Create/edit content boxes (reusable content blocks), multilingual
- Content Images: Upload and manage content images
- Content Files: File management (partially implemented)
- Promotion management (placeholder/in development)

### 9. Shipping Management

- Expedition configuration (enable/disable shipping, set shipping type)
- Shipping methods management with support for multiple providers:
  - Canada Post (with detailed configuration: API credentials, services, packaging)
  - UPS (API credentials, service selection)
  - ShipRocket
  - Weight-based shipping
  - Custom shipping rules
  - Store pickup
  - Price by distance
- Shipping origin address configuration (country, state/province, city, postal code)
- Package/box management (create, list, edit packaging dimensions and weight)
- Shipping rules configuration (custom pricing rules)
- Transfer list box UI for selecting shipping zones/regions

### 10. Payment Management

- List available payment methods with provider logos
- Configure payment gateways with provider-specific forms:
  - Stripe (API keys, integration type)
  - PayPal Express Checkout (client ID, secret, environment)
  - Braintree (merchant ID, public/private keys, environment)
  - Beanstream (merchant ID, API credentials)
  - Paytm (merchant ID, keys)
  - Money Order (manual payment instructions)
- Enable/disable payment methods
- Environment selection (sandbox/production) per gateway

### 11. Tax Management

- Tax Classes: List, create, edit, and delete tax classes
- Tax Rates: List, create, edit, and delete tax rates with:
  - Country and zone/state selection
  - Tax rate percentage
  - Tax class assignment
  - Multilingual descriptions

### 12. Cross-Cutting Features

- Role-based menu visibility — sidebar menu items show/hide based on user roles
- Multilingual UI (English, French) with runtime language switching
- Responsive layout with Bootstrap grid
- Toast notifications for success/error feedback
- Loading spinners on async operations
- Smart tables with inline actions (edit, delete buttons)
- Image upload with drag-and-drop support
- Back navigation buttons
- Pagination controls
- Modal dialogs for confirmations
- Form validation (required fields, email format, password matching, numeric validation)
- Store autocomplete widget for multi-store contexts
