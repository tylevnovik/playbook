# Multi-Platform Role-Playing LLM App — Design Spec

## Overview

A feature-rich, cross-platform role-playing application powered by LLMs. Single Flutter codebase targeting Web, Windows, and Android with a beautiful Material Design 3 interface.

## Goals

1. **Universal LLM Support** — OpenAI, Anthropic, Gemini API formats via unified abstraction
2. **Rich Role-Playing** — Character cards, world books, tree-structured dialogues
3. **Beautiful UI** — Material Design 3, switchable themes, responsive across platforms
4. **Local-First** — All data stored locally, cloud sync as future placeholder
5. **SillyTavern Compatible** — Import/export SillyTavern JSON character cards

## Non-Goals (Placeholders)

- TTS (Text-to-Speech)
- AI Image Generation
- Cloud Sync / Proxy Server
- Plugin System

---

## Architecture

### Pattern: Clean Architecture + BLoC

```
lib/
├── core/
│   ├── constants/
│   ├── error/              # Failure classes, error handling
│   ├── theme/              # Material 3 theme (light/dark/custom)
│   ├── utils/              # Helpers, formatters
│   └── di/                 # Dependency injection (GetIt + injectable)
│
├── data/
│   ├── datasources/
│   │   ├── local/          # SQLite (sqflite) for structured data
│   │   └── remote/         # LLM API clients
│   ├── models/             # JSON-serializable data models
│   └── repositories/       # Repository implementations
│
├── domain/
│   ├── entities/           # Business entities (Character, Chat, WorldBook)
│   ├── repositories/       # Abstract repository interfaces
│   └── usecases/           # Use cases (SendMessage, LoadCharacter, etc.)
│
├── presentation/
│   ├── common/             # Shared widgets (chat bubble, input box, sidebar)
│   └── features/
│       ├── home/           # Character list grid
│       ├── character/      # Character card editor
│       ├── chat/           # Chat interface
│       ├── worldbook/      # World book manager
│       ├── settings/       # Settings (API keys, themes, user profile)
│       └── splash/         # Splash screen
│
└── app.dart                # MaterialApp entry point
```

### Dependency Injection

- **GetIt** + **injectable** for service location
- All dependencies registered at startup
- Easy to swap implementations (e.g., SQLite → Hive)

---

## Feature Modules

### 1. Home — Character List

**Screen:** Grid of character cards with avatar, name, last chat time.

- Search bar at top
- Tag-based filtering
- FAB (Floating Action Button) to create new character
- Long-press context menu: Edit / Delete / Export / Duplicate
- Sort by: last chatted / name / created date

### 2. Character Card Editor

**Screen:** Form-based editor matching SillyTavern JSON schema.

**Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Character name |
| avatar | image | No | Local file or URL |
| description | text | Yes | Character persona/backstory |
| greeting | text | Yes | First message on new chat |
| example_messages | text | No | Example dialogue pairs |
| system_prompt | text | No | System-level instructions |
| tags | list | No | Category tags |
| world_book | ref | No | Linked world book ID |

**Actions:**
- Import JSON (SillyTavern format)
- Export JSON
- Save / Cancel

### 3. Chat Interface

**Layout:**
```
┌─────────────────────────────────────────────┐
│ [Avatar] Character Name     [Settings] [≡]  │
├─────────────────────────────────────────────┤
│                                             │
│  [Character] Hello, traveler...             │
│                                             │
│  [User] Hi there!                           │
│                                             │
│  [Character] *smiles* Welcome to...         │
│                                             │
├─────────────────────────────────────────────┤
│ [📎] [Input message here...] [Send ▶]       │
└─────────────────────────────────────────────┘
```

**Features:**
- **Markdown Rendering** — Code blocks, tables, bold/italic, lists
- **Variable Substitution** — `{{user}}` → username, `{{char}}` → character name
- **Streaming Output** — Typewriter effect via SSE/Stream
- **Tree Dialogues** — Branching conversation paths
  - Each message has a parent pointer
  - Visual indicator for branches
  - Swipe/click to switch between branches
  - "Regenerate" creates a new branch at current point
- **Multi-modal Input** — Image attachment (base64 for Gemini/GPT-4o)
- **Auto-Summary** — When context exceeds threshold:
  1. Summarize old messages via LLM
  2. Inject summary as system message
  3. Keep recent N messages in full
- **Drawer (Right Side):**
  - Temperature slider
  - Max tokens input
  - System prompt override
  - Context window usage indicator

### 4. World Book / Knowledge Base

**Screen:** List of world book entries grouped by category.

**Entry Schema:**
| Field | Type | Description |
|-------|------|-------------|
| name | string | Entry name |
| keywords | list | Trigger words |
| content | text | Injected content |
| category | string | Group (world, character, location, etc.) |
| priority | int | Injection order |
| enabled | bool | Toggle on/off |

**Behavior:**
- When user message matches any keyword → inject entry content into context
- Entries injected before character description in prompt
- Priority determines order of injection
- Supports binding to specific characters

### 5. Settings

**Sections:**

**API Configuration:**
- OpenAI: API Key, Base URL (for compatible APIs), Model selection
- Anthropic: API Key, Model selection
- Gemini: API Key, Model selection
- Default provider selector

**Appearance:**
- Theme: Light / Dark / System / Custom
- Custom theme: Primary color, secondary color, background color
- Font size slider
- Chat bubble style selector

**Profile:**
- Username (for `{{user}}` replacement)
- User avatar (optional)

**Data:**
- Export all data (JSON)
- Import data (JSON)
- Clear all data (with confirmation)

**About:**
- Version info
- Open source licenses

---

## LLM Integration Layer

### Unified Provider Interface

```dart
abstract class LlmProvider {
  /// Non-streaming send
  Future<ChatResponse> sendMessage({
    required List<ChatMessage> messages,
    required LlmConfig config,
    List<Attachment>? attachments,
  });

  /// Streaming send (SSE)
  Stream<ChatChunk> streamMessage({
    required List<ChatMessage> messages,
    required LlmConfig config,
    List<Attachment>? attachments,
  });
}
```

### Implementations

| Provider | API Format | Base URL | Models |
|----------|-----------|----------|--------|
| OpenAIProvider | OpenAI Chat Completions | Configurable | GPT-4o, GPT-4, GPT-3.5 |
| AnthropicProvider | Anthropic Messages | api.anthropic.com | Claude 3.5 Sonnet, Claude 3 Opus |
| GeminiProvider | Gemini GenerateContent | generativelanguage.googleapis.com | Gemini 1.5 Pro, Gemini 1.5 Flash |

### Prompt Construction Pipeline

```
[System Prompt (from settings)]
  +
[World Book entries (keyword-matched)]
  +
[Character Description]
  +
[Auto-summary (if context too long)]
  +
[Example Messages (first chat only)]
  +
[Greeting]
  +
[Recent Messages]
  +
[User Input]
```

### Token Management

- Track token usage per message (estimated)
- Configurable context window size per model
- When approaching limit:
  1. Trigger auto-summarization
  2. Drop oldest non-summary messages
  3. Always keep: system prompt + character description + summary + last N messages

---

## Data Storage

### SQLite Schema

**characters**
- id (UUID, PK)
- name, avatar_path, description, greeting, example_messages
- system_prompt, tags (JSON array)
- world_book_id (FK, nullable)
- created_at, updated_at, last_chatted_at

**chats**
- id (UUID, PK)
- character_id (FK)
- created_at, updated_at

**messages**
- id (UUID, PK)
- chat_id (FK)
- parent_id (self-FK, nullable — for tree structure)
- role (user/assistant/system)
- content (text)
- attachments (JSON, nullable)
- tokens_used (int, nullable)
- created_at

**world_books**
- id (UUID, PK)
- name, description
- created_at, updated_at

**world_book_entries**
- id (UUID, PK)
- world_book_id (FK)
- name, keywords (JSON array), content
- category, priority, enabled
- created_at, updated_at

**settings**
- key (PK)
- value (text)

---

## Theme System

### Material Design 3 Integration

- Use `ThemeData` with `ColorScheme.fromSeed()`
- Built-in themes:
  - **Light** — Clean white/blue
  - **Dark** — AMOLED black/purple
  - **System** — Follow OS preference
- **Custom Theme:**
  - User picks primary color
  - Auto-generate color scheme via `ColorScheme.fromSeed()`
  - Save as named theme

### Chat Bubble Styling

- User messages: Right-aligned, primary color background
- Character messages: Left-aligned, surface color with avatar
- System messages: Centered, muted text
- Support for custom bubble shapes (rounded, flat, etc.)

---

## Platform-Specific Considerations

### Web
- Use `sqflite_common_ffi_web` for SQLite
- File picker for avatar import
- Responsive layout (sidebar collapses on narrow screens)

### Windows
- Native window title bar customization
- System tray support (future)
- File system paths for data storage

### Android
- Material You dynamic color (optional)
- Back gesture handling
- Notification support (future)

---

## Dependencies

| Package | Purpose |
|---------|---------|
| flutter_bloc | State management |
| get_it + injectable | Dependency injection |
| sqflite + sqflite_common_ffi | Local database |
| http / dio | HTTP client |
| json_serializable | JSON serialization |
| go_router | Navigation |
| flutter_markdown | Markdown rendering |
| image_picker | Avatar/attachment selection |
| file_picker | File import/export |
| path_provider | Platform file paths |
| uuid | ID generation |
| google_fonts | Custom fonts |
| dynamic_color | Material You colors |
| shared_preferences | Simple key-value storage |

---

## Prompt Engineering Details

### System Prompt Template

```
You are {{char}}. Stay in character at all times.

## Character Description
{{character.description}}

## World Context
{{world_book_entries}}

## Rules
- Never break character
- Never refer to yourself as an AI or language model
- Respond as {{char}} would, based on the character description
- Use * for actions, " for dialogue
- Keep responses engaging and in-character
```

### Memory Management Strategy

1. **Short-term** — Last 20 messages kept in full
2. **Working Memory** — Auto-summary of messages 21+
3. **Long-term** — Character description + world book always present
4. **Context Budget:**
   - System prompt: ~500 tokens (fixed)
   - World book: ~1000 tokens (variable)
   - Character desc: ~500 tokens (fixed)
   - Summary: ~300 tokens
   - Recent messages: ~3000 tokens
   - Reserve for response: ~1000 tokens
   - **Total target: ~6000-8000 tokens** (adjustable per model)

### Auto-Summary Prompt

```
Summarize the following conversation in 3-5 sentences, preserving key facts, 
emotional developments, and ongoing storylines:

{{messages_to_summarize}}
```

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| API Key invalid | Show error dialog, link to settings |
| Rate limited | Exponential backoff, show "retrying..." |
| Network offline | Queue message, show offline indicator |
| Context too long | Auto-summarize and retry |
| API format error | Show raw error, offer to report |
| File import fails | Show specific validation errors |

---

## Testing Strategy

- **Unit Tests** — Repository logic, prompt construction, token counting
- **Widget Tests** — Chat bubble rendering, form validation
- **Integration Tests** — LLM provider mocking, database CRUD
- **Golden Tests** — Theme rendering across platforms

---

## Future Placeholders

| Feature | Status |
|---------|--------|
| TTS | Interface defined, no implementation |
| Image Generation | Interface defined, no implementation |
| Cloud Sync | Data export/import ready, sync protocol TBD |
| Proxy Server | Client-side only for now |
| Plugin System | Not planned |
