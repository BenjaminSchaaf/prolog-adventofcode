% Use intcode from day 9
:- ['day9-fast'].


scaffold_intersections(Grid, Points) :-
    % Find all points that are scaffolding and are surrounded by scaffolding
    findall(
        P,
        (
            nth0(Y, Grid, Line),
            YAbove is Y - 1,
            nth0(YAbove, Grid, LineAbove),
            YBelow is Y + 1,
            nth0(YBelow, Grid, LineBelow),
            % 35 = "#"
            string_code(X1, Line, 35),
            string_code(X1, LineAbove, 35),
            string_code(X1, LineBelow, 35),
            XBefore is X1 - 1,
            string_code(XBefore, Line, 35),
            XAfter is X1 + 1,
            string_code(XAfter, Line, 35),
            X is X1 - 1,
            P = -(X, Y)
        ),
        Points).

test_scaffold_intersections :-
    Grid = [
        "..#..........",
        "..#..........",
        "#######...###",
        "#.#...#...#.#",
        "#############",
        "..#...#...#..",
        "..#####...^.."
    ],
    scaffold_intersections(Grid, Points),
    member(-(2, 2), Points),
    member(-(2, 4), Points),
    member(-(6, 4), Points),
    member(-(10, 4), Points).


scaffold_alignment(Program, Alignment) :-
    intcode(Program, [], Codes),
    string_codes(String, Codes),
    split_string(String, "\n", "\n", Lines),
    scaffold_intersections(Lines, Points),
    maplist([-(X, Y), Value]>>(Value is X * Y), Points, Values),
    sum_list(Values, Alignment).


grid_entry(Grid, X, Y, Code) :-
    nth0(Y, Grid, Line),
    string_length(Line, Size),
    X >= 0, X < Size,
    X1 is X + 1,
    string_code(X1, Line, Code).

test_grid_entry :-
    Grid = [
        "..#..",
        "...#.",
        "#...."
    ],
    % 46 = "."
    grid_entry(Grid, 1, 0, 46),
    grid_entry(Grid, 2, 0, 35),
    grid_entry(Grid, 3, 0, 46),
    grid_entry(Grid, 2, 1, 46),
    grid_entry(Grid, 3, 1, 35),
    grid_entry(Grid, 4, 1, 46).


move(-(X, Y), up, -(X, NY)) :- NY is Y - 1.
move(-(X, Y), down, -(X, NY)) :- NY is Y + 1.
move(-(X, Y), right, -(NX, Y)) :- NX is X + 1.
move(-(X, Y), left, -(NX, Y)) :- NX is X - 1.


rotate(up, l, left).
rotate(left, l, down).
rotate(down, l, right).
rotate(right, l, up).
rotate(up, r, right).
rotate(right, r, down).
rotate(down, r, left).
rotate(left, r, up).


generate_traversal_instructions(Grid, Instructions) :-
    % Find current location of bot "^"
    nth0(Y, Grid, Line),
    % 94 = "^"
    string_code(X1, Line, 94),
    X is X1 - 1,
    StartPoint = -(X, Y),
    StartDirection = up,
    !,
    generate_traversal_instructions_(
        Grid, StartPoint, StartDirection, Instructions).

generate_traversal_instructions_(
        Grid, Point, Direction, [Turn,Walk|Instructions]) :-
    % Find a direction to turn to
    rotate(Direction, Turn, NextDirection),
    move(Point, NextDirection, -(NX, NY)),
    grid_entry(Grid, NX, NY, 35),
    !,
    % Find the length of the walk in that direction
    generate_traversal_instructions_walk_(
        Grid, -(NX, NY), NextDirection, 1, NextPoint, Walk),
    % Next instruction
    generate_traversal_instructions_(
        Grid, NextPoint, NextDirection, Instructions).

generate_traversal_instructions_(Grid, Point, Direction, []) :-
    % Stop when we've reached the end
    length(Grid, Height),
    Grid = [FirstLine|_],
    string_length(FirstLine, Width),
    % Both to the left and right of the point must be empty. Need to handle
    % edges as a special case.
    rotate(Direction, l, Left),
    move(Point, Left, -(LX, LY)),
    (grid_entry(Grid, LX, LY, 46); LX < 0; LX >= Width; LY < 0; LY >= Height),
    rotate(Direction, r, Right),
    move(Point, Right, -(RX, RY)),
    (grid_entry(Grid, RX, RY, 46); RX < 0; RX >= Width; RY < 0; RY >= Height).

generate_traversal_instructions_walk_(
        Grid, Point, Direction, Length, ResultPoint, ResultLength) :-
    !,
    move(Point, Direction, -(NX, NY)),
    (grid_entry(Grid, NX, NY, Code); Code = 46),
    (Code = 35
        -> (
            NextLength is Length + 1,
            generate_traversal_instructions_walk_(
                Grid,
                -(NX, NY),
                Direction,
                NextLength,
                ResultPoint,
                ResultLength)
        )
        ; (
            ResultPoint = Point,
            ResultLength is Length
        )
    ).

test_generate_traversal_instructions :-
    Grid = [
        "#######...#####",
        "#.....#...#...#",
        "#.....#...#...#",
        "......#...#...#",
        "......#...###.#",
        "......#.....#.#",
        "^########...#.#",
        "......#.#...#.#",
        "......#########",
        "........#...#..",
        "....#########..",
        "....#...#......",
        "....#...#......",
        "....#...#......",
        "....#####......"
    ],
    generate_traversal_instructions(Grid, Instructions),
    !,
    Instructions = [
        r, 8, r, 8, r, 4, r, 4, r, 8, l, 6, l, 2, r, 4, r, 4, r, 8, r, 8, r, 8,
        l, 6, l, 2
    ].


% For putting together the sets of instructions it was easiest doing it by hand.
% This just gives you the instructions you need to group
traversal_instructions(Program, Instructions) :-
    intcode(Program, [], Codes),
    string_codes(String, Codes),
    split_string(String, "\n", "\n", Grid),
    generate_traversal_instructions(Grid, Instructions).


robot_collect_dust(Program, InstructionsString, Output) :-
    string_codes(InstructionsString, Input),
    intcode(Program, Input, Result),
    % Get last output
    append(_, [Output], Result).
