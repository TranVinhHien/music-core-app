# Local task product

This glossary defines the product language for the deterministic Demo sign-in
and account-owned task flow.

## Language

**Demo account**:
One of the two public demonstration identities available in this teaching
product.
_Avoid_: Real user, production account

**Session**:
The currently selected Demo account, retained across application launches until
sign-out.
_Avoid_: Token, credentials

**Task**:
A to-do item owned by exactly one Demo account.

**Task owner**:
The Demo account that alone can view and change a task.
_Avoid_: Current user

**Active task**:
A task that has not been completed.
_Avoid_: In-progress task

**Completed task**:
A task that has been marked as completed.

**Task title**:
The trimmed, non-empty text that names a task.
