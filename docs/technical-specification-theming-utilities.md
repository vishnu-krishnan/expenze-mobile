# Technical Specification - Dark Mode & Utility Suite

### System overview
Implementation of a system-wide theme management service and a local database-backed utility suite for user notes and reminders.

### Architecture diagram (ASCII)
```
[ Screens (Dashboard, Notes API, etc) ]
        |             |
[ ThemeProvider ] [ NoteProvider ]
        |             |
[ SharedPreferences ] [ SQLite (notes table) ]
```

### Component breakdown
- **ThemeProvider**: Manages `isDarkMode` state and persists to `SharedPreferences`.
- **AppTheme**: Contains `lightTheme` and `darkTheme` `ThemeData` with matching background decorations.
- **Note**: Domain model for utility items.
- **notes_screen**: High-performance list view with modal creation flow.
- **DatabaseHelper (v7)**: includes `notes` table for persistence.

### Data flow
1. User interacting with UI triggers `Provider` methods.
2. `Provider` performs async I/O with SQLite/SharedPreferences.
3. `Provider` notifies listeners.
4. UI rebuilds with fresh data/styles.

### API contracts
Local Provider API:
- `loadNotes()`: Fetches all notes sorted by pin status and date.
- `addNote(title, content, date)`: Persists new entry.
- `toggleTheme()`: Flips boolean and updates persistence.

### Validation rules
- Note title can be empty if content exists (and vice-versa).
- Reminder date must be in the future.
- Max 1000 characters per note (soft limit).

### Error handling
- Persistence failures logged via `debugPrint`.
- UI handles empty states gracefully with vector/icon-based fallbacks.

### Schema changes
**Table: notes**
- `id`: INTEGER PRIMARY KEY
- `title`: TEXT
- `content`: TEXT
- `reminder_date`: TEXT (ISO8601)
- `is_reminder_active`: INTEGER
- `is_pinned`: INTEGER
- `color`: TEXT
- `created_at`: TEXT
- `updated_at`: TEXT

### Security model
- Local-only storage for notes (**Privacy by design**).
- No external sync for notes in this phase.

### Performance analysis
- SQLite indexing on `updated_at` and `is_pinned` ensures efficient access.
- Memory usage for themes is negligible (<1MB).

### Deployment plan
- Database migration (v7) handles table creation on app launch.
- `ThemeProvider` initializes from startup preferences.

### Rollback plan
- Delete `notes` table if corruption occurs.
- Reset `isDarkMode` flag to false in `SharedPreferences`.

Date: 2026-02-16
