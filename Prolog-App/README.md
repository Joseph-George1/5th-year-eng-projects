# Prolog Family Tree Application

A comprehensive Prolog knowledge base that demonstrates logical inference for family relationships.

## Overview

This application uses Prolog's logical programming paradigm to define family relationships and automatically infer complex relationships like grandparents, cousins, uncles, aunts, and ancestors.

## Files

- **family_tree.pl** - Main knowledge base with facts and inference rules
- **queries.pl** - Sample queries and helper predicates for exploring the family tree
- **README.md** - This file

## Prerequisites

Install SWI-Prolog:
- **Windows**: Download from https://www.swi-prolog.org/Download.html
- **Linux**: `sudo apt-get install swi-prolog`
- **macOS**: `brew install swi-prolog`

## Running the Application

1. Open SWI-Prolog interpreter:
   ```bash
   swipl
   ```

2. Load the knowledge base:
   ```prolog
   ?- [family_tree].
   ```

3. Load sample queries (optional):
   ```prolog
   ?- [queries].
   ```

## Example Queries

### Basic Queries

Find all fathers:
```prolog
?- father(F, _).
```

Find Mary's children:
```prolog
?- parent(mary, Child).
```

Find all of John's grandchildren:
```prolog
?- grandparent(john, GC).
```

### Relationship Queries

Who are James's uncles?
```prolog
?- uncle(Uncle, james).
```

Who are cousins with Mike?
```prolog
?- cousin(mike, Cousin).
```

Find all siblings of Tom:
```prolog
?- sibling(tom, S).
```

### Advanced Queries

Find all ancestors of David:
```prolog
?- ancestor(A, david).
```

Find all descendants of John:
```prolog
?- descendant(D, john).
```

How many children does John have?
```prolog
?- child_count(john, Count).
```

Are Mike and Lisa related?
```prolog
?- related(mike, lisa).
```

### Helper Predicates

Get complete information about a person:
```prolog
?- person_info(mary).
```

Display family tree structure:
```prolog
?- display_family_tree.
```

## Family Structure

```
John ─┬─ Susan
      │
      ├─ Mary ─┬─ Bob
      │        ├─ James
      │        └─ Lisa
      │
      ├─ Tom ─┬─ Anna
      │       ├─ Mike
      │       └─ Emma
      │
      └─ Sarah ─┬─ Paul
                └─ David
```

## Available Relationships

The knowledge base can infer:
- **father/2** - Father-child relationship
- **mother/2** - Mother-child relationship
- **sibling/2** - Sibling relationship
- **brother/2** - Brother relationship
- **sister/2** - Sister relationship
- **grandparent/2** - Grandparent-grandchild relationship
- **grandfather/2** - Grandfather-grandchild relationship
- **grandmother/2** - Grandmother-grandchild relationship
- **uncle/2** - Uncle-niece/nephew relationship
- **aunt/2** - Aunt-niece/nephew relationship
- **cousin/2** - Cousin relationship
- **ancestor/2** - Ancestor-descendant relationship
- **descendant/2** - Descendant-ancestor relationship
- **married/2** - Married couples (inferred from shared children)
- **related/2** - Checks if two people are related

## Extending the Knowledge Base

Add new family members by adding facts:
```prolog
parent(new_parent, new_child).
male(new_parent).  % or female(new_parent)
```

The inference rules will automatically compute all relationships!

## Tips

- Use `;` in the interpreter to see more results
- Use `.` to stop seeing results
- Press Ctrl+D (Unix) or Ctrl+Z (Windows) to exit
- Use `listing(predicate_name).` to see all clauses for a predicate

## Learning Resources

- SWI-Prolog Documentation: https://www.swi-prolog.org/pldoc/
- Learn Prolog Now: http://www.learnprolognow.org/
- Prolog Tutorial: https://www.cpp.edu/~jrfisher/www/prolog_tutorial/contents.html
