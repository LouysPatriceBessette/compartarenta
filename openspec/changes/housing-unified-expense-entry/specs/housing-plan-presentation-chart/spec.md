## ADDED Requirements

### Requirement: Chart lists each expense as its own item

The housing plan presentation chart SHALL render one visual item per expense line. The system MUST NOT group, stack, or merge lines by `PlanGroup`, ratio template id, or identical split weights.

#### Scenario: Multiple lines on one plan

- **WHEN** the plan has three expense lines
- **THEN** the chart presents three distinct items

#### Scenario: Lines sharing a Like template

- **WHEN** two lines were authored with the same ratio template weights
- **THEN** the chart still shows two items (typically labeled by each line’s Name), not a single grouped bucket
