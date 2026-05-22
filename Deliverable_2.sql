CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. BASE USERS & ROLES
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email_address TEXT UNIQUE NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('Student', 'Librarian', 'Administrator')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS students (
  id UUID PRIMARY KEY REFERENCES public.users (id) ON DELETE CASCADE,
  student_code TEXT UNIQUE NOT NULL,
  postal_address TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  is_university_student BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS librarians (
  id UUID PRIMARY KEY REFERENCES public.users (id) ON DELETE CASCADE,
  employee_code TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS admins (
  id UUID PRIMARY KEY REFERENCES public.users (id) ON DELETE CASCADE,
  employee_code TEXT UNIQUE NOT NULL
);

-- Create database roles (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'librarian_role') THEN
    CREATE ROLE librarian_role;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'student_role') THEN
    CREATE ROLE student_role;
  END IF;
END $$;

-- 2. RESOURCES INFRASTRUCTURE
CREATE TABLE IF NOT EXISTS resource_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES resource_categories(id) ON DELETE SET NULL,
  resource_type TEXT NOT NULL CHECK (resource_type IN('Book', 'Magazine', 'Computer', 'MeetingRoom'))
);

-- 3. RESOURCE SUBCLASSES
CREATE TABLE IF NOT EXISTS books (
  id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
  isbn TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  language TEXT NOT NULL,
  number_of_pages INT NOT NULL,
  publication_year INT NOT NULL,
  author TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS magazines (
  id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  issue_number TEXT NOT NULL,
  edition_number INT NOT NULL,   
  publication_date DATE NOT NULL,
  editor TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS computers (
  id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  serial_number TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS meeting_rooms (
  id UUID PRIMARY KEY REFERENCES resources(id) ON DELETE CASCADE,
  room_number TEXT UNIQUE NOT NULL,
  capacity INT DEFAULT 0,
  equipment TEXT NOT NULL,
  is_available BOOLEAN DEFAULT TRUE
);

-- 4. MASTER DIRECTORIES (Publishers & Subjects)
-- Placed BEFORE junction tables to respect foreign key constraints
CREATE TABLE IF NOT EXISTS publishers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  country TEXT
);

CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_name TEXT UNIQUE NOT NULL
);

-- 5. MANY-TO-MANY JUNCTIONS
CREATE TABLE IF NOT EXISTS book_publishers (
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  publisher_id UUID REFERENCES publishers(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, publisher_id)
);

CREATE TABLE IF NOT EXISTS magazine_publishers (
  magazine_id UUID REFERENCES magazines(id) ON DELETE CASCADE,
  publisher_id UUID REFERENCES publishers(id) ON DELETE CASCADE,
  PRIMARY KEY (magazine_id, publisher_id)
);

CREATE TABLE IF NOT EXISTS resource_subjects (
  resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
  PRIMARY KEY (resource_id, subject_id)
);

-- 6. PHYSICAL COPIES HIERARCHY
CREATE TABLE IF NOT EXISTS physical_copies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode TEXT UNIQUE NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  purchase_date DATE,
  rack_number TEXT,
  copy_type TEXT NOT NULL CHECK (copy_type IN('Book', 'Magazine'))
);

CREATE TABLE IF NOT EXISTS book_copies (
  id UUID PRIMARY KEY REFERENCES physical_copies(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS magazine_copies (
  id UUID PRIMARY KEY REFERENCES physical_copies(id) ON DELETE CASCADE,
  magazine_id UUID REFERENCES magazines(id) ON DELETE CASCADE
);

-- 7. TRANSACTIONS & SCHEDULES
CREATE TABLE IF NOT EXISTS library_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_number TEXT UNIQUE NOT NULL,
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  category_id UUID REFERENCES resource_categories(id) ON DELETE CASCADE,
  activation_date DATE DEFAULT CURRENT_DATE,
  expiration_date DATE,
  status TEXT DEFAULT 'Active'
);

CREATE TABLE IF NOT EXISTS loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
  copy_id UUID REFERENCES physical_copies(id) ON DELETE SET NULL,
  loan_date DATE DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  return_date DATE,
  status TEXT NOT NULL CHECK (status IN ('Active', 'Returned', 'Overdue'))
);

CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_room_id UUID REFERENCES meeting_rooms(id) ON DELETE CASCADE,
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime TIMESTAMPTZ NOT NULL,
  maintenance_type TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id) ON DELETE CASCADE,
  meeting_room_id UUID REFERENCES meeting_rooms(id) ON DELETE CASCADE,
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending',
  approved_by UUID REFERENCES librarians(id) ON DELETE SET NULL
);

-- 8. CUSTOM VIEW AUTOMATION
CREATE OR REPLACE VIEW overdue_inventory_view AS
SELECT
    l.id AS loan_id,
    s.student_code,
    b.title,
    bc.id AS copy_id,
    l.loan_date,
    l.due_date
FROM loans l
JOIN students s ON l.student_id = s.id
JOIN physical_copies pc ON l.copy_id = pc.id
JOIN book_copies bc ON pc.id = bc.id
JOIN books b ON bc.book_id = b.id
WHERE l.return_date IS NULL
  AND l.due_date < CURRENT_DATE;

-- 9. PROGRAMMATIC VALIDATION (Trigger)
CREATE OR REPLACE FUNCTION check_room_maintenance_overlap()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM maintenance_schedules ms
        WHERE ms.meeting_room_id = NEW.meeting_room_id
          AND NEW.start_datetime < ms.end_datetime
          AND NEW.end_datetime > ms.start_datetime
    ) THEN
        RAISE EXCEPTION 'Booking failed: This time slot overlaps with the room maintenance schedule.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_maintenance_schedule ON reservations;
CREATE TRIGGER enforce_maintenance_schedule
BEFORE INSERT OR UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION check_room_maintenance_overlap();

-- 10. SYSTEM PERMISSIONS (DCL)
GRANT SELECT, INSERT, UPDATE, DELETE ON resources, books, magazines, computers, meeting_rooms TO librarian_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON loans, reservations, physical_copies, book_copies, magazine_copies TO librarian_role;
GRANT SELECT ON public.users, students TO librarian_role;

GRANT SELECT ON resources, books, magazines, computers, meeting_rooms TO student_role;
GRANT INSERT ON reservations TO student_role;
GRANT SELECT ON reservations TO student_role;