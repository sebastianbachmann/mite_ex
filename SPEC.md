# elixir-mite

A TUI application for interacting with the [mite.de](https://mite.de) time tracking API.

## Overview

elixir-mite is a terminal user interface application built with Elixir that allows users to manage their time tracking workflow directly from the command line. It provides a rich, interactive interface for creating projects, customers, tracking time, and managing resources in mite.de.

## Technology Stack

### TUI Framework
- **[ExRatatui](https://hex.pm/packages/ex_ratatui)** - Elixir bindings for the Rust [ratatui](https://ratatui.rs) library via precompiled NIFs. LiveView-inspired `App` behaviour, 16 built-in widgets, OTP-supervised, non-blocking event polling on BEAM's DirtyIo scheduler. No Rust toolchain required. Note: `ratatouille` (the pure-Elixir alternative) is broken on Python 3.12+ due to its C build dependency.

### HTTP Client
- **[Req](https://hex.pm/packages/req)** - A batteries-included HTTP client for Elixir by Wojtek Mach (creator of Livebook). Built-in JSON encoding, retry logic, and simpler API than alternatives. 1300+ GitHub stars.

### Configuration
- **[TOML](https://hex.pm/packages/toml)** - For reading config files (credentials, preferences).

## Architecture

```
lib/
├── elixir_mite/
│   ├── application.ex          # OTP Application
│   ├── api/
│   │   ├── client.ex           # Req client with auth
│   │   ├── customers.ex        # Customer endpoints
│   │   ├── projects.ex         # Project endpoints
│   │   ├── services.ex         # Service (billing unit) endpoints
│   │   ├── time_entries.ex     # Time entry endpoints
│   │   └── tracker.ex          # Live tracker endpoints
│   ├── config/
│   │   └── loader.ex           # Config file loading
│   └── tui/
│       ├── app.ex              # Main TUI application (Ratatouille)
│       ├── views/
│       │   ├── layout.ex       # Common layout components
│       │   ├── dashboard.ex    # Main dashboard view
│       │   ├── time_entry.ex   # Time entry list/create view
│       │   ├── projects.ex     # Project management view
│       │   ├── customers.ex    # Customer management view
│       │   └── tracker.ex      # Active tracker widget
│       └── components/
│           ├── table.ex         # Reusable table component
│           ├── form.ex         # Input form component
│           └── status_bar.ex   # Bottom status bar
└── mix.exs
```

## API Integration

### Base URL
```
https://{account_name}.mite.de
```

### Authentication
- API key passed via `X-MiteApiKey` header
- Account name extracted from config

### Endpoints to Implement

| Resource | Endpoint | Methods |
|----------|----------|---------|
| Account | `/account.json` | GET |
| Customers | `/customers.json` | GET, POST, PATCH, DELETE |
| Projects | `/projects.json` | GET, POST, PATCH, DELETE |
| Services | `/services.json` | GET, POST, PATCH, DELETE |
| Time Entries | `/time_entries.json` | GET, POST, PATCH, DELETE |
| Tracker | `/tracker.json` | GET, POST, DELETE |
| Bookmarks | `/bookmarks.json` | GET, POST, DELETE |
| Users | `/users.json` | GET |
| Changes | `/changes.json` | GET |

## Features

### Core Features (MVP)
1. **Dashboard** - Overview of today's tracked time, active tracker status
2. **Time Tracking** - Start/stop timer, create/edit time entries
3. **Project Management** - List, create, edit, archive projects
4. **Customer Management** - List, create, edit customers
5. **Service Management** - List, create, edit billing units

### Configuration
- Config file: `~/.config/elixir-mite/config.toml`
- Config structure:
```toml
[account]
name = "your_account"
api_key = "your_api_key"
```

### Keybindings
- `j/k` or `↑/↓` - Navigate lists
- `Enter` - Select/Open
- `n` - New (create resource)
- `e` - Edit selected resource
- `d` - Delete (with confirmation)
- `t` - Toggle time tracker
- `q` or `Esc` - Quit/Back
- `/` - Search/Filter
- `r` - Refresh data
- `?` - Help overlay

## Data Models

### Customer
```elixir
%{
  id: integer,
  name: string,
  archived: boolean,
  created_at: datetime,
  updated_at: datetime
}
```

### Project
```elixir
%{
  id: integer,
  customer_id: integer | nil,
  name: string,
  budget: float | nil,
  archived: boolean,
  created_at: datetime,
  updated_at: datetime
}
```

### Service
```elixir
%{
  id: integer,
  name: string,
  hourly_rate: float | nil,
  billable: boolean,
  created_at: datetime,
  updated_at: datetime
}
```

### TimeEntry
```elixir
%{
  id: integer,
  project_id: integer,
  service_id: integer | nil,
  user_id: integer,
  date: date,
  minutes: integer,
  note: string,
  created_at: datetime,
  updated_at: datetime
}
```

### Tracker
```elixir
%{
  id: integer,
  project_id: integer,
  service_id: integer | nil,
  user_id: integer,
  started_at: datetime,
  note: string
}
```

## Error Handling

- Display API errors in status bar
- Offline detection with retry option
- Request timeout: 10 seconds
- Rate limiting awareness

## Development

### Dependencies
```elixir
def deps do
  [
    {:ex_ratatui, "~> 0.5"},    # TUI framework (precompiled Rust NIF)
    {:req, "~> 0.5"},            # Batteries-included HTTP client
    {:jason, "~> 1.4"},          # JSON parsing (Req uses Jason by default)
    {:toml, "~> 0.7"},          # Config file parsing
    {:tzdata, "~> 1.1"}         # Timezone support
  ]
end
```

### Running
```bash
mix deps.get
mix run --no-halt
```

### Testing
```bash
mix test
```

## TODO

- [ ] Project scaffolding and mix.exs setup
- [ ] Config loader implementation
- [ ] Tesla API client with auth middleware
- [ ] All API resource modules
- [ ] TUI Application structure
- [ ] Dashboard view
- [ ] Time entry views (list, create, edit)
- [ ] Project management views
- [ ] Customer management views
- [ ] Service management views
- [ ] Active tracker widget
- [ ] Keyboard navigation
- [ ] Search/filter functionality
- [ ] Error handling and status feedback
- [ ] Tests
