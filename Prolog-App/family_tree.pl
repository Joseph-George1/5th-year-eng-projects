% Family Tree Knowledge Base
% This Prolog program defines family relationships and infers complex relationships

% Facts: Basic family relationships
% parent(Parent, Child)
parent(john, mary).
parent(john, tom).
parent(john, sarah).
parent(susan, mary).
parent(susan, tom).
parent(susan, sarah).
parent(mary, james).
parent(mary, lisa).
parent(bob, james).
parent(bob, lisa).
parent(tom, mike).
parent(tom, emma).
parent(anna, mike).
parent(anna, emma).
parent(sarah, david).
parent(paul, david).

% Gender facts
male(john).
male(tom).
male(bob).
male(james).
male(mike).
male(paul).
male(david).

female(susan).
female(mary).
female(sarah).
female(anna).
female(lisa).
female(emma).

% Rules: Inferred relationships

% Father relationship
father(Father, Child) :-
    parent(Father, Child),
    male(Father).

% Mother relationship
mother(Mother, Child) :-
    parent(Mother, Child),
    female(Mother).

% Sibling relationship (share at least one parent)
sibling(X, Y) :-
    parent(P, X),
    parent(P, Y),
    X \= Y.

% Full sibling (share both parents)
full_sibling(X, Y) :-
    father(F, X),
    father(F, Y),
    mother(M, X),
    mother(M, Y),
    X \= Y.

% Brother relationship
brother(Brother, Person) :-
    sibling(Brother, Person),
    male(Brother).

% Sister relationship
sister(Sister, Person) :-
    sibling(Sister, Person),
    female(Sister).

% Grandparent relationship
grandparent(GP, GC) :-
    parent(GP, P),
    parent(P, GC).

% Grandfather relationship
grandfather(GF, GC) :-
    grandparent(GF, GC),
    male(GF).

% Grandmother relationship
grandmother(GM, GC) :-
    grandparent(GM, GC),
    female(GM).

% Uncle relationship
uncle(Uncle, Person) :-
    parent(P, Person),
    brother(Uncle, P).

% Aunt relationship
aunt(Aunt, Person) :-
    parent(P, Person),
    sister(Aunt, P).

% Cousin relationship
cousin(X, Y) :-
    parent(P1, X),
    parent(P2, Y),
    sibling(P1, P2).

% Ancestor relationship (recursive)
ancestor(X, Y) :-
    parent(X, Y).
ancestor(X, Y) :-
    parent(X, Z),
    ancestor(Z, Y).

% Descendant relationship
descendant(X, Y) :-
    ancestor(Y, X).

% Number of children
child_count(Parent, Count) :-
    findall(Child, parent(Parent, Child), Children),
    length(Children, Count).

% All children of a parent
children(Parent, Children) :-
    findall(Child, parent(Parent, Child), Children).

% All descendants of a person
descendants(Person, Descendants) :-
    findall(D, descendant(D, Person), Descendants).

% Check if two people are related
related(X, Y) :-
    ancestor(A, X),
    ancestor(A, Y).

% Marriage relationship (inferred from shared children)
married(X, Y) :-
    parent(X, Child),
    parent(Y, Child),
    X \= Y.
