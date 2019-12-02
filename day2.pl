replace([_|Tail], 0, Element, [Element|Tail]).
replace([Head|Tail], Index, Element, [Head|ResultTail]) :-
    NextIndex is Index - 1,
    replace(Tail, NextIndex, Element, ResultTail).

test_replace :-
    replace([1, 2, 3], 1, 4, [1, 4, 3]).

%% This solves part 1 and part 2, it's just a matter of where you put the
%% variables.
intcode(Memory, ResultingMemory) :-
    intcode(0, Memory, ResultingMemory).
intcode(Pointer, Memory, ResultingMemory) :-
    Pointer1 is Pointer + 1,
    Pointer2 is Pointer + 2,
    Pointer3 is Pointer + 3,
    Pointer4 is Pointer + 4,
    nth0(Pointer, Memory, Op),
    (
        (
            Op = 99,
            ResultingMemory = Memory
        );
        (
            nth0(Pointer1, Memory, Val1Index),
            nth0(Pointer2, Memory, Val2Index),
            nth0(Pointer3, Memory, ResultIndex),
            nth0(Val1Index, Memory, Val1),
            nth0(Val2Index, Memory, Val2),
            (
                (
                    Op = 1,
                    Result is Val1 + Val2,
                    replace(Memory, ResultIndex, Result, NextMemory)
                );
                (
                    Op = 2,
                    Result is Val1 * Val2,
                    replace(Memory, ResultIndex, Result, NextMemory)
                )
            ),
            intcode(Pointer4, NextMemory, ResultingMemory)
        )
    ).

test_intcode :-
    intcode([1, 1, 2, 0, 99], [3, 1, 2, 0, 99]),
    intcode([1, 0, 0, 0, 99], [2, 0, 0, 0, 99]),
    intcode([2, 3, 0, 3, 99], [2, 3, 0, 6, 99]),
    intcode([2, 4, 4, 5, 99, 0], [2, 4, 4, 5, 99, 9801]),
    intcode([1, 1, 1, 4, 99, 5, 6, 0, 99], [30, 1, 1, 4, 2, 5, 6, 0, 99]),
    intcode([1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50], [3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50]).
