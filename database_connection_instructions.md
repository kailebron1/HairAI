# Database Connection Setup for Cursor

## Prerequisites
✅ PostgreSQL extension installed in Cursor
✅ Supabase database password obtained

## Connection Details
- **Host**: `db.whybphphnjchcbnuxeph.supabase.co`
- **Port**: `5432`
- **Database**: `postgres`
- **Username**: `postgres`
- **Password**: `[Your Supabase Database Password]`
- **SSL**: `Required`

## Setup Steps

### 1. Update Connection Password
1. Open `.vscode/settings.json`
2. Replace `YOUR_DATABASE_PASSWORD_HERE` with your actual Supabase database password
3. Save the file

### 2. Connect via PostgreSQL Extension
1. Open Command Palette (Cmd+Shift+P)
2. Type: `PostgreSQL: New Connection`
3. Select your configured connection: "Supabase - HairStyle AI"
4. Enter password when prompted

### 3. Alternative: Manual Connection
If the settings.json method doesn't work, connect manually:
1. Command Palette → `PostgreSQL: New Connection`
2. Enter connection details:
   - Host: `db.whybphphnjchcbnuxeph.supabase.co`
   - Port: `5432`
   - Database: `postgres`
   - Username: `postgres`
   - Password: `[Your Database Password]`
   - SSL: `Require`

## Usage

### Running SQL Files
1. Open any `.sql` file in your project
2. Right-click → `Run SQL Query`
3. Or use Command Palette → `PostgreSQL: Run Query`

### Quick Database Operations
- **View Tables**: Command Palette → `PostgreSQL: Show Tables`
- **Run Query**: Command Palette → `PostgreSQL: Run Query`
- **Export Results**: Right-click query results → `Export`

## Ready-to-Run SQL Files
- `fix_gallery_images.sql` - Fix your current gallery image issue
- `debug_card_images.sql` - Debug both card and gallery images
- `debug_database.sql` - General database debugging

## Security Note
⚠️ The `.vscode/settings.json` file contains your database password. 
Make sure this file is in your `.gitignore` to avoid committing passwords to version control. 