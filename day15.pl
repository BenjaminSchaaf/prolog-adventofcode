% Use intcode from day 9
:- ['day9-fast'].


move(-(X, Y), 1, -(X, NY)) :- NY is Y + 1. % North
move(-(X, Y), 2, -(X, NY)) :- NY is Y - 1. % South
move(-(X, Y), 3, -(NX, Y)) :- NX is X - 1. % West
move(-(X, Y), 4, -(NX, Y)) :- NX is X + 1. % East


droid_map(ProgramState, Grid, FinalState) :-
    empty_assoc(EmptyGrid),
    put_assoc(-(0, 0), EmptyGrid, point(empty, 0), InitialGrid),
    Visiting = [-(0, visiting(-(0, 0), ProgramState))],
    droid_map_(InitialGrid, Visiting, Grid, FinalState).

droid_map_(Grid, [], Grid, _).
droid_map_(Grid, [Visiting|VisitingTail], Result, FinalState) :-
    Visiting = -(Length, visiting(Point, State)),
    % Get neighbours
    maplist(
        [D, N]>>(move(Point, D, NP), N = -(D, NP)),
        [1, 2, 3, 4], % Move directions
        Neighbours),
    % Ignore already seen neighbours
    exclude([-(_, P)]>>get_assoc(P, Grid, _), Neighbours, FilteredNeighbours),
    NextLength is Length + 1,
    droid_map_visit_(
        Grid,
        VisitingTail,
        State,
        NextLength,
        FilteredNeighbours,
        NextVisitingOrFinalState,
        NextGrid),
    (is_list(NextVisitingOrFinalState)
        -> (
            keysort(NextVisitingOrFinalState, SortedNextVisiting),
            droid_map_(NextGrid, SortedNextVisiting, Result, FinalState)
        )
        ; (
            % We've reached the goal, so exit now
            write("!!\n"),
            Result = NextGrid,
            FinalState = NextVisitingOrFinalState
        )
    ).

droid_map_visit_(Grid, Visiting, _, _, [], Visiting, Grid).
droid_map_visit_(
        Grid,
        Visiting,
        State,
        Length,
        [-(Direction, Point)|Neighbours],
        VisitingResult,
        GridResult) :-
    !,
    % Make sure intcode_step doesn't modify the state by making a hard copy
    duplicate_term(State, StateCopy),
    set_prolog_flag(gc, false),
    intcode_step(StateCopy, [Direction], Result, FinalState, []),
    set_prolog_flag(gc, true),
    (
        (
            Result = 0,
            !,
            put_assoc(Point, Grid, point(wall, Length), NextGrid),
            droid_map_visit_(
                NextGrid,
                Visiting,
                State,
                Length,
                Neighbours,
                VisitingResult,
                GridResult)
        );
        (
            Result = 1,
            !,
            put_assoc(Point, Grid, point(empty, Length), NextGrid),
            NextVisiting = [-(Length, visiting(Point, FinalState))|Visiting],
            droid_map_visit_(
                NextGrid,
                NextVisiting,
                State,
                Length,
                Neighbours,
                VisitingResult,
                GridResult)
        );
        (
            Result = 2,
            !,
            % Return the final state through the visiting result
            VisitingResult = FinalState,
            put_assoc(Point, Grid, point(goal, Length), GridResult)
        )
    ).


find_goal(Grid, Goal) :-
    gen_assoc(Position, Grid, point(goal, Length)),
    Goal = -(Position, Length).


shorted_droid_map(Program, PathLength) :-
    intcode_state(InitialState, Program),
    droid_map(InitialState, Grid, _),
    find_goal(Grid, -(_, PathLength)).


total_fill_time(Program, Time) :-
    % Find the state where we've reached the goal, then re-run droid_map there
    intcode_state(InitialState, Program),
    droid_map(InitialState, _, SourceState),
    droid_map(SourceState, Grid, _),
    % Find the empty space furthest from the source
    assoc_to_values(Grid, Points),
    include([point(empty, _)]>>true, Points, EmptyPoints),
    maplist([point(_, L), L]>>true, EmptyPoints, Lengths),
    max_list(Lengths, Time).
