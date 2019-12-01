:- use_module(library(pio)).

%% Part 1
fuel(Mass, Fuel) :-
    Fuel is floor(Mass / 3) - 2.

test_fuel :-
    fuel(12, 2),
    fuel(14, 2),
    fuel(1969, 654),
    fuel(100756, 33583).


fuel_total([], 0).
fuel_total([Mass|Tail], TotalFuel) :-
    fuel_total(Tail, TailFuel),
    fuel(Mass, Fuel),
    TotalFuel is TailFuel + Fuel.

test_fuel_total :-
    fuel_total([12, 14], 4),
    fuel_total([12, 1969, 100756], 34239).


%% Part 2
fuel_adjusted(Mass, AdjustedFuel) :-
    fuel(Mass, Fuel),
    (
        (
            Fuel > 0,
            fuel_adjusted(Fuel, FuelFuel),
            AdjustedFuel is Fuel + FuelFuel);
        (
            AdjustedFuel is 0)).

test_adjusted_fuel :-
    fuel_adjusted(14, 2),
    fuel_adjusted(1969, 966),
    fuel_adjusted(100756, 50346).


fuel_adjusted_total([], 0).
fuel_adjusted_total([Mass|Tail], TotalFuel) :-
    fuel_adjusted_total(Tail, TailFuel),
    fuel_adjusted(Mass, Fuel),
    TotalFuel is TailFuel + Fuel.

test_fuel_adjusted_total :-
    fuel_adjusted_total([12, 14], 4),
    fuel_adjusted_total([14, 1969], 968),
    fuel_adjusted_total([14, 1969, 100756], 51314).


test :-
    test_fuel(),
    test_fuel_total(),
    test_adjusted_fuel(),
    test_fuel_adjusted_total().
