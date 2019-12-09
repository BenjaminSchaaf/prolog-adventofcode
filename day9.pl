% Partial copy of day 5, except now every address access can grow the amount of
% memory.

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


% Part 2 takes a while and generally runs out of stack space. 8GB per stack
% should be enough to complete it though, so use the following settings:
% set_prolog_stack(local, limit(8000000000)),
% set_prolog_stack(global, limit(8000000000)).
intcode(Memory, Input, Output) :-
    intcode(0, 0, Memory, Input, Output).
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
    test_replace(),
    test_padd_to(),
    test_address(),
    test_set_mem(),
    test_intcode().
