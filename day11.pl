% Partial copy of day 9, refactored to handle single-step outputs

replace([_|Tail], 0, Element, [Element|Tail]).
replace([Head|Tail], Index, Element, [Head|ResultTail]) :-
    NextIndex is Index - 1,
    replace(Tail, NextIndex, Element, ResultTail).

test_replace :-
    replace([1, 2, 3], 1, 4, [1, 4, 3]),
    \+ replace([1, 2, 3], 3, 4, [1, 2, 3, 4]).


padd_to(List, Size, Result) :-
    length(List, S),
    (
        (
            S =< Size,
            append(List, [0], Next),
            padd_to(Next, Size, Result)
        );
        List = Result
    ).

test_padd_to :-
    padd_to([0, 1, 2], 5, [0, 1, 2, 0, 0, 0]),
    padd_to([0, 1, 2], 4, [0, 1, 2, 0, 0]),
    padd_to([0, 1, 2], 3, [0, 1, 2, 0]),
    padd_to([0, 1, 2], 2, [0, 1, 2]),
    padd_to([0, 1, 2], 0, [0, 1, 2]).


% address now needs to grow the memory if we access past the end
address(Memory, Pointer, Value, NextMemory) :-
    padd_to(Memory, Pointer, NextMemory),
    nth0(Pointer, NextMemory, Value).
address(Memory, Pointer, Offset, Value, NextMemory) :-
    Index is Pointer + Offset,
    address(Memory, Index, Value, NextMemory).

test_address :-
    address([3, 4, 5, 6], 1, 4, [3, 4, 5, 6]),
    address([3, 4, 5, 6], 4, 0, [3, 4, 5, 6, 0]).


% Instead of just replace we need to grow the memory if the pointer is past the
% end
set_mem(Memory, Pointer, Value, NextMemory) :-
    padd_to(Memory, Pointer, IntermediaMemory),
    replace(IntermediaMemory, Pointer, Value, NextMemory).

test_set_mem :-
    set_mem([1, 2, 3], 3, 4, [1, 2, 3, 4]).


intcode_parameter(
        Memory, Pointer, RelativeBase, Index, Modes, Parameter, NextMemory) :-
    Mode is mod(floor(Modes / 10**Index), 10),
    AddressPointer is Pointer + Index + 1,
    (
        (
            Mode = 0,
            address(Memory, AddressPointer, ParameterAddress, IntermediaMemory),
            address(IntermediaMemory, ParameterAddress, Parameter, NextMemory)
        );
        (Mode = 1, address(Memory, AddressPointer, Parameter, NextMemory));
        (
            Mode = 2,
            address(Memory, AddressPointer, Offset, IntermediaMemory),
            ParameterAddress is RelativeBase + Offset,
            address(IntermediaMemory, ParameterAddress, Parameter, NextMemory)
        )
    ).


% Results now have parameter modes, so handle those
intcode_result(
        Memory, Pointer, RelativeBase, Index, Modes, Value, NextMemory) :-
    Mode is mod(floor(Modes / 10**Index), 10),
    ResultPointer is Pointer + Index + 1,
    (
        (
            Mode = 0,
            address(Memory, ResultPointer, ResultAddress, IntermediateMemory)
        );
        (
            Mode = 2,
            address(Memory, ResultPointer, Offset, IntermediateMemory),
            ResultAddress is RelativeBase + Offset
        )
    ),
    set_mem(IntermediateMemory, ResultAddress, Value, NextMemory).


intcode(Memory, Input, Output) :-
    intcode_(state(0, 0, Memory), Input, Output).
intcode_(State, [], []) :-
    intcode_step(State, [], fin, fin, []).
intcode_(State, Input, [Output|OutputTail]) :-
    intcode_step(State, Input, Output, NextState, InputTail),
    intcode_(NextState, InputTail, OutputTail).

% Step until the next output or termination
intcode_step(
        state(Pointer, RelativeBase, InitialMemory),
        Input,
        Output,
        FinalState,
        RemainingInput) :-
    address(InitialMemory, Pointer, Operation, Memory),
    OpCode is mod(Operation, 100),
    ParameterModes is floor(Operation / 100),
    (
        ( % Stop
            OpCode = 99,
            Output = fin,
            FinalState = fin,
            RemainingInput = Input
        );
        ( % Input
            OpCode = 3,
            Input = [Value|InputTail],
            intcode_result(
                Memory,
                Pointer,
                RelativeBase,
                0,
                ParameterModes,
                Value,
                NextMemory),
            NextPointer is Pointer + 2,
            intcode_step(
                state(NextPointer, RelativeBase, NextMemory),
                InputTail,
                Output,
                FinalState,
                RemainingInput)
        );
        ( % Output
            OpCode = 4,
            intcode_parameter(
                Memory,
                Pointer,
                RelativeBase,
                0,
                ParameterModes,
                Value,
                NextMemory),
            Output = Value,
            NextPointer is Pointer + 2,
            FinalState = state(NextPointer, RelativeBase, NextMemory),
            RemainingInput = Input
        );
        ( % JMP
            (OpCode = 5; OpCode = 6),
            intcode_parameter(
                Memory,
                Pointer,
                RelativeBase,
                0,
                ParameterModes,
                Condition,
                NextMemory1),
            intcode_parameter(
                NextMemory1,
                Pointer,
                RelativeBase,
                1,
                ParameterModes,
                NextPointer,
                NextMemory2),
            (
                (
                    ((OpCode = 5, Condition \= 0); (OpCode = 6, Condition = 0)),
                    AfterPointer = NextPointer
                );
                (AfterPointer is Pointer + 3)
            ),
            intcode_step(
                state(AfterPointer, RelativeBase, NextMemory2),
                Input,
                Output,
                FinalState,
                RemainingInput)
        );
        ( % Modify Relative Base
            (OpCode = 9),
            intcode_parameter(
                Memory,
                Pointer,
                RelativeBase,
                0,
                ParameterModes,
                Value,
                NextMemory),
            NextRelativeBase is RelativeBase + Value,
            NextPointer is Pointer + 2,
            intcode_step(
                state(NextPointer, NextRelativeBase, NextMemory),
                Input,
                Output,
                FinalState,
                RemainingInput)
        );
        ( % Normal Ops
            intcode_parameter(
                Memory,
                Pointer,
                RelativeBase,
                0,
                ParameterModes,
                Val1,
                NextMemory1),
            intcode_parameter(
                NextMemory1,
                Pointer,
                RelativeBase,
                1,
                ParameterModes,
                Val2,
                NextMemory2),
            (
                % Addition
                (OpCode = 1, Result is Val1 + Val2);
                % Subtraction
                (OpCode = 2, Result is Val1 * Val2);
                ( % < Comparison
                    OpCode = 7,
                    (Val1 < Val2 -> Result = 1; Result = 0)
                );
                ( % = Comparison
                    OpCode = 8,
                    (Val1 = Val2 -> Result = 1; Result = 0)
                )
            ),
            intcode_result(
                NextMemory2,
                Pointer,
                RelativeBase,
                2,
                ParameterModes,
                Result,
                NextMemory3),
            NextPointer is Pointer + 4,
            intcode_step(
                state(NextPointer, RelativeBase, NextMemory3),
                Input,
                Output,
                FinalState,
                RemainingInput)
        )
    ).

test_intcode :-
    intcode([1, 1, 2, 0, 99], [], []),
    intcode([1, 0, 0, 0, 99], [], []),
    intcode([2, 3, 0, 3, 99], [], []),
    intcode([2, 4, 4, 5, 99, 0], [], []),
    intcode([1, 1, 1, 4, 99, 5, 6, 0, 99], [], []),
    intcode([1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50], [], []),
    intcode([3, 0, 4, 0, 99], [12], [12]),
    intcode([1002, 4, 3, 4, 33], [], []),
    EQ8 = [3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8],
    intcode(EQ8, [7], [0]),
    intcode(EQ8, [8], [1]),
    intcode(EQ8, [9], [0]),
    LT8 = [3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8],
    intcode(LT8, [7], [1]),
    intcode(LT8, [8], [0]),
    intcode(LT8, [9], [0]),
    Other8 = [
        3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006, 20, 31,
        1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1, 46, 104,
        999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99
    ],
    intcode(Other8, [6], [999]),
    intcode(Other8, [7], [999]),
    intcode(Other8, [8], [1000]),
    intcode(Other8, [9], [1001]),
    intcode(Other8, [10], [1001]),
    QUINE = [
        109, 1,
        204,-1,
        1001,100,1,100,
        1008,100,16,101,
        1006,101,0,
        99
    ],
    intcode(QUINE, [], QUINE),
    intcode([1102, 34915192, 34915192, 7, 4, 7, 99, 0], [], [1219070632396864]),
    intcode([104, 1125899906842624, 99], [], [1125899906842624]).


rotate_direction(up, 0, left).
rotate_direction(left, 0, down).
rotate_direction(down, 0, right).
rotate_direction(right, 0, up).
rotate_direction(up, 1, right).
rotate_direction(right, 1, down).
rotate_direction(down, 1, left).
rotate_direction(left, 1, up).


move_direction(up, -(X, Y), -(X, NY)) :- NY is Y + 1.
move_direction(down, -(X, Y), -(X, NY)) :- NY is Y - 1.
move_direction(right, -(X, Y), -(NX, Y)) :- NX is X + 1.
move_direction(left, -(X, Y), -(NX, Y)) :- NX is X - 1.


% Like Day 9, we run out of memory with this. Use the same workaround.
paint_robot(State, Result) :-
    empty_assoc(Grid),
    paint_robot(-(0, 0), up, State, Grid, Result).
paint_robot(Position, Direction, State, Grid, Result) :-
    (get_assoc(Position, Grid, CurrentColor); CurrentColor = 0),
    % Step intcode program to get both outputs
    intcode_step(State, [CurrentColor], PaintColor, NextState1, InputTail),
    % Handle the program completing at this point
    ((NextState1 = fin)
    -> (
        InputTail = [CurrentColor],
        Result = Grid
    )
    ; (
        InputTail = [],
        intcode_step(NextState1, [], Rotation, NextState2, []),
        % Paint and move
        put_assoc(Position, Grid, PaintColor, NextGrid),
        rotate_direction(Direction, Rotation, NextDirection),
        move_direction(NextDirection, Position, NextPosition),
        paint_robot(NextPosition, NextDirection, NextState2, NextGrid, Result)
    )).


robot_panel_count(Program, Count) :-
    ProgramState = state(0, 0, Program),
    paint_robot(ProgramState, Grid),
    assoc_to_list(Grid, Pairs),
    length(Pairs, Count).


% Find the size required to paint the given grid, then iterate through each
% element and set the desired color.
paint_row(_, _, [], _, _).
paint_row(OffsetX, GY, [Element|Row], X, Grid) :-
    NextX is X + 1,
    GX is X + OffsetX,
    (get_assoc(-(GX, GY), Grid, Element); Element = 0),
    paint_row(OffsetX, GY, Row, NextX, Grid).

paint_rows(_, _, [], _, _).
paint_rows(-(OffsetX, OffsetY), SizeX, [Row|Rows], Y, Grid) :-
    GY is Y + OffsetY,
    length(Row, SizeX),
    paint_row(OffsetX, GY, Row, 0, Grid),
    NextY is Y + 1,
    paint_rows(-(OffsetX, OffsetY), SizeX, Rows, NextY, Grid).

paint_grid(Canvas, Grid) :-
    assoc_to_keys(Grid, Positions),
    maplist([-(X, _), R]>>(R = X), Positions, XPositions),
    min_list(XPositions, MinX),
    max_list(XPositions, MaxX),
    maplist([-(_, Y), R]>>(R = Y), Positions, YPositions),
    min_list(YPositions, MinY),
    max_list(YPositions, MaxY),
    SizeX is MaxX - MinX + 1,
    SizeY is MaxY - MinY + 1,
    length(Canvas, SizeY),
    paint_rows(-(MinX, MinY), SizeX, Canvas, 0, Grid).


paint_registration(Program, Rego) :-
    ProgramState = state(0, 0, Program),
    empty_assoc(EmptyGrid),
    put_assoc(-(0, 0), EmptyGrid, 1, InitialGrid),
    paint_robot(-(0, 0), up, ProgramState, InitialGrid, Grid),
    paint_grid(Rego, Grid).


test :-
    test_replace(),
    test_padd_to(),
    test_address(),
    test_set_mem(),
    test_intcode().
