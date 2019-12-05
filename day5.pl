%% Copied from day 2
replace([_|Tail], 0, Element, [Element|Tail]).
replace([Head|Tail], Index, Element, [Head|ResultTail]) :-
    NextIndex is Index - 1,
    replace(Tail, NextIndex, Element, ResultTail).

test_replace :-
    replace([1, 2, 3], 1, 4, [1, 4, 3]).


address(Memory, Pointer, Offset, Value) :-
    Index is Pointer + Offset,
    nth0(Index, Memory, Value).


intcode_parameter(Memory, Pointer, Index, Modes, Parameter) :-
    Mode is mod(floor(Modes / 10**Index), 10),
    AddressPointer is Pointer + Index + 1,
    (
        (
            Mode = 0,
            nth0(AddressPointer, Memory, ParameterAddress),
            nth0(ParameterAddress, Memory, Parameter)
        );
        (Mode = 1, nth0(AddressPointer, Memory, Parameter))
    ).


%% Slightly more complicated version of day2
intcode(Memory, ResultingMemory, Input, Output) :-
    intcode(0, Memory, ResultingMemory, Input, Output).
intcode(Pointer, Memory, ResultingMemory, Input, Output) :-
    nth0(Pointer, Memory, Operation),
    OpCode is mod(Operation, 100),
    ParameterModes is floor(Operation / 100),
    (
        (
            OpCode = 99,
            ResultingMemory = Memory,
            Output = []
        );
        (
            OpCode = 3,
            Input = [Value|InputTail],
            address(Memory, Pointer, 1, Address),
            replace(Memory, Address, Value, NextMemory),
            NextPointer is Pointer + 2,
            intcode(NextPointer, NextMemory, ResultingMemory, InputTail, Output)
        );
        (
            OpCode = 4,
            intcode_parameter(Memory, Pointer, 0, ParameterModes, Value),
            Output = [Value|OutputTail],
            NextPointer is Pointer + 2,
            intcode(NextPointer, Memory, ResultingMemory, Input, OutputTail)
        );
        (
            (OpCode = 5; OpCode = 6),
            intcode_parameter(Memory, Pointer, 0, ParameterModes, Condition),
            intcode_parameter(Memory, Pointer, 1, ParameterModes, NextPointer),
            (
                ((OpCode = 5, Condition \= 0); (OpCode = 6, Condition = 0))
                -> intcode(NextPointer, Memory, ResultingMemory, Input, Output)
                ; (
                    AfterPointer is Pointer + 3,
                    intcode(AfterPointer, Memory, ResultingMemory, Input, Output)
                )
            )
        );
        (
            intcode_parameter(Memory, Pointer, 0, ParameterModes, Val1),
            intcode_parameter(Memory, Pointer, 1, ParameterModes, Val2),
            address(Memory, Pointer, 3, Address),
            (
                (OpCode = 1, Result is Val1 + Val2);
                (OpCode = 2, Result is Val1 * Val2);
                (
                    OpCode = 7,
                    (Val1 < Val2 -> Result = 1; Result = 0)
                );
                (
                    OpCode = 8,
                    (Val1 = Val2 -> Result = 1; Result = 0)
                )
            ),
            replace(Memory, Address, Result, NextMemory),
            NextPointer is Pointer + 4,
            intcode(NextPointer, NextMemory, ResultingMemory, Input, Output)
        )
    ).

test_intcode :-
    intcode([1, 1, 2, 0, 99], [3, 1, 2, 0, 99], [], []),
    intcode([1, 0, 0, 0, 99], [2, 0, 0, 0, 99], [], []),
    intcode([2, 3, 0, 3, 99], [2, 3, 0, 6, 99], [], []),
    intcode([2, 4, 4, 5, 99, 0], [2, 4, 4, 5, 99, 9801], [], []),
    intcode([1, 1, 1, 4, 99, 5, 6, 0, 99], [30, 1, 1, 4, 2, 5, 6, 0, 99], [], []),
    intcode([1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50], [3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50], [], []),
    intcode([3, 0, 4, 0, 99], [12, 0, 4, 0, 99], [12], [12]),
    intcode([1002,4,3,4,33], [1002, 4, 3, 4, 99], [], []),
    EQ8 = [3,9,8,9,10,9,4,9,99,-1,8],
    intcode(EQ8, _, [7], [0]),
    intcode(EQ8, _, [8], [1]),
    intcode(EQ8, _, [9], [0]),
    LT8 = [3,9,7,9,10,9,4,9,99,-1,8],
    intcode(LT8, _, [7], [1]),
    intcode(LT8, _, [8], [0]),
    intcode(LT8, _, [9], [0]),
    Other8 = [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,
              1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,
              999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99],
    intcode(Other8, _, [6], [999]),
    intcode(Other8, _, [7], [999]),
    intcode(Other8, _, [8], [1000]),
    intcode(Other8, _, [9], [1001]),
    intcode(Other8, _, [10], [1001]).


test :-
    test_replace(),
    test_intcode().
