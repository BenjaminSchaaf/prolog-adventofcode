% Read an asteroid grid from a string
asteroid_grid(Data, Grid) :-
    split_string(Data, "\n", "", RowsData),
    maplist(asteroid_grid_row, RowsData, Grid).

asteroid_grid_row(Data, Row) :-
    string_codes(Data, RowCodes),
    maplist([Code, Tile]>>((Code = 35, Tile = '#'); Tile = '.'), RowCodes, Row).

test_asteroid_grid :-
    asteroid_grid(
        ".#..#\n.....\n#####\n....#\n...##",
        [
            ['.', '#', '.', '.', '#'],
            ['.', '.', '.', '.', '.'],
            ['#', '#', '#', '#', '#'],
            ['.', '.', '.', '.', '#'],
            ['.', '.', '.', '#', '#']
        ]).


% Angle in radians from up in a clockwise direction
angle_from_up(-(StartX, StartY), -(GoalX, GoalY), Angle) :-
    GradientX is GoalX - StartX,
    GradientY is GoalY - StartY,
    Angle is pi() - atan(GradientX, GradientY).

test_angle_from_up :-
    angle_from_up(0-0, 0- -1, 0.0).


count_visible_asteroids(Grid, Position, Count) :-
    findall(
        A,
        (
            nth0(Y, Grid, Row),
            nth0(X, Row, '#'),
            -(X, Y) \= Position,
            angle_from_up(Position, -(X, Y), A)
        ),
        Angles),
    list_to_set(Angles, UniqueAngles),
    length(UniqueAngles, Count).


% Custom max_list implementation for a list of key-value pairs
max_key([Head|Tail], Max) :- max_key_(Tail, Head, Max).
max_key_([], Current, Current).
max_key_([Head|Tail], Current, Result) :-
    Head = -(HeadValue, _),
    Current = -(CurrentValue, _),
    (
        HeadValue > CurrentValue
        -> max_key_(Tail, Head, Result)
        ; max_key_(Tail, Current, Result)
    ).


most_visible_asteroids(Data, Result) :-
    asteroid_grid(Data, Grid),
    findall(
        R,
        (
            nth0(Y, Grid, Row),
            nth0(X, Row, '#'),
            count_visible_asteroids(Grid, -(X, Y), Count),
            R = -(Count, -(X, Y))
        ),
        Counts),
    max_key(Counts, Result).

test_most_visible_asteroids :-
    most_visible_asteroids(".#..#\n.....\n#####\n....#\n...##", -(8, 3-4)),
    most_visible_asteroids(
        "......#.#.\n#..#.#....\n..#######.\n.#.#.###..\n.#..#.....\n..#....#.#\n#..#....#.\n.##.#..###\n##...#..#.\n.#....####",
        -(33, 5-8)),
    most_visible_asteroids(
        ".#..##.###...#######\n##.############..##.\n.#.######.########.#\n.###.#######.####.#.\n#####.##.#.##.###.##\n..#####..#.#########\n####################\n#.####....###.#.#.##\n##.#################\n#####.##.###..####..\n..######..##.#######\n####.##.####...##..#\n.#####..#.######.###\n##...#.##########...\n#.##########.#######\n.####.#.###.###.#.##\n....##.##.###..#####\n.#.#.###########.###\n#.#.#.#####.####.###\n###.##.####.##.#..##",
        -(210, 11-13)).


% Get a list of adjacent entities in a key-value list
adjacent_keys([Entry|Tail], [Entry|Adjacent], Rest) :-
    Entry = -(Value, _),
    adjacent_keys_(Tail, Value, Adjacent, Rest).
adjacent_keys_([Entry|Tail], Value, [Entry|Adjacent], Rest) :-
    Entry = -(Value, _),
    adjacent_keys_(Tail, Value, Adjacent, Rest).
adjacent_keys_([First|Rest], Value, [], [First|Rest]) :-
    First \= -(Value, _).
adjacent_keys_([], _, [], []).

test_adjacent_keys :-
    adjacent_keys([-(1, 2)], [-(1, 2)], []),
    adjacent_keys([-(1, 3), -(2, 4)], [-(1, 3)], [-(2, 4)]),
    adjacent_keys([-(1, 2), -(1, 3)], [-(1, 2), -(1, 3)], []),
    adjacent_keys([-(1, 3), -(1, 4), -(2, 5)], [-(1, 3), -(1, 4)], [-(2, 5)]).


% Group all asteroids on the same angle and pick the closest, put the rest on an
% array for later.
laser_visibility(Input, Result) :-
    laser_visibility_(Input, Result, []).
laser_visibility_([], [], []).
laser_visibility_([], Result, Back) :-
    laser_visibility_(Back, Result, []).
laser_visibility_(Input, [Result|ResultTail], Back) :-
    adjacent_keys(Input, Matches, InputTail),
    keysort(Matches, [Result|Tail]),
    append(Back, Tail, NextBack),
    laser_visibility_(InputTail, ResultTail, NextBack).

laser_visibility_list(Data, Position, Set) :-
    asteroid_grid(Data, Grid),
    Position = -(PX, PY),
    findall(
        R,
        (
            nth0(Y, Grid, Row),
            nth0(X, Row, '#'),
            -(X, Y) \= Position,
            angle_from_up(Position, -(X, Y), Angle),
            Distance is sqrt((PX - X)**2 + (PY - Y)**2),
            R = -(Angle, -(Distance, -(X, Y)))
        ),
        Asteroids),
    keysort(Asteroids, OrderedAsteroids),
    laser_visibility(OrderedAsteroids, Visible),
    maplist([V, P]>>(V = -(_, -(_, P))), Visible, Set).

test_laser_visibility_list :-
    laser_visibility_list(
        ".#....#####...#..\n##...##.#####..##\n##...#...#.#####.\n..#.....X...###..\n..#.#.....#....##",
        8-3,
        [
            8-0,
            9-0,
            9-1,
            10-0,
            10-1,
            11-1,
            14-0,
            11-2,
            15-1,
            16-1,
            13-2,
            14-2,
            15-2,
            12-3,
            16-4,
            15-4,
            10-4,
            4-4,
            2-4,
            2-3,
            0-2,
            1-2,
            0-1,
            1-1,
            5-2,
            1-0,
            5-1,
            6-1,
            6-0,
            7-0,
            8-1,
            9-2,
            12-1,
            12-2,
            13-3,
            14-3
        ]).


test :-
    test_asteroid_grid(),
    test_angle_from_up(),
    test_most_visible_asteroids(),
    test_adjacent_keys(),
    test_laser_visibility_list().
