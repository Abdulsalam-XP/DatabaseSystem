# AGENTS.md

## Project Overview

University Library Management System — a pure SQL (PostgreSQL) database project with DDL schema (`Deliverable_2.sql`) and DML seed data (`Deliverable_3.sql`). No application layer (no frontend/backend).

## Cursor Cloud specific instructions

### Database

- **RDBMS**: PostgreSQL 16 (required — uses `pgcrypto`, `gen_random_uuid()`, PL/pgSQL triggers, `TIMESTAMPTZ`, PostgreSQL role system).
- **Database name**: `library_db`
- **Start PostgreSQL**: `sudo pg_ctlcluster 16 main start`
- **Connect**: `sudo -u postgres psql -d library_db`

### Running the SQL files

Run in order (DDL first, then DML):
```
sudo -u postgres psql -d library_db -f /workspace/Deliverable_2.sql
sudo -u postgres psql -d library_db -f /workspace/Deliverable_3.sql
```

Both scripts are idempotent (`CREATE TABLE IF NOT EXISTS`, `CREATE OR REPLACE`), but DML inserts use fixed UUIDs so re-running `Deliverable_3.sql` on an already-populated database will fail with duplicate key errors. To reset, drop and recreate the database:
```
sudo -u postgres psql -c "DROP DATABASE IF EXISTS library_db;"
sudo -u postgres psql -c "CREATE DATABASE library_db;"
```

### Known data note

`Deliverable_3.sql` inserts two Book-type physical copies but only registers one in `book_copies`. The second copy (`55555555-2222-2222-2222-222222222222`) is missing from `book_copies`, which causes the `overdue_inventory_view` to miss the overdue loan for student EXT-2026-099.

### Key verification queries

- **Overdue view**: `SELECT * FROM overdue_inventory_view;`
- **Trigger test** (should fail with maintenance overlap error):
  ```sql
  INSERT INTO reservations (student_id, meeting_room_id, start_datetime, end_datetime, status)
  VALUES ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-4444-4444-4444-444444444444',
          '2026-06-01 10:00:00+04', '2026-06-01 11:00:00+04', 'Pending');
  ```
- **DB roles**: `SELECT rolname FROM pg_roles WHERE rolname IN ('librarian_role', 'student_role');`
