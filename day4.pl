sorted([]).
sorted([_]).
sorted([X,Y|Tail]) :-
    X =< Y,
    sorted([Y|Tail]).


adjacent2([X, X|_]).
adjacent2([_|Tail]) :-
    adjacent2(Tail).


password(Password) :-
    string_length(Password, 6),
    string_codes(Password, Codes),
    sorted(Codes),
    adjacent2(Codes).

test_password :-
    password("111111"),
    \+ password("223450"),
    \+ password("123789").


password_in_range(Password, RangeStart, RangeEnd) :-
    between(RangeStart, RangeEnd, Number),
    number_string(Number, Password),
    password(Password).


count_passwords_in_range(Count, RangeStart, RangeEnd) :-
    setof(P, password_in_range(P, RangeStart, RangeEnd), Passwords),
    length(Passwords, Count).


% Find a pair and only a pair
adjacent_only2([X, X]).
adjacent_only2([X, X, Y|_]) :-
    X \= Y.
adjacent_only2([X, Y|Tail]) :-
    X \= Y,
    adjacent_only2([Y|Tail]).
% Ignore larger groups
adjacent_only2([X, X, X|Tail]) :-
    nth0(0, Tail, X)
    -> adjacent_only2([X, X|Tail])
    ; adjacent_only2(Tail).

test_adjacent_only2 :-
    adjacent_only2([0, 0]),
    adjacent_only2([0, 0, 1]),
    adjacent_only2([1, 0, 0]),
    \+ adjacent_only2([0, 0, 0]),
    \+ adjacent_only2([0, 1, 0]),
    \+ adjacent_only2([0, 1, 0, 1]),
    adjacent_only2([0, 1, 0, 0]),
    adjacent_only2([0, 0, 0, 1, 0, 0]),
    adjacent_only2([0, 0, 1, 0, 0, 0]).


password2(Password) :-
    string_length(Password, 6),
    string_codes(Password, Codes),
    sorted(Codes),
    adjacent_only2(Codes).

test_password2 :-
    password2("112233"),
    password2("111122"),
    \+ password2("123444"),
    \+ password2("223450"),
    \+ password2("123789").


password2_in_range(Password, RangeStart, RangeEnd) :-
    between(RangeStart, RangeEnd, Number),
    number_string(Number, Password),
    password2(Password).


count_passwords2_in_range(Count, RangeStart, RangeEnd) :-
    setof(P, password2_in_range(P, RangeStart, RangeEnd), Passwords),
    length(Passwords, Count).


test :-
    test_password(),
    test_adjacent_only2(),
    test_password2().
