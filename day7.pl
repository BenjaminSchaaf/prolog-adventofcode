% We can reuse intcode from day 5
:- [day5].


permutation(Base, Result) :-
    same_length(Base, Result),
    permutation_(Base, Result).
permutation_([], []).
permutation_([X|Tail], Result) :-
    select(X, Result, Remaining),
    permutation_(Tail, Remaining).

test_permutation :-
    permutation([1, 2, 3], [1, 2, 3]),
    permutation([1, 2, 3], [1, 3, 2]),
    permutation([1, 2, 3], [2, 1, 3]),
    permutation([1, 2, 3], [3, 1, 2]),
    permutation([1, 2, 3], [2, 3, 1]),
    permutation([1, 2, 3], [3, 2, 1]).


amplifier(Program, PhaseSetting, Signal) :-
    amplifier(Program, PhaseSetting, 0, Signal).
amplifier(_, [], Input, Input).
amplifier(Program, [PhaseSetting|Tail], Input, Signal) :-
    intcode(Program, _, [PhaseSetting, Input], [Result]),
    amplifier(Program, Tail, Result, Signal).

test_amplifier :-
    amplifier(
        [3, 15, 3, 16, 1002, 16, 10, 16, 1, 16, 15, 15, 4, 15, 99, 0, 0],
        [4, 3, 2, 1, 0],
        43210),
    amplifier(
        [
            3, 23,
            3, 24,
            1002, 24, 10, 24,
            1002, 23, -1, 23,
            101, 5, 23, 23,
            1, 24, 23, 23,
            4, 23,
            99,
            0, 0
        ],
        [0, 1, 2, 3, 4],
        54321),
    amplifier(
        [
            3, 31,
            3, 32,
            1002, 32, 10, 32,
            1001, 31, -2, 31,
            1007, 31, 0, 33,
            1002, 33, 7, 33,
            1, 33, 31, 31,
            1, 32, 31, 31,
            4, 31,
            99,
            0, 0, 0
        ],
        [1, 0, 4, 3, 2],
        65210).


best_amplifier_phase_setting(Program, Signal) :-
    % Instantiating permutations before finding the best phase setting is
    % significantly faster than doing it all in one go.
    findall(P, permutation([0, 1, 2, 3, 4], P), Permutations),
    maplist(amplifier(Program), Permutations, Signals),
    max_list(Signals, Signal).

test_best_amplifier_phase_setting :-
    best_amplifier_phase_setting(
        [3, 15, 3, 16, 1002, 16, 10, 16, 1, 16, 15, 15, 4, 15, 99, 0, 0],
        43210),
    best_amplifier_phase_setting(
        [
            3, 23,
            3, 24,
            1002, 24, 10, 24,
            1002, 23, -1, 23,
            101, 5, 23, 23,
            1, 24, 23, 23,
            4, 23,
            99,
            0, 0
        ],
        54321),
    best_amplifier_phase_setting([
            3, 31,
            3, 32,
            1002, 32, 10, 32,
            1001, 31, -2, 31,
            1007, 31, 0, 33,
            1002, 33, 7, 33,
            1, 33, 31, 31,
            1, 32, 31, 31,
            4, 31,
            99,
            0, 0, 0
        ],
        65210).


amplifier_loop(Program, PhaseSetting, Signal) :-
    PhaseSetting = [P0, P1, P2, P3, P4],
    intcode(Program, _, [P0, 0|O4], O0),
    intcode(Program, _, [P1|O0], O1),
    intcode(Program, _, [P2|O1], O2),
    intcode(Program, _, [P3|O2], O3),
    append(O4, [Signal], O4Comb),
    intcode(Program, _, [P4|O3], O4Comb).

test_amplifier_loop :-
    amplifier_loop(
        [
            3, 26,
            1001, 26, -4, 26,
            3, 27,
            1002, 27, 2, 27,
            1, 27, 26, 27,
            4, 27,
            1001, 28, -1, 28,
            1005, 28, 6,
            99,
            0, 0, 5
        ],
        [9, 8, 7, 6, 5],
        139629729),
    amplifier_loop(
        [
            3, 52,
            1001, 52, -5, 52,
            3, 53,
            1, 52, 56, 54,
            1007, 54, 5, 55,
            1005, 55, 26,
            1001, 54, -5, 54,
            1105, 1, 12,
            1, 53, 54, 53,
            1008, 54, 0, 55,
            1001, 55, 1, 55,
            2, 53, 55, 53,
            4, 53,
            1001, 56, -1, 56,
            1005, 56, 6,
            99,
            0, 0, 0, 0, 10
        ],
        [9, 7, 8, 5, 6],
        18216).


best_amplifier_loop_phase_setting(Program, Signal) :-
    findall(P, permutation([5, 6, 7, 8, 9], P), Permutations),
    maplist(amplifier_loop(Program), Permutations, Signals),
    max_list(Signals, Signal).

test_best_amplifier_loop_phase_setting :-
    best_amplifier_loop_phase_setting(
        [
            3, 26,
            1001, 26, -4, 26,
            3, 27,
            1002, 27, 2, 27,
            1, 27, 26, 27,
            4, 27,
            1001, 28, -1, 28,
            1005, 28, 6,
            99,
            0, 0, 5
        ],
        139629729),
    best_amplifier_loop_phase_setting(
        [
            3, 52,
            1001, 52, -5, 52,
            3, 53,
            1, 52, 56, 54,
            1007, 54, 5, 55,
            1005, 55, 26,
            1001, 54, -5, 54,
            1105, 1, 12,
            1, 53, 54, 53,
            1008, 54, 0, 55,
            1001, 55, 1, 55,
            2, 53, 55, 53,
            4, 53,
            1001, 56, -1, 56,
            1005, 56, 6,
            99,
            0, 0, 0, 0, 10
        ],
        18216).


test :-
    test_permutation(),
    test_amplifier(),
    test_best_amplifier_phase_setting(),
    test_amplifier_loop(),
    test_best_amplifier_loop_phase_setting().
