direct_orbit(Orbits, A, B) :-
    member(-(A, B), Orbits).
indirect_orbit(Orbits, A, B) :-
    direct_orbit(Orbits, A, C),
    (direct_orbit(Orbits, C, B); indirect_orbit(Orbits, C, B)).


orbits([], []).
orbits([Rule|Rules], [Orbit|Orbits]) :-
    split_string(Rule, ")", "", [ObjectStr, SateliteStr]),
    atom_string(Object, ObjectStr),
    atom_string(Satelite, SateliteStr),
    Orbit = -(Object, Satelite),
    orbits(Rules, Orbits).


checksum(RulesString, Checksum) :-
    split_string(RulesString, "\n", "", Rules),
    orbits(Rules, Orbits),
    findall(1, direct_orbit(Orbits, _, _), DirectOrbits),
    findall(1, indirect_orbit(Orbits, _, _), IndirectOrbits),
    length(DirectOrbits, X),
    length(IndirectOrbits, Y),
    Checksum is X + Y.


test_checksum :-
    checksum("A)B", 1),
    checksum("COM)B\nB)C\nC)D\nD)E\nE)F\nB)G\nG)H\nD)I\nE)J\nJ)K\nK)L", 42).


shorted_path(RulesString, PathLength) :-
    split_string(RulesString, "\n", "", Rules),
    orbits(Rules, Orbits),
    direct_orbit(Orbits, Start, 'YOU'),
    direct_orbit(Orbits, Goal, 'SAN'),
    setof(
        L,
        (
            path(Orbits, ['YOU', 'SAN'], Start, Goal, Path),
            length(Path, L)
        ),
        [PathLength|_]
    ).


path(_, _, Goal, Goal, []).
path(Orbits, Visited, Current, Goal, [Current|Path]) :-
    (direct_orbit(Orbits, Current, Next); direct_orbit(Orbits, Next, Current)),
    \+ member(Next, Visited),
    path(Orbits, [Current|Visited], Next, Goal, Path).


test_shorted_path :-
    shorted_path("A)YOU\nA)SAN", 0),
    shorted_path(
        "COM)B\nB)C\nC)D\nD)E\nE)F\nB)G\nG)H\nD)I\nE)J\nJ)K\nK)L\nK)YOU\nI)SAN",
        4).
