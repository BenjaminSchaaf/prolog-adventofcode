manhatten_distance(-(X, Y), D) :-
    D is abs(X) + abs(Y).

test_manhatten_distance :-
    manhatten_distance(-(1, 1), 2),
    manhatten_distance(-(18, 12), 30).


list_min([Value], Value).
list_min([Value|Tail], Min) :-
    list_min(Tail, TailMin),
    (
        (Value < TailMin, Min = Value);
        Min = TailMin
    ).

test_list_min :-
    list_min([3, -1, 8, 2], -1).


%% Line intersection test only needs to consider two cases, either the lines are
%% perpendicular or parallel.
% Parallel line intersection along the y axis
lines_intersect(-(X, Y1), u, L1, -(X, Y2), u, L2, -(X, PY)) :-
    End1 is Y1 + L1,
    End2 is Y2 + L2,
    Y1 =< End2,
    End1 >= Y2,
    BottomIntersect is max(Y1, Y2),
    TopIntersect is min(End1, End2),
    (
        (
            BottomIntersect =< 0,
            TopIntersect >= 0,
            PY = 0
        );
        (
            abs(BottomIntersect) =< abs(TopIntersect),
            PY = BottomIntersect
        );
        (
            abs(BottomIntersect) >= abs(TopIntersect),
            PY = TopIntersect
        )
    ).
% Swap axies for parallel line intersection along x axis
lines_intersect(-(X1, Y1), r, L1, -(X2, Y2), r, L2, -(PX, PY)) :-
    lines_intersect(-(Y1, X1), u, L1, -(Y2, X2), u, L2, -(PY, PX)).
% Perpendicular lines u and r
lines_intersect(-(X1, Y1), u, L1, -(X2, Y2), r, L2, -(X1, Y2)) :-
    End1Y is Y1 + L1,
    End2X is X2 + L2,
    Y1 =< Y2, Y2 =< End1Y,
    X2 =< X1, X1 =< End2X.
% Swap lines to intersect perpendicular lines r and u
lines_intersect(-(X1, Y1), r, L1, -(X2, Y2), u, L2, Point) :-
    lines_intersect(-(X2, Y2), u, L2, -(X1, Y1), r, L1, Point).
% l and d lines are intersected by converting them to r and u lines respectively
lines_intersect(-(X1, Y1), l, L1, P2, D2, L2, Point) :-
    EndX is X1 - L1,
    lines_intersect(-(EndX, Y1), r, L1, P2, D2, L2, Point).
lines_intersect(P2, D2, L2, -(X1, Y1), l, L1, Point) :-
    EndX is X1 - L1,
    lines_intersect(P2, D2, L2, -(EndX, Y1), r, L1, Point).
lines_intersect(-(X1, Y1), d, L1, P2, D2, L2, Point) :-
    EndY is Y1 - L1,
    lines_intersect(-(X1, EndY), u, L1, P2, D2, L2, Point).
lines_intersect(P2, D2, L2, -(X1, Y1), d, L1, Point) :-
    EndY is Y1 - L1,
    lines_intersect(P2, D2, L2, -(X1, EndY), u, L1, Point).

test_lines_intersect :-
    lines_intersect(-(1, 1), u, 5, -(1, 6), u, 3, -(1, 6)),
    \+ lines_intersect(-(1, 1), u, 4, -(1, 6), u, 3, _),
    lines_intersect(-(1, 3), u, 1, -(0, 3), r, 1, -(1, 3)),
    \+ lines_intersect(-(1, 4), u, 1, -(0, 3), r, 1, -(1, 3)).


%% Construct a set of lines from the program input, lines are in the format
%% [-(X, Y0), Direction, Length, Cost]
line_program(Program, Lines) :-
    split_string(Program, ",", "", Instructions),
    line_program(-(0, 0), 0, Instructions, Lines).
line_program(-(_, _), _, [], []).
line_program(-(X, Y), Cost, [Instruction|InstructionsTail], [Line|LinesTail]) :-
    sub_string(Instruction, 0, 1, _, DirectionStr),
    atom_string(DirectionUpper, DirectionStr),
    downcase_atom(DirectionUpper, Direction),
    sub_string(Instruction, 1, _, 0, LengthStr),
    number_string(Length, LengthStr),
    Line = [-(X, Y), Direction, Length, Cost],
    NextCost is Cost + Length,
    (
        (Direction = u, EndX is X, EndY is Y + Length);
        (Direction = d, EndX is X, EndY is Y - Length);
        (Direction = l, EndX is X - Length, EndY is Y);
        (Direction = r, EndX is X + Length, EndY is Y)
    ),
    line_program(-(EndX, EndY), NextCost, InstructionsTail, LinesTail).

test_line_program :-
    line_program("R8,U5,L5,D3",
        [
            [0-0, r, 8, 0],
            [8-0, u, 5, 8],
            [8-5, l, 5, 13],
            [3-5, d, 3, 18]
        ]),
    line_program("U7,R6,D4,L4",
        [
            [0-0, u, 7, 0],
            [0-7, r, 6, 7],
            [6-7, d, 4, 13],
            [6-3, l, 4, 17]
        ]).


line_program_intersection(Program1, Program2, Point, Cost) :-
    line_program(Program1, Lines1),
    line_program(Program2, Lines2),
    member([Line1P, Line1D, Line1L, Line1C], Lines1),
    member([Line2P, Line2D, Line2L, Line2C], Lines2),
    lines_intersect(Line1P, Line1D, Line1L, Line2P, Line2D, Line2L, Point),
    Point \= -(0, 0),
    % Calculate the total cost at the intersection point
    -(PointX, PointY) = Point,
    -(Line1PX, Line1PY) = Line1P,
    -(Line2PX, Line2PY) = Line2P,
    Cost is Line1C + abs(Line1PX - PointX) + abs(Line1PY - PointY)
          + Line2C + abs(Line2PX - PointX) + abs(Line2PY - PointY).


closest_intersecting_line_distance(Program1, Program2, Distance) :-
    findall(P, line_program_intersection(Program1, Program2, P, _), Points),
    maplist(manhatten_distance, Points, Distances),
    list_min(Distances, Distance).

test_closest_intersecting_line_distance :-
    closest_intersecting_line_distance("U1,R1", "R1,U1", 2),
    closest_intersecting_line_distance("D1,L1", "L1,D1", 2),
    closest_intersecting_line_distance("U9999,R9999", "R9999,U9999", 19998),
    closest_intersecting_line_distance("R8,U5,L5,D3", "U7,R6,D4,L4", 6),
    closest_intersecting_line_distance("R75,D30,R83,U83,L12,D49,R71,U7,L72", "U62,R66,U55,R34,D71,R55,D58,R83", 159),
    closest_intersecting_line_distance("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51", "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7", 135).


least_cost_intersecting_line(Program1, Program2, Cost) :-
    findall(C, line_program_intersection(Program1, Program2, _, C), Costs),
    list_min(Costs, Cost).

test_least_cost_intersecting_line :-
    least_cost_intersecting_line("R8,U5,L5,D3", "U7,R6,D4,L4", 30),
    least_cost_intersecting_line("R75,D30,R83,U83,L12,D49,R71,U7,L72", "U62,R66,U55,R34,D71,R55,D58,R83", 610).


test :-
    test_manhatten_distance(),
    test_list_min(),
    test_lines_intersect(),
    test_line_program(),
    test_closest_intersecting_line_distance(),
    test_least_cost_intersecting_line().
