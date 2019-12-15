% Partial copy of day 5, except now every address access can grow the amount of
% memory. Memory manipulation is also rewritten to use mutated terms to increase
% performance.


padd_term(Term, Size, Result) :-
    compound_name_arity(Term, _, S),
    (
        S > Size
        -> Term = Result
        ; (
            PaddingSize is Size - S + 1,
            length(Padding, PaddingSize),
            maplist([E]>>(E = 0), Padding),
            Term =.. List,
            append(List, Padding, PaddedList),
            Result =.. PaddedList
        )
    ).

test_padd_term :-
    padd_term(a(0, 1, 2), 5, a(0, 1, 2, 0, 0, 0)),
    padd_term(a(0, 1, 2), 4, a(0, 1, 2, 0, 0)),
    padd_term(a(0, 1, 2), 3, a(0, 1, 2, 0)),
    padd_term(a(0, 1, 2), 2, a(0, 1, 2)),
    padd_term(a(0, 1, 2), 0, a(0, 1, 2)).


% address now needs to grow the memory if we access past the end
address(Memory, Pointer, Value, NextMemory) :-
    padd_term(Memory, Pointer, NextMemory),
    Arg is Pointer + 1,
    arg(Arg, NextMemory, Value).
address(Memory, Pointer, Offset, Value, NextMemory) :-
    Index is Pointer + Offset,
    address(Memory, Index, Value, NextMemory).

test_address :-
    address(a(3, 4, 5, 6), 1, 4, a(3, 4, 5, 6)),
    address(a(3, 4, 5, 6), 4, 0, a(3, 4, 5, 6, 0)).


% Setting memory may require increasing the amount of memory. This uses setarg
% which is incredibly evil but allows things to be fast. This is extra-logical,
% sadly.
set_mem(Memory, Pointer, Value, NextMemory) :-
    % Make sure NextMemory is a variable, this makes setarg less error prone
    var(NextMemory),

    padd_term(Memory, Pointer, NextMemory),
    % Evil: Use setarg to mutate NextMemory
    Arg is Pointer + 1,
    setarg(Arg, NextMemory, Value).

test_set_mem :-
    A = a(1, 2, -1),
    set_mem(A, 2, 3, B),
    A = B,
    B = a(1, 2, 3),
    set_mem(B, 3, 4, C),
    C = a(1, 2, 3, 4).


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
    M =.. [a|Memory],

    % From profiling, gc takes up 97% of cpu time. Disable the GC for intcode.
    current_prolog_flag(gc, GC),
    set_prolog_flag(gc, false),

    intcode(0, 0, M, Input, Output),

    set_prolog_flag(gc, GC).
intcode(Pointer, RelativeBase, InitialMemory, Input, Output) :-
    address(InitialMemory, Pointer, Operation, Memory),
    OpCode is mod(Operation, 100),
    ParameterModes is floor(Operation / 100),
    (
        ( % Stop
            OpCode = 99,
            Output = []
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
            intcode(NextPointer, RelativeBase, NextMemory, InputTail, Output)
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
            Output = [Value|OutputTail],
            NextPointer is Pointer + 2,
            intcode(NextPointer, RelativeBase, NextMemory, Input, OutputTail)
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
            intcode(AfterPointer, RelativeBase, NextMemory2, Input, Output)
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
            intcode(NextPointer, NextRelativeBase, NextMemory, Input, Output)
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
            intcode(NextPointer, RelativeBase, NextMemory3, Input, Output)
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


test :-
    test_padd_term(),
    test_address(),
    test_set_mem(),
    test_intcode().
