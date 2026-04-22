# BUH1 — Project Documentation

## Overview

**BUH1** is a multi-tenant accounting and bookkeeping web application built with Perl and the Mojolicious web framework. It is designed for small-to-medium businesses, particularly in the Uzbekistan market (supports Uzbek/Russian multilingual content and local regulatory import formats from LEX.uz and NORMA).

Author: M. Nurullaev <maksud.nurullaev@gmail.com>
Repository: https://github.com/maksudnurullaev/buh1

---

## Technology Stack

| Layer        | Technology                                     |
|---|---|
| Language     | Perl 5                                         |
| Web Framework| Mojolicious                                    |
| Database     | SQLite (via DBI + DBD::SQLite)                 |
| Templates    | Embedded Perl (`.html.ep`)                     |
| Auth         | SHA-512 salted hashes (`Crypt::SaltedHash`)    |
| Bot          | Telegram Bot API (`WWW::Telegram::BotAPI`)     |
| Caching      | CHI                                            |
| Excel export | `Spreadsheet::WriteExcel`                      |
| CSV          | `Text::CSV_XS`                                 |
| Event loop   | EV                                             |

---

## Running the Application

**Development (auto-reload on file change):**
```bash
morbo -m production ./script/buh1 -l http://127.0.0.1:9000
# or use the helper script:
./start.script
```

**Production (hypnotoad):**
```bash
hypnotoad ./script/buh1
# Listens on http://*:3000
```

**Environment variables:**

| Variable               | Default       | Description                                    |
|---|---|---|
| `MOJO_MODE`            | `development` | Set to `production` for production mode        |
| `BUH1_SECRETS`         | (hardcoded)   | Comma-separated session signing secrets        |
| `MOJO_MAX_MESSAGE_SIZE`| `104857600`   | Max upload size in bytes (default 100MB)       |

---

## Installing Dependencies

```bash
# Install all runtime dependencies:
cpanm Mojolicious Crypt::SaltedHash Data::UUID DBI DBD::SQLite List::MoreUtils \
    Hash::Merge::Simple Locale::Currency::Format Mojolicious::Plugin::RenderFile \
    Text::CSV_XS Test::Most Test::Deep Test::NoWarnings CHI EV \
    Spreadsheet::WriteExcel WWW::Telegram::BotAPI \
    Mojolicious::Plugin::AdditionalValidationChecks

# Or via cpm:
cpm install -g

# Install test dependency (to local user dir if no root):
cpanm --local-lib=~/perl5 Test::Mojo::Session
```

---

## Running Tests

```bash
# From the project root — .proverc auto-applies -I lib and local perl5 path:
prove -r t/

# Or explicitly:
prove -I lib -r t/
```

A `.proverc` file in the project root configures `prove` automatically. Tests live under `t/` organized by category:

| Directory          | Coverage                                 |
|---|---|
| `t/database/`      | Db.pm core operations, SQL, links        |
| `t/mojo/`          | Mojolicious app startup, utilities       |
| `t/utils/`         | Auth, caching, date formatting, ML, user |
| `t/unused/`        | Legacy / disabled tests                  |

---

## Project Structure

```
buh1/
├── script/buh1              # Entry point — sets env, starts Mojolicious
├── lib/
│   ├── Buh1.pm              # Main app: startup, routes (~250+ routes)
│   ├── Auth.pm              # Login, password hashing (SHA-512 salted)
│   ├── Db.pm                # Database abstraction layer (SQLite EAV)
│   ├── DbClient.pm          # Per-company database client utilities
│   ├── Utils.pm             # General utilities (trimming, date, caching)
│   ├── ML.pm                # i18n / multilingual support
│   ├── Buh1/                # Controllers (22 modules)
│   ├── Utils/               # Utility modules (20 modules)
│   ├── Tests/               # Test helper modules
│   └── Mojolicious/Plugin/  # HTMLTags custom plugin
├── db/
│   ├── main.db              # Main SQLite database (users, companies, config)
│   ├── backup.db            # Backup copy of main.db
│   └── clients/             # Per-company SQLite databases (one file each)
├── config/
│   ├── admin.login          # Hashed admin password (auto-created, default: 'admin')
│   ├── accounts_lex.txt     # LEX.uz chart of accounts reference (29 KB)
│   └── accounts_sasol.txt   # Alternative chart of accounts (39 KB)
├── templates/               # Embedded Perl templates (~25 feature dirs)
├── public/                  # Static assets (CSS, images)
├── t/                       # Test suite
├── cpm.yml                  # Dependency manifest
├── .proverc                 # prove configuration (-I lib)
├── start.script             # Quick dev-mode start command
├── TIPS.txt                 # Developer tips and useful SQL/commands
└── TODO.txt                 # Feature roadmap
```

---

## Controllers (`lib/Buh1/`)

| Module            | Responsibility                                          |
|---|---|
| `User.pm`         | Login, logout, password change                          |
| `Users.pm`        | User list, add, edit, delete, restore                   |
| `Companies.pm`    | Multi-tenant company management                         |
| `Accounts.pm`     | Chart of accounts                                       |
| `Operations.pm`   | Financial transactions / journal entries                |
| `Documents.pm`    | Business documents (invoices, etc.)                     |
| `Warehouse.pm`    | Inventory and stock management                          |
| `Catalog.pm`      | Product / service catalog                               |
| `Tbalance.pm`     | Trial balance reports                                   |
| `Calculations.pm` | Financial calculations                                  |
| `Templates.pm`    | Document template management                            |
| `Imports.pm`      | Data imports (LEX.uz, NORMA formats)                    |
| `Guides.pm`       | Built-in help / guide system                            |
| `Feedbacks.pm`    | User feedback collection                                |
| `TBot.pm`         | Telegram bot integration                                |
| `Database.pm`     | Database administration UI                              |
| `Filter.pm`       | Search and filter state                                 |
| `Files.pm`        | File upload / download                                  |
| `Backup.pm`       | Database backup and restore                             |
| `Desktop.pm`      | Company dashboard                                       |
| `Initial.pm`      | Welcome page and language selection                     |
| `Browser.pm`      | Mobile browser utilities                                |

---

## Database Design

All data is stored in a single **EAV (Entity-Attribute-Value)** table:

```sql
CREATE TABLE objects (
    name  TEXT,                  -- entity type: 'user', 'account', 'document', …
    id    TEXT,                  -- UUID for the entity
    field TEXT,                  -- attribute name
    value TEXT COLLATE NOCASE    -- attribute value
);
CREATE INDEX i_objects ON objects (name, id, field COLLATE NOCASE);
```

### Entity types stored in `objects`:

| name        | Description                                    |
|---|---|
| `user`      | User accounts (email, password, rights)        |
| `company`   | Tenant companies                               |
| `account`   | Chart of accounts entries                      |
| `operation` | Financial transactions                         |
| `document`  | Business documents                             |
| `catalog`   | Products / services                            |
| `warehouse` | Inventory items                                |
| `template`  | Document templates                             |
| `guide`     | Help content                                   |
| `feedback`  | User feedback                                  |
| `_link_`    | Many-to-many relationships between entities    |

### Multi-tenancy

Each company gets its own SQLite database file at `db/clients/<company_id>.db` with the same schema. The main `db/main.db` holds global data: users, companies, admin config.

### Database utilities

```bash
# Dump main db to gzipped SQL:
echo '.dump' | sqlite3 db/main.db | gzip -c > db/dump/main.db.dump.gz

# Restore:
zcat db/dump/main.db.dump.gz | sqlite3 db/main.db

# Find DB anomalies (duplicate EAV rows):
select count(*) as cnt, name, id, field
  from objects
  group by name, id, field
  HAVING COUNT(*) > 1 and name <> '_link_';
```

---

## Key Features

- **Multi-tenant**: each company is fully isolated in its own database file
- **Chart of accounts**: configurable with LEX.uz and NORMA reference imports
- **Financial documents**: invoices, journal entries, trial balance
- **Warehouse / inventory**: stock tracking, Excel exports
- **File attachments**: upload/download per document, catalog item, or warehouse entry
- **Telegram bot**: notifications via webhook
- **Multilingual**: i18n via `ML.pm` (Russian / Uzbek)
- **Auto-recovery**: main DB and per-company DBs are auto-initialized if missing
- **Backup/restore**: built-in archive and restore via the admin UI

---

## Security Notes

- **Session secrets**: set `BUH1_SECRETS` env var (comma-separated) to override defaults
- **App mode**: set `MOJO_MODE=production` for production deployments
- **Upload limit**: `MOJO_MAX_MESSAGE_SIZE` defaults to 100 MB (was 1 GB)
- **SQL injection**: all database queries in `Db.pm` use parameterized statements (`?` placeholders or `$dbh->quote()`) — no raw string interpolation in SQL
- **Admin password**: stored as SSHA512 hash in `config/admin.login`; default password is `admin` — **change immediately in production**
