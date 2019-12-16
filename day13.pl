% Use intcode from day 11
:- ['day9-fast'].

game(Program, Grid) :-
    intcode(Program, [], Output),
    empty_assoc(InitialGrid),
    game_output(Output, InitialGrid, Grid).


game_output([], Grid, Grid).
game_output([X, Y, TileID|Tail], Grid, Result) :-
    put_assoc(-(X, Y), Grid, TileID, NextGrid),
    game_output(Tail, NextGrid, Result).

test_game_output :-
    empty_assoc(InitialGrid),
    game_output([1,2,3,6,5,4], InitialGrid, Grid),
    get_assoc(-(1, 2), Grid, 3),
    get_assoc(-(6, 5), Grid, 4).


count_block_tiles(Program, Count) :-
    game(Program, Grid),
    assoc_to_values(Grid, Tiles),
    include(=(2), Tiles, BlockTiles),
    length(BlockTiles, Count).


% For debugging
display_game(Grid) :-
    Size = -(200, 50),
    display_game_rows(Grid, Size, 0).

display_game_rows(_, -(_, Height), Height).
display_game_rows(Grid, -(Width, Height), Y) :-
    Y < Height,
    display_game_row(Grid, Width, -(0, Y)),
    write("\n"),
    NextY is Y + 1,
    %% write("??"),
    %% write(NextY),
    %% write("\n"),
    display_game_rows(Grid, -(Width, Height), NextY).

display_game_row(_, Width, -(Width, _)).
display_game_row(Grid, Width, -(X, Y)) :-
    !,
    X < Width,
    (get_assoc(-(X, Y), Grid, Entry); Entry = 0),
    (
        (Entry = 0, Char = " ");
        (Entry = Char)
    ),
    write(Char),
    NextX is X + 1,
    display_game_row(Grid, Width, -(NextX, Y)).


% Simple game AI, move towards ball
game_ai(-1, _, 0).
game_ai(_, -1, 0).
game_ai(Ball, Puck, Joystick) :-
    Joystick is sign(Puck - Ball).


play_game(Program, Score) :-
    empty_assoc(InitialGrid),
    Memory =.. [a|Program],
    play_game_(state(0, 0, Memory), InitialGrid, Grid, [], -1, -1),
    get_assoc(-(-1, 0), Grid, Score).

play_game_(State, Grid, Result, [O1, O2, O3], BallX, PuckX) :-
    !,
    game_output([O1, O2, O3], Grid, NextGrid),
    % Use for debugging
    % display_game(NextGrid),
    (
        (O3 = 3, NextBallX = O1, NextPuckX = PuckX);
        (O3 = 4, NextBallX = BallX, NextPuckX = O1);
        (NextBallX = BallX, NextPuckX = PuckX)
    ),
    play_game_(State, NextGrid, Result, [], NextBallX, NextPuckX).
play_game_(S1, Grid, Result, Output, BallX, PuckX) :-
    game_ai(BallX, PuckX, Joystick),
    intcode_step(S1, [Joystick], O, S2, _),
    !,
    (
        (O = fin, S2 = fin, Result = Grid);
        (
            append(Output, [O], NextOutput),
            play_game_(S2, Grid, Result, NextOutput, BallX, PuckX)
        )
    ).
