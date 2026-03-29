# AGENTS.md

Agentic coding guidelines for the elixir-mite repository.

## Project Overview

Elixir TUI application for mite.de time tracking using ExRatatui.

## Build / Lint / Test Commands

```bash
# Install dependencies
mix deps.get

# Compile
mix compile

# Run all tests
mix test

# Run a single test file
mix test test/elixir_mite_test.exs

# Run a single test by line number
mix test test/elixir_mite_test.exs:5

# Format code
mix format

# Check formatting
mix format --check-formatted

# Run the application
mix run --no-halt
```

## Code Style Guidelines

### Module Structure

- Use `defmodule ElixirMite.ModuleName` naming convention
- Always include `@moduledoc` with brief module description
- Group related aliases at the top using multi-alias syntax:
  ```elixir
  alias ElixirMite.API.{Client, Customers, Tracker, TimeEntries}
  alias ExRatatui.{Layout, Style}
  alias ExRatatui.Widgets.{Block, List, Paragraph}
  ```

### Functions

- Use `def` for public functions, `defp` for private
- Keep function bodies concise; extract complex logic to private functions
- Use descriptive parameter names (e.g., `customer` not `c`)
- Prefer pattern matching in function heads over conditional logic
- Use the `with` statement for multiple potentially failing operations
- Private helper functions should end with descriptive suffixes (e.g., `render_*`, `fetch_*`, `handle_*`)

### Naming Conventions

- **Modules**: PascalCase (e.g., `TimeEntries`, `Config.Loader`)
- **Functions**: snake_case (e.g., `render_dashboard`, `fetch_customers`)
- **Variables**: snake_case (e.g., `time_entries`, `customer_name`)
- **Module attributes**: `@screaming_snake_case` for constants
- **Private functions**: Same naming as public, just marked with `defp`

### Error Handling

- Use `{:ok, result}` / `{:error, reason}` tuples consistently
- Provide `!` variants that raise for critical failures (e.g., `load!/0`)
- Pattern match on API responses with status codes:
  ```elixir
  {:ok, %{status: 200, body: body}} -> body
  {:ok, %{status: _, body: %{"error" => msg}}} -> {:error, msg}
  _ -> {:error, "API request failed"}
  ```
- Store error messages in state as strings for display: `error: "Config error: #{reason}"`

### Types and Specs

- No dialyzer/type specs currently used
- Keep data shapes simple; use maps with string keys for API responses
- Use pattern matching to validate data structure over formal types

### Formatting

- Max line length: follow Elixir default (98 chars)
- Use parentheses for function calls with arguments: `Client.new(name, api_key)`
- Omit parentheses for zero-arity calls in pipelines
- Use the pipe operator `|>` for multi-step transformations
- Indent with 2 spaces, no tabs

### Imports and Dependencies

- Prefer `alias` over `import`
- Group aliases: project modules first, then library modules, then external deps
- Avoid `use` except for behaviors (e.g., `use ExRatatui.App`)
- Keep dependencies minimal; this project uses: `ex_ratatui`, `req`, `jason`, `toml`, `tzdata`

### Testing

- Tests use ExUnit with `use ExUnit.Case`
- Place tests in `test/` directory with `_test.exs` suffix
- Tests are run via `mix test`

### Documentation

- Use `@moduledoc` for every module
- Use `@doc` sparingly for complex public functions
- Include usage examples in moduledoc for config/loader modules
