# Discrete Math Escape Room

A 2D top-down educational game built with Godot 4.5 that teaches discrete mathematics concepts through interactive puzzles.

## Overview

This game combines traditional escape room mechanics with discrete mathematics education. Players navigate through multiple rooms solving logic-based puzzles including affine ciphers, truth tables, and set theory problems. The game features a health system where incorrect puzzle attempts result in losing hearts.

## Game Features

- Top-down 2D exploration with WASD/arrow key movement
- Three distinct mini-game puzzles based on discrete math concepts
- Health system with visual heart display
- Dialog system for hints and story elements
- Room transition system with multiple levels
- Pause menu and main menu
- Win condition tracking all puzzle completions

## Puzzles

### 1. Affine Cipher Game
Players decrypt messages using the affine cipher formula: D(x) = a^(-1) * (x - b) mod 26
- 15 unique puzzles with randomized selection
- Limited attempts (3 per puzzle)
- Persistent state across game sessions

### 2. Truth Table Puzzle
Complete truth tables for logical operators including NOT, AND, OR, implication, and equivalence
- 5 different question variations
- Pre-filled cells as hints
- 3 attempts allowed

### 3. Set Theory Puzzle
Find intersection elements (A intersect B) in a coordinate grid system
- 3 rounds per game
- Grid-based cell selection interface
- Limited total attempts

## Game Structure

### Main Components

**Player System**
- Character movement with animation states (Walk, Idle)
- Directional sprite animations
- Freeze/unfreeze mechanics during interactions
- Health management (6 HP maximum, 3 hearts)

**Interaction System**
- InteractionArea for detecting nearby objects
- InteractionManager autoload for global coordination
- Support for text dialogs and mini-games
- One-time and repeatable interactions

**Mini-Game System**
- BaseMiniGame class for all puzzles
- MiniGameManager autoload handles lifecycle
- Persistent completion tracking
- Success/failure callbacks
- Player movement freezing during puzzles

**Health System**
- HealthManager autoload tracks HP
- Heart-based UI representation
- Game over condition on hearts empty
- Penalty system for puzzle failures

### Project Structure

```
Characters/         - Player character scripts and scenes
GUI/                - User interface elements
  MiniGames/        - All puzzle implementations
  player_HUD/       - Health display system
  Font/             - Press Start 2P retro font
Interaction/        - Interaction detection system
Levels/             - Game rooms and scenes
  Interactions/     - Doors and interactable objects
Art/                - Sprites and tilesets
  Characters/       - Character spritesheets
  Tilesets/         - Environment assets
```

## Installation

### Prerequisites
- Godot Engine 4.5 or later
- Windows, macOS, or Linux

### Setup
1. Clone this repository
2. Open the project in Godot 4.5+
3. Run the project from the editor (F5) or export as executable

## Controls

- **WASD** or **Arrow Keys** - Move player
- **E** - Interact with objects
- **ESC** - Pause game or close mini-games
- **Left Click** - UI interactions and puzzle selections
- **Enter** - Submit puzzle answers

## Technical Details

**Engine**: Godot 4.5  
**Language**: GDScript  
**Display**: 1920x1080 viewport with 4x scale  
**Compatibility**: GL Compatibility renderer

### Key Autoloads
- NavigationManager: Room transitions and player spawning
- InteractionManager: Global interaction handling
- DialogBox: Dialog display system
- MiniGameManager: Puzzle state management
- HealthManager: HP tracking
- PauseMenu: Game pause functionality

## Development

The game uses Godot's node-based architecture with autoload singletons for cross-scene state management. All mini-games extend the BaseMiniGame class for consistent behavior. The project follows a component-based design with separate systems for movement, interaction, health, and puzzles.

## Credits

**Art Assets**
- Character sprites: Free Chicken/Cow/Character spritesheets
- Tileset: TopDownHouse collection
- Font: Press Start 2P by CodeMan38

## License

See LICENSE file for details.
