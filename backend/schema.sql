CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    crn VARCHAR(50) UNIQUE NOT NULL,
    base_currency VARCHAR(3) NOT NULL DEFAULT 'KWD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE user_role AS ENUM ('ADMIN', 'TENANT', 'CLIENT');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    role user_role NOT NULL DEFAULT 'CLIENT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE property_type AS ENUM ('COMMERCIAL', 'RESIDENTIAL', 'INDUSTRIAL', 'RETAIL');

CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type property_type NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL DEFAULT 'Kuwait City',
    total_gla NUMERIC(12, 2) NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE unit_status AS ENUM ('VACANT', 'LEASED', 'SOLD', 'UNDER_MAINTENANCE');
CREATE TYPE listing_intent AS ENUM ('FOR_RENT', 'FOR_SALE', 'BOTH', 'NOT_LISTED');

CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_number VARCHAR(50) NOT NULL,
    floor INT NOT NULL DEFAULT 1,
    gla NUMERIC(10, 2) NOT NULL,
    rental_price NUMERIC(15, 3) NOT NULL DEFAULT 0.000,
    sale_price NUMERIC(15, 3) NOT NULL DEFAULT 0.000,
    status unit_status NOT NULL DEFAULT 'VACANT',
    listing_intent listing_intent NOT NULL DEFAULT 'FOR_RENT',
    features TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(property_id, unit_number)
);

CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    civil_id_or_crn VARCHAR(50) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE lease_status AS ENUM ('DRAFT', 'ACTIVE', 'TERMINATED', 'EXPIRED');

CREATE TABLE leases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE RESTRICT,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent NUMERIC(15, 3) NOT NULL,
    security_deposit NUMERIC(15, 3) NOT NULL DEFAULT 0.000,
    status lease_status NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE invoice_status AS ENUM ('PENDING', 'PAID', 'OVERDUE', 'CANCELLED');

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    lease_id UUID NOT NULL REFERENCES leases(id) ON DELETE RESTRICT,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount NUMERIC(15, 3) NOT NULL,
    status invoice_status NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(50),
    paid_at TIMESTAMPTZ,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE expense_category AS ENUM ('MAINTENANCE', 'UTILITIES', 'INSURANCE', 'GOVERNMENT_TAX', 'MANAGEMENT_FEES', 'CAPEX');

CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
    category expense_category NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    expense_date DATE NOT NULL,
    amount NUMERIC(15, 3) NOT NULL,
    description TEXT,
    receipt_reference VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE ticket_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'EMERGENCY');
CREATE TYPE ticket_status AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED');

CREATE TABLE maintenance_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    priority ticket_priority NOT NULL DEFAULT 'MEDIUM',
    status ticket_status NOT NULL DEFAULT 'OPEN',
    description TEXT NOT NULL,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE inquiry_type AS ENUM ('RENT', 'BUY', 'GENERAL');
CREATE TYPE inquiry_status AS ENUM ('NEW', 'CONTACTED', 'VIEWING_SCHEDULED', 'CLOSED');

CREATE TABLE client_inquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID REFERENCES users(id) ON DELETE SET NULL,
    unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
    client_name VARCHAR(150) NOT NULL,
    client_email VARCHAR(255) NOT NULL,
    client_phone VARCHAR(30) NOT NULL,
    inquiry_type inquiry_type NOT NULL,
    message TEXT NOT NULL,
    status inquiry_status NOT NULL DEFAULT 'NEW',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
