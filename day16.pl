digit_number(Code, Number) :-
    number(Code),
    Number is Code - 48,
    Number >= 0, Number < 10.
digit_number(Code, Number) :-
    number(Number),
    Number >= 0, Number < 10,
    Code is Number + 48.


digits_string(String, List) :-
    string(String),
    string_codes(String, Codes),
    maplist(digit_number, Codes, List).
digits_string(String, List) :-
    is_list(List),
    maplist(digit_number, Codes, List),
    string_codes(String, Codes).

test_digits_string :-
    digits_string("123", L1),
    L1 = [1, 2, 3],
    digits_string("12673170823", L2),
    L2 = [1, 2, 6, 7, 3, 1, 7, 0, 8, 2, 3],
    digits_string(S1, [1, 2, 3]),
    S1 = "123",
    digits_string(S2, [1, 2, 6, 7, 3, 1, 7, 0, 8, 2, 3]),
    S2 = "12673170823".

fft_multiplier(X, Y, Value) :-
    Index is mod(div(X, (Y + 1)), 4) + 1,
    arg(Index, a(1, 0, -1, 0), Value).

test_fft_multiplier :-
    fft_multiplier(0, 0, 1),
    fft_multiplier(1, 0, 0),
    fft_multiplier(2, 0, -1),
    fft_multiplier(3, 0, 0),
    fft_multiplier(4, 0, 1),
    fft_multiplier(5, 0, 0),
    fft_multiplier(6, 0, -1),
    fft_multiplier(7, 0, 0),
    fft_multiplier(8, 0, 1),
    fft_multiplier(9, 0, 0),
    fft_multiplier(0, 1, 1),
    fft_multiplier(1, 1, 1),
    fft_multiplier(2, 1, 0),
    fft_multiplier(3, 1, 0),
    fft_multiplier(4, 1, -1),
    fft_multiplier(5, 1, -1),
    fft_multiplier(6, 1, 0),
    fft_multiplier(7, 1, 0),
    fft_multiplier(8, 1, 1),
    fft_multiplier(9, 1, 1),
    fft_multiplier(0, 2, 1),
    fft_multiplier(1, 2, 1),
    fft_multiplier(2, 2, 1),
    fft_multiplier(3, 2, 0),
    fft_multiplier(4, 2, 0),
    fft_multiplier(5, 2, 0),
    fft_multiplier(6, 2, -1),
    fft_multiplier(7, 2, -1),
    fft_multiplier(8, 2, -1),
    fft_multiplier(9, 2, 0).


fft(Digits, Result) :-
    length(Digits, Size),
    A =.. [a|Digits],
    fft_(A, 0, Size, Result).

fft_(_, Size, Size, []).
fft_(Digits, Index, Size, [Value|ValueTail]) :-
    Index < Size,
    RowSize is Size - Index,
    fft_row_(Index, 0, RowSize, Digits, 0, Result),
    Value is mod(abs(Result), 10),
    NextIndex is Index + 1,
    fft_(Digits, NextIndex, Size, ValueTail).

fft_row_(_, Size, Size, _, V, V).
fft_row_(Y, X, Size, Digits, Value, Sum) :-
    X < Size,
    fft_multiplier(X, Y, Multiplier),
    Index is 1 + Y + X,
    arg(Index, Digits, Digit),
    NextValue is Value + (Digit * Multiplier),
    NextX is X + 1,
    fft_row_(Y, NextX, Size, Digits, NextValue, Sum).

test_fft :-
    fft([1, 2, 3, 4, 5, 6, 7, 8], [4, 8, 2, 2, 6, 1, 5, 8]),
    fft([4, 8, 2, 2, 6, 1, 5, 8], [3, 4, 0, 4, 0, 4, 3, 8]).


phased_fft(0, Digits, Digits).
phased_fft(Phase, Digits, Result) :-
    Phase > 0,
    NextPhase is Phase - 1,
    fft(Digits, NextDigits),
    % Progress reporting
    write(Phase),
    write("\n"),
    phased_fft(NextPhase, NextDigits, Result).

test_phased_fft :-
    phased_fft(
        100,
        [
            8, 0, 8, 7, 1, 2, 2, 4, 5, 8, 5, 9, 1, 4, 5, 4, 6, 6, 1, 9, 0, 8, 3,
            2, 1, 8, 6, 4, 5, 5, 9, 5
        ],
        [2, 4, 1, 7, 6, 1, 7, 6|_]),
    phased_fft(
        100,
        [
            1, 9, 6, 1, 7, 8, 0, 4, 2, 0, 7, 2, 0, 2, 2, 0, 9, 1, 4, 4, 9, 1, 6,
            0, 4, 4, 1, 8, 9, 9, 1, 7
        ],
        [7, 3, 7, 4, 5, 4, 1, 8|_]),
    phased_fft(
        100,
        [
            6, 9, 3, 1, 7, 1, 6, 3, 4, 9, 2, 9, 4, 8, 6, 0, 6, 3, 3, 5, 9, 9, 5,
            9, 2, 4, 3, 1, 9, 8, 7, 3
        ],
        [5, 2, 4, 3, 2, 1, 3, 3|_]).


partial_sums(List, Result) :-
    same_length(List, Result),
    partial_sums_(0, List, Result).

partial_sums_(_, [], []).
partial_sums_(Sum, [Value|ValueTail], [Result|ResultTail]) :-
    S is Sum + Value,
    Result is mod(abs(S), 10),
    partial_sums_(S, ValueTail, ResultTail).

test_partial_sums :-
    partial_sums([1, 2, 3, 4, 5], [1, 3, 6, 10, 15]).


% Part 2 is dumb. Since the "offset" is near the end and the 2nd half of digits
% can be calculated using partial sums we just use that instead of trying to
% actually do fft. A fast enough general solution to this problem isn't
% realistic for prolog.
part2_fft(DigitString, Result) :-
    sub_string(DigitString, 0, 7, _, OffsetString),
    number_string(Offset, OffsetString),
    digits_string(DigitString, Digits),
    length(Digits, DigitsSize),
    Size is DigitsSize * 10000 - Offset,
    reverse(Digits, ReverseDigits),
    % Construct a list of repeating digits of ReverseDigits of Size
    append(ReverseDigits, InfiniteReverseDigits, InfiniteReverseDigits),
    length(InitialDigits, Size),
    append(InitialDigits, _, InfiniteReverseDigits),

    part2_fft_(100, InitialDigits, PartialSums),
    reverse(PartialSums, ReversedPartialSums),
    digits_string(ResultString, ReversedPartialSums),
    sub_string(ResultString, 0, 8, _, Result).

part2_fft_(0, Digits, Digits).
part2_fft_(Phase, Digits, Result) :-
    Phase > 0,
    % Progress reporting
    write(Phase),
    write("\n"),
    partial_sums(Digits, NextDigits),
    NextPhase is Phase - 1,
    part2_fft_(NextPhase, NextDigits, Result).

test_part2_fft :-
    part2_fft("03036732577212944063491565474664", "84462026"),
    part2_fft("02935109699940807407585447034323", "78725270"),
    part2_fft("03081770884921959731165446850517", "53553731").
