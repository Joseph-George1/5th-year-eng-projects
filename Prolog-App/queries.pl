% Sample Queries for Family Tree Knowledge Base
% Load this file after loading family_tree.pl

% Example queries to demonstrate the system:
% Copy and paste these into the Prolog interpreter

/*
% Find all fathers
?- father(F, _).

% Find Mary's children
?- parent(mary, Child).

% Find all of John's grandchildren
?- grandparent(john, GC).

% Find all siblings of Tom
?- sibling(tom, S).

% Who are James's uncles?
?- uncle(Uncle, james).

% Who are cousins with Mike?
?- cousin(mike, Cousin).

% Find all ancestors of David
?- ancestor(A, david).

% Find all descendants of John
?- descendant(D, john).

% How many children does John have?
?- child_count(john, Count).

% Who is married to whom?
?- married(X, Y).

% Are Mike and Lisa related?
?- related(mike, lisa).

% Find all grandfathers
?- grandfather(GF, _).

% Find all sisters of Mary
?- sister(S, mary).

% Find everyone's children
?- children(P, Kids).

% Find all descendants of Susan
?- descendants(susan, Desc).
*/

% Helper predicate to display family tree structure
display_family_tree :-
    write('=== Family Tree ==='), nl, nl,
    write('Parents and their children:'), nl,
    forall(
        (parent(P, _), \+ (parent(_, P))),
        (
            write(P), write(' and '),
            (married(P, Spouse) -> write(Spouse); write('unknown')),
            write(' have children: '),
            children(P, Kids),
            write(Kids), nl
        )
    ).

% Helper to display all relationships for a person
person_info(Person) :-
    format('~n=== Information about ~w ===~n', [Person]),
    
    % Parents
    write('Parents: '),
    (father(F, Person) -> format('Father: ~w ', [F]); write('Father: unknown ')),
    (mother(M, Person) -> format('Mother: ~w', [M]); write('Mother: unknown')),
    nl,
    
    % Siblings
    findall(S, sibling(S, Person), Siblings),
    (Siblings \= [] -> 
        (format('Siblings: ~w~n', [Siblings])) 
    ; 
        write('Siblings: none'), nl
    ),
    
    % Children
    findall(C, parent(Person, C), Children),
    (Children \= [] -> 
        (format('Children: ~w~n', [Children])) 
    ; 
        write('Children: none'), nl
    ),
    
    % Grandchildren
    findall(GC, grandparent(Person, GC), Grandchildren),
    (Grandchildren \= [] -> 
        (format('Grandchildren: ~w~n', [Grandchildren])) 
    ; 
        write('Grandchildren: none'), nl
    ).
