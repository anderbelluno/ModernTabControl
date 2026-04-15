# ModernTabControl

A fully customizable tab component for **Lazarus / Free Pascal**, with a modern look, dark theme support, and native integration with `TNotebook`.

---

## Overview

`TModernTabControl` is a drop-in replacement for the standard LCL `TPageControl`, built from scratch with its own rendering via `TCustomControl`. Every visual detail — colors, separators, accent bar, close button — is configurable through `published` properties, with no need for subclasses or hacks.

---

## Features

| Feature | Details |
|---|---|
| **Full color palette** | 10 color properties exposed in the Object Inspector |
| **Accent bar** | Colored indicator on the active tab |
| **Per-tab close button** | With highlight on mouse hover |
| **Drag & drop** | Reorder tabs by dragging |
| **Horizontal scroll** | `<` `>` buttons appear automatically when needed |
| **Per-tab tooltips** | Native `THintWindow`, set per tab via `SetTabHint` |
| **TNotebook integration** | Automatic page and active index synchronization |
| **Configurable separators** | Separator thickness and color between tabs |

---

## Properties

### Behavior

| Property | Type | Default | Description |
|---|---|---|---|
| `NoteBook` | `TNotebook` | `nil` | Notebook synchronized with the tabs |
| `ActiveTab` | `Integer` | `-1` | Index of the active tab |
| `TabHeight` | `Integer` | `36` | Tab bar height in pixels |
| `SepWidth` | `Integer` | `1` | Separator width between tabs (0 = no separator) |

### Colors

| Property | Default (Dark) | Description |
|---|---|---|
| `ColorBackground` | `#202020` | Tab bar background |
| `ColorTabInactive` | `#2D2D2D` | Inactive tab background |
| `ColorTabHover` | `#383838` | Hovered tab background |
| `ColorTabActive` | `#424242` | Active tab background |
| `ColorAccent` | `#CF6E27` | Accent bar on the active tab |
| `ColorTextInactive` | `#AAAAAA` | Inactive tab text |
| `ColorTextActive` | `#FFFFFF` | Active tab text |
| `ColorClose` | `#777777` | Close (X) icon on the active tab |
| `ColorCloseHover` | `#0055FF` | Close (X) icon on hover |
| `ColorSeparator` | `#444444` | Separator between tabs |

---

## Events

| Event | Signature | Description |
|---|---|---|
| `OnChange` | `TNotifyEvent` | Fired when the active tab changes |
| `OnCloseTab` | `(Sender; TabIndex; var CanClose)` | Allows canceling a tab close |
| `OnMoveTab` | `(Sender; OldIndex, NewIndex)` | Fired when tabs are reordered via drag |
| `OnAddTab` | `TNotifyEvent` | Fired when the `+` button is clicked |

---

## Public API

```pascal
// Adds a tab (returns its index)
function AddTab(const ACaption: string; const AHint: string = ''): Integer;

// Removes the tab at the specified index
procedure DeleteTab(Index: Integer);

// Removes all tabs
procedure Clear;

// Sets the tooltip for a specific tab
procedure SetTabHint(Index: Integer; const AHint: string);

// Access to individual tabs
property Tabs[Index: Integer]: TModernTab;  // read-only
property TabCount: Integer;                  // read-only
```

---

## Installation

1. Open Lazarus and go to **Package → Open Package File (.lpk)**
2. Select `ModernTabControl/moderncontrols.lpk`
3. Click **Compile** and then **Use → Install**
4. Confirm the IDE recompilation
5. The component will appear in the **Modern** palette

---

## Basic Usage

1. Add a `TNotebook` to your form
2. Add a `TModernTabControl` and set `Align = alTop`
3. Point the `NoteBook` property to the `TNotebook`
4. Tabs are automatically synchronized with the Notebook pages

```pascal
// Adding tabs at runtime
ModernTabControl1.AddTab('General');
ModernTabControl1.AddTab('Settings', 'Adjust system preferences');
ModernTabControl1.AddTab('About');

// Light theme at runtime
ModernTabControl1.ColorBackground   := clWhite;
ModernTabControl1.ColorTabInactive  := $00F0F0F0;
ModernTabControl1.ColorTabActive    := clWhite;
ModernTabControl1.ColorTextInactive := clGray;
ModernTabControl1.ColorTextActive   := clBlack;
ModernTabControl1.ColorAccent       := clBlue;
```

---

## Requirements

- Lazarus 2.x or higher
- Free Pascal 3.x or higher
- Platforms: Windows, Linux, macOS (via LCL)

---

## License

MIT — free to use, modify, and distribute.
