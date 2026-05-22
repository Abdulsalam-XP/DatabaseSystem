-- 1. BASE USERS
INSERT INTO public.users (id, first_name, last_name, email_address, user_type) VALUES
('11111111-1111-1111-1111-111111111111', 'Ahmad', 'Al-Mansoori', 'ahmad.student@bub.ac.ae', 'Student'),
('22222222-2222-2222-2222-222222222222', 'Sarah', 'Lynch', 'sarah.librarian@bub.ac.ae', 'Librarian'),
('33333333-3333-3333-3333-333333333333', 'Admin', 'User', 'admin.system@bub.ac.ae', 'Administrator'),
('44444444-4444-4444-4444-444444444444', 'Fatima', 'Al-Hashimi', 'fatima.external@gmail.com', 'Student');

-- 2. USER SUBCLASSES
INSERT INTO students (id, student_code, postal_address, phone_number, is_university_student) VALUES
('11111111-1111-1111-1111-111111111111', 'STU-2026-001', 'University City, Sharjah, UAE', '+971501111111', TRUE),
('44444444-4444-4444-4444-444444444444', 'EXT-2026-099', 'Al Majaz 2, Sharjah, UAE', '+971504444444', FALSE);

INSERT INTO librarians (id, employee_code) VALUES
('22222222-2222-2222-2222-222222222222', 'LIB-007');

INSERT INTO admins (id, employee_code) VALUES
('33333333-3333-3333-3333-333333333333', 'ADM-001');

-- 3. RESOURCE CATEGORIES
INSERT INTO resource_categories (id, category_name) VALUES
('00000000-1111-1111-1111-111111111111', 'Computer Science & AI'),
('00000000-2222-2222-2222-222222222222', 'Academic Journals & Periodicals'),
('00000000-3333-3333-3333-333333333333', 'Facilities & Study Spaces');

-- 4. MASTER RESOURCES
INSERT INTO resources (id, category_id, resource_type) VALUES
('aaaaaaaa-1111-1111-1111-111111111111', '00000000-1111-1111-1111-111111111111', 'Book'),
('aaaaaaaa-2222-2222-2222-222222222222', '00000000-2222-2222-2222-222222222222', 'Magazine'),
('aaaaaaaa-3333-3333-3333-333333333333', '00000000-1111-1111-1111-111111111111', 'Computer'),
('aaaaaaaa-4444-4444-4444-444444444444', '00000000-3333-3333-3333-333333333333', 'MeetingRoom');

-- 5. RESOURCE SUBCLASSES
INSERT INTO books (id, isbn, title, language, number_of_pages, publication_year, author) VALUES
('aaaaaaaa-1111-1111-1111-111111111111', '978-0136086208', 'Artificial Intelligence: A Modern Approach', 'English', 1132, 2020, 'Stuart Russell & Peter Norvig');

INSERT INTO magazines (id, title, issue_number, edition_number, publication_date, editor) VALUES
('aaaaaaaa-2222-2222-2222-222222222222', 'IEEE Intelligent Systems', 'Vol. 41 No. 2', 41, '2026-03-01', 'Dr. Chris Jordan');

INSERT INTO computers (id, brand, model, serial_number, status) VALUES
('aaaaaaaa-3333-3333-3333-333333333333', 'Apple', 'iMac M4', 'C02FX11V01XG', 'Available');

INSERT INTO meeting_rooms (id, room_number, capacity, equipment, is_available) VALUES
('aaaaaaaa-4444-4444-4444-444444444444', 'Room 302 (AI Lab Study Room)', 6, '85-inch Touchscreen Promethean Board, Camera, Array Microphones', TRUE);

-- 6. PUBLISHERS & SUBJECTS MASTER RECORDS
INSERT INTO publishers (id, name, country) VALUES
('99999999-1111-1111-1111-111111111111', 'Pearson Education', 'United States'),
('99999999-2222-2222-2222-222222222222', 'IEEE Computer Society', 'United States');

INSERT INTO subjects (id, subject_name) VALUES
('88888888-1111-1111-1111-111111111111', 'Artificial Intelligence'),
('88888888-2222-2222-2222-222222222222', 'Machine Learning'),
('88888888-3333-3333-3333-333333333333', 'Database Systems');

-- 7. MAP MANY-TO-MANY JUNCTIONS
INSERT INTO book_publishers (book_id, publisher_id) VALUES
('aaaaaaaa-1111-1111-1111-111111111111', '99999999-1111-1111-1111-111111111111');

INSERT INTO magazine_publishers (magazine_id, publisher_id) VALUES
('aaaaaaaa-2222-2222-2222-222222222222', '99999999-2222-2222-2222-222222222222');

INSERT INTO resource_subjects (resource_id, subject_id) VALUES
('aaaaaaaa-1111-1111-1111-111111111111', '88888888-1111-1111-1111-111111111111'),
('aaaaaaaa-1111-1111-1111-111111111111', '88888888-2222-2222-2222-222222222222'),
('aaaaaaaa-2222-2222-2222-222222222222', '88888888-1111-1111-1111-111111111111');

-- 8. PHYSICAL COPIES
INSERT INTO physical_copies (id, barcode, price, purchase_date, rack_number, copy_type) VALUES
('55555555-1111-1111-1111-111111111111', 'BC-AI-001-A', 450.00, '2024-05-10', 'Rack-C2', 'Book'),
('55555555-2222-2222-2222-222222222222', 'BC-AI-001-B', 450.00, '2024-05-10', 'Rack-C2', 'Book'),
('55555555-3333-3333-3333-333333333333', 'BC-MAG-041', 75.00, '2026-03-15', 'Rack-P1', 'Magazine');

INSERT INTO book_copies (id, book_id) VALUES
('55555555-1111-1111-1111-111111111111', 'aaaaaaaa-1111-1111-1111-111111111111');

INSERT INTO magazine_copies (id, magazine_id) VALUES
('55555555-3333-3333-3333-333333333333', 'aaaaaaaa-2222-2222-2222-222222222222');

-- 9. TRANSACTIONS: LIBRARY CARDS
INSERT INTO library_cards (id, card_number, student_id, category_id, activation_date, expiration_date, status) VALUES
('77777777-1111-1111-1111-111111111111', 'CARD-AHMAD-CS', '11111111-1111-1111-1111-111111111111', '00000000-1111-1111-1111-111111111111', '2025-09-01', '2029-06-30', 'Active'),
('77777777-2222-2222-2222-222222222222', 'CARD-FATIMA-EX', '44444444-4444-4444-4444-444444444444', '00000000-1111-1111-1111-111111111111', '2026-01-10', '2027-01-10', 'Active');

-- 10. TRANSACTIONS: LOANS & OVERDUE VERIFICATION
INSERT INTO loans (id, student_id, resource_id, copy_id, loan_date, due_date, return_date, status) VALUES
('66666666-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-1111-1111-111111111111', '55555555-1111-1111-1111-111111111111', '2026-05-15', '2026-05-30', NULL, 'Active'),
('66666666-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444444', 'aaaaaaaa-1111-1111-1111-111111111111', '55555555-2222-2222-2222-222222222222', '2026-04-01', '2026-04-16', NULL, 'Overdue');

-- 11. TRANSACTIONS: MAINTENANCE SCHEDULES
INSERT INTO maintenance_schedules (id, meeting_room_id, start_datetime, end_datetime, maintenance_type) VALUES
('bdbdbdbd-1111-1111-1111-111111111111', 'aaaaaaaa-4444-4444-4444-444444444444', '2026-06-01 09:00:00+04', '2026-06-01 12:00:00+04', 'Firmware Flash & Hardware Check');

-- 12. TRANSACTIONS: RESERVATIONS
INSERT INTO reservations (id, student_id, meeting_room_id, start_datetime, end_datetime, status, approved_by) VALUES
('ecececec-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-4444-4444-4444-444444444444', '2026-06-02 14:00:00+04', '2026-06-02 16:00:00+04', 'Approved', '22222222-2222-2222-2222-222222222222');