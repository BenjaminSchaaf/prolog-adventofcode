:- use_module(library(clpfd)).

apply_gravity(-(X, Y, Z), -(OX, OY, OZ), -(DX, DY, DZ)) :-
    DX is sign(OX - X),
    DY is sign(OY - Y),
    DZ is sign(OZ - Z).

test_apply_gravity :-
    apply_gravity(-(0, 1, -1), -(0, 0, 0), -(0, -1, 1)).


simulation_step(Moons, NextMoons) :-
    maplist(
        [moon(-(X, Y, Z), -(DX, DY, DZ)), moon(NextPosition, NextVelocity)]>>(
            maplist(
                [moon(P, _), GX, GY, GZ]>>
                    apply_gravity(-(X, Y, Z), P, -(GX, GY, GZ)),
                Moons,
                GravityXList,
                GravityYList,
                GravityZList),
            sum_list(GravityXList, GravityX),
            sum_list(GravityYList, GravityY),
            sum_list(GravityZList, GravityZ),
            NDX is DX + GravityX,
            NDY is DY + GravityY,
            NDZ is DZ + GravityZ,
            NextVelocity = -(NDX, NDY, NDZ),
            NX is X + NDX,
            NY is Y + NDY,
            NZ is Z + NDZ,
            NextPosition = -(NX, NY, NZ)
        ),
        Moons, NextMoons).

test_simulation_step :-
    simulation_step([], []),
    simulation_step(
        [
            moon(-(-1, 0, 2), -(0, 0, 0)),
            moon(-(2, -10, -7), -(0, 0, 0)),
            moon(-(4, -8, 8), -(0, 0, 0)),
            moon(-(3, 5, -1), -(0, 0, 0))
        ],
        [
            moon(-(2, -1,  1), -( 3, -1, -1)),
            moon(-(3, -7, -4), -( 1,  3,  3)),
            moon(-(1, -7,  5), -(-3,  1, -3)),
            moon(-(2,  2,  0), -(-1, -3,  1))
        ]).


energy(Moons, TotalEnergy) :-
    maplist(
        [moon(-(X, Y, Z), -(DX, DY, DZ)), Energy]>>(
            PE is abs(X) + abs(Y) + abs(Z),
            KE is abs(DX) + abs(DY) + abs(DZ),
            Energy is PE * KE
        ),
        Moons,
        EnergyList),
    sum_list(EnergyList, TotalEnergy).

test_energy :-
    energy(
        [
            moon(-(2,  1, -3), -(-3, -2,  1)),
            moon(-(1, -8,  0), -(-1,  1,  3)),
            moon(-(3, -6,  1), -( 3,  2, -3)),
            moon(-(2,  0,  4), -( 1, -1, -1))
        ],
        179).


simulate_for_steps(Moons, 0, Moons).
simulate_for_steps(Moons, Count, Result) :-
    simulation_step(Moons, NextMoons),
    NextCount #= Count - 1,
    simulate_for_steps(NextMoons, NextCount, Result).

% Least Common Multiple
lcm(A, B, M) :-
    gcd(A, B, GCD),
    M is (A * B) / GCD.

test_lcm :-
    lcm(3, 5, 15),
    lcm(5, 3, 15),
    lcm(5, 5, 5).


lcm_list([A, B], M) :-
    lcm(A, B, M).
lcm_list([A|Tail], M) :-
    lcm_list(Tail, B),
    lcm(A, B, M).

test_lcm_list :-
    lcm_list([3, 5], 15),
    lcm_list([3, 5, 15], 15),
    lcm_list([3, 5, 20], 60).


% Greatest Common Divisor
gcd(A, 0, A).
gcd(A, A, A).
gcd(A, B, D) :-
    A < B, gcd(B, A, D).
gcd(A, B, D) :-
    A >= B, C is mod(A, B), gcd(B, C, D).


simulation_repeat_count(Moons, Count) :-
    % Find the number of iterations required to repeat the X axis
    maplist(
        [moon(-(X, _, _), -(DX, _, _)), Goal]>>(
            Goal = moon(-(X, _, _), -(DX, _, _))
        ),
        Moons,
        InitialX),
    simulate_for_steps(Moons, CountX, InitialX),
    CountX > 1,
    % Do the same for Y
    maplist(
        [moon(-(_, Y, _), -(_, DY, _)), Goal]>>(
            Goal = moon(-(_, Y, _), -(_, DY, _))
        ),
        Moons,
        InitialY),
    simulate_for_steps(Moons, CountY, InitialY),
    CountY > 1,
    % And Z
    maplist(
        [moon(-(_, _, Z), -(_, _, DZ)), Goal]>>(
            Goal = moon(-(_, _, Z), -(_, _, DZ))
        ),
        Moons,
        InitialZ),
    simulate_for_steps(Moons, CountZ, InitialZ),
    CountZ > 1,
    % Calculate total required count
    lcm_list([CountX, CountY, CountZ], Count).
