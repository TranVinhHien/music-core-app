# Design System

## Design Direction

Build a modern, premium music application with a clean, calm and minimal visual language.

The UI should feel:

* Modern
* Premium
* Minimal
* Comfortable for long listening sessions
* Visually focused on music/content rather than decoration

Avoid:

* Excessive gradients
* Excessive shadows
* Dense layouts
* Too many colors
* Unnecessary borders
* Overly complicated interactions
* UI that looks like a generic admin dashboard

## Visual Hierarchy

Every screen must have a clear hierarchy:

1. Primary content
2. Primary action
3. Secondary information
4. Secondary actions

Important content should receive stronger visual weight through:

* Size
* Typography
* Spacing
* Position
* Contrast

Do not use color alone to communicate hierarchy.

## Layout

Use a consistent layout system across the application.

Rules:

* Prefer simple vertical/horizontal layouts.
* Use consistent horizontal page margins.
* Use predictable spacing between sections.
* Group related content visually.
* Avoid unnecessary nested containers.
* Prefer whitespace over borders for separation.

The layout must work naturally on different screen sizes.

## Spacing

Use a consistent spacing scale.

Do not use arbitrary spacing values throughout the UI.

Prefer reusable spacing tokens/components instead of hardcoded values.

## Typography

Typography must have a clear hierarchy:

* Display
* Screen title
* Section title
* Body
* Secondary text
* Caption

Use font size, weight and spacing consistently.

Avoid using many different font sizes or weights on the same screen.

## Colors

Support:

* Light theme
* Dark theme
* System theme

Colors must come from the centralized theme/design system.

Never hardcode colors inside individual screens or widgets.

The color system should provide clear roles for:

* Background
* Surface
* Primary
* Secondary
* Text
* Secondary text
* Divider
* Error
* Success
* Warning

Dark mode should be designed independently, not simply created by inverting light-mode colors.

## Components

Prefer reusable components over screen-specific implementations.

Common components should have consistent:

* Size
* Shape
* Padding
* Typography
* Icon size
* Interaction states

Examples:

* Buttons
* Icon buttons
* Cards
* List items
* Chips
* Tabs
* Bottom sheets
* Dialogs
* Search fields
* Navigation components
* Media artwork components

Create a reusable component when the same visual pattern appears in multiple places.

## Icons

Use one consistent icon system.

Do not mix unrelated icon styles.

Icons must have:

* Consistent visual weight
* Consistent size
* Appropriate touch area

Icon-only actions must have sufficient touch targets.

## Artwork

Music artwork is an important visual element.

Artwork components should have consistent:

* Aspect ratio
* Corner radius
* Size hierarchy
* Placeholder behavior
* Loading behavior

Artwork should visually distinguish primary content from secondary content.

## Interaction States

Every interactive component should consider:

* Default
* Pressed
* Focused
* Disabled
* Loading
* Selected
* Error

State changes should be visually clear but subtle.

## Navigation Structure

Navigation should remain visually consistent across the application.

Do not introduce different navigation patterns for different screens without a clear reason.

Primary navigation should be easy to discover and reachable with minimal interaction.

## Responsive Design

The design must adapt to:

* Small phones
* Large phones
* Different aspect ratios
* Portrait orientation
* Landscape where appropriate

Do not solve responsive layouts by simply shrinking everything.

Preserve hierarchy and usability first.

## Accessibility

UI must maintain:

* Readable contrast
* Adequate touch targets
* Clear text hierarchy
* Visible interaction states
* Semantic labels for important controls

Do not rely exclusively on color to communicate state.

## Design Consistency

When creating a new screen:

1. Reuse existing design tokens.
2. Reuse existing components.
3. Follow existing spacing and typography.
4. Follow existing interaction patterns.
5. Only introduce a new pattern when an existing pattern cannot satisfy the design requirement.

The application should feel like one coherent product, not a collection of independently designed screens.
