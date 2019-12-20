chemical(Data, Chemical) :-
    split_string(Data, " ", "", [Amount, Name]),
    number_string(A, Amount),
    atom_string(N, Name),
    Chemical =.. [N, A].

reaction(Data, reaction(Inputs, Output)) :-
    split_string(Data, "=", "> ", [InputData, OutputData]),

    split_string(InputData, ",", " ", InputsData),
    maplist(chemical, InputsData, Inputs),

    %% sub_string(OutputData, 2, _, 0, OutputData2),
    split_string(OutputData, ",", " ", OutputsData),
    maplist(chemical, OutputsData, [Output]).

reactions(Data, Reactions) :-
    split_string(Data, "\n", "", Lines),
    maplist(reaction, Lines, Reactions).

test_reactions :-
    reactions(
        "10 ORE => 10 A\n1 ORE => 1 B\n7 A, 1 B => 1 C\n7 A, 1 C => 1 D",
        [
            reaction(['ORE'(10)], 'A'(10)),
            reaction(['ORE'(1)], 'B'(1)),
            reaction(['A'(7), 'B'(1)], 'C'(1)),
            reaction(['A'(7), 'C'(1)], 'D'(1))
        ]).


add_assoc_chemicals(Result, [], Result, _).
add_assoc_chemicals(Current, [Element|Tail], Result, Multiplier) :-
    Element =.. [Chemical, Amount],
    (get_assoc(Chemical, Current, CurrentAmount); CurrentAmount = 0),
    NextAmount is CurrentAmount + Amount * Multiplier,
    put_assoc(Chemical, Current, NextAmount, Next),
    add_assoc_chemicals(Next, Tail, Result, Multiplier).

test_add_assoc_chemicals :-
    empty_assoc(Empty),
    put_assoc(a, Empty, 12, Init),
    add_assoc_chemicals(Init, [b(2), a(3), b(1), c(4)], Result, 2),
    get_assoc(a, Result, 18),
    get_assoc(b, Result, 6),
    get_assoc(c, Result, 8).


fuel_requirements(Requirements, Amount) :-
    empty_assoc(Init),
    put_assoc('FUEL', Init, Amount, Requirements).


reaction_sequence(Reactions, Requirements, Resources) :-
    empty_assoc(EmptyAssoc),
    reaction_sequence_(
        Reactions, Requirements, EmptyAssoc, EmptyAssoc, Resources).

reaction_sequence_(Reactions, Requirements, Surplus, Resources, Result) :-
    % Find a required chemical
    gen_assoc(Chemical, Requirements, AmountRequired1),
    % Subtract any amount in surplus
    (get_assoc(Chemical, Surplus, ExistingAmount); ExistingAmount = 0),
    AmountRequired2 is max(0, AmountRequired1 - ExistingAmount),
    % Update remaining surplus
    RemainingSurplus is max(0, ExistingAmount - AmountRequired1),
    put_assoc(Chemical, Surplus, RemainingSurplus, NextSurplus1),
    (AmountRequired2 > 0
        -> (
            % Find a reaction that produces it
            Output =.. [Chemical, OutputAmount],
            member(reaction(Inputs, Output), Reactions),
            !,
            ReactionCount is ceil(AmountRequired2 / OutputAmount),
            Amount is OutputAmount * ReactionCount,
            % Calculate new surplus from output
            AmountSurplus is max(0, Amount - AmountRequired2),
            ChemicalSurplus =.. [Chemical, AmountSurplus],
            add_assoc_chemicals(
                NextSurplus1, [ChemicalSurplus], NextSurplus2, 1),
            % Add output to total
            add_assoc_chemicals(
                Resources, [Output], NextResources, ReactionCount),
            % Add inputs to requirements
            add_assoc_chemicals(
                Requirements, Inputs, NextRequirements1, ReactionCount)
        )
        ; (
            !,
            NextSurplus2 = NextSurplus1,
            NextResources = Resources,
            NextRequirements1 = Requirements
        )
    ),
    !,
    % Remove requirements for chemical
    del_assoc(Chemical, NextRequirements1, _, NextRequirements2),
    reaction_sequence_(
        Reactions, NextRequirements2, NextSurplus2, NextResources, Result).
% Base case for when required resources have no reactions to make them
reaction_sequence_(Reactions, Requirements, _, Resources, Result) :-
    assoc_to_list(Requirements, [-(Chemical, Amount)]),
    Output =.. [Chemical, _],
    \+ member(reaction(_, Output), Reactions),
    !,
    (get_assoc(Chemical, Resources, CurrentAmount); CurrentAmount = 0),
    NextAmount is CurrentAmount + Amount,
    put_assoc(Chemical, Resources, NextAmount, Result).

test_reaction_sequence :-
    reactions(
        "10 ORE => 10 A\n1 ORE => 1 B\n7 A, 1 B => 1 C\n7 A, 1 C => 1 D\n7 A, 1 D => 1 E\n7 A, 1 E => 1 FUEL",
        Test1),
    fuel_requirements(Test1Requirements, 1),
    reaction_sequence(Test1, Test1Requirements, Test1Result),
    get_assoc('ORE', Test1Result, 31),
    get_assoc('A', Test1Result, 30),
    get_assoc('B', Test1Result, 1),
    get_assoc('C', Test1Result, 1),
    get_assoc('D', Test1Result, 1),
    get_assoc('E', Test1Result, 1),
    get_assoc('FUEL', Test1Result, 1).


ore_requirement(ReactionData, Count) :-
    reactions(ReactionData, Reactions),
    fuel_requirements(Requirements, 1),
    reaction_sequence(Reactions, Requirements, Resources),
    get_assoc('ORE', Resources, Count).

test_ore_requirement :-
    ore_requirement(
        "10 ORE => 10 A\n1 ORE => 1 B\n7 A, 1 B => 1 C\n7 A, 1 C => 1 D\n7 A, 1 D => 1 E\n7 A, 1 E => 1 FUEL",
        31),
    ore_requirement(
        "9 ORE => 2 A\n8 ORE => 3 B\n7 ORE => 5 C\n3 A, 4 B => 1 AB\n5 B, 7 C => 1 BC\n4 C, 1 A => 1 CA\n2 AB, 3 BC, 4 CA => 1 FUEL",
        165),
    ore_requirement(
        "157 ORE => 5 NZVS\n165 ORE => 6 DCFZ\n44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL\n12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ\n179 ORE => 7 PSHF\n177 ORE => 5 HKGWZ\n7 DCFZ, 7 PSHF => 2 XJWVT\n165 ORE => 2 GPVTF\n3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT",
        13312),
    ore_requirement(
        "2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG\n17 NVRVD, 3 JNWZP => 8 VPVL\n53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL\n22 VJHF, 37 MNCFX => 5 FWMGM\n139 ORE => 4 NVRVD\n144 ORE => 7 JNWZP\n5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC\n5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV\n145 ORE => 6 MNCFX\n1 NVRVD => 8 CXFTF\n1 VJHF, 6 MNCFX => 4 RFSQX\n176 ORE => 6 VJHF",
        180697),
    ore_requirement(
        "171 ORE => 8 CNZTR\n7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL\n114 ORE => 4 BHXH\n14 VRPVC => 6 BMBT\n6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL\n6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT\n15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW\n13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW\n5 BMBT => 4 WPTQ\n189 ORE => 9 KTJDG\n1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP\n12 VRPVC, 27 CNZTR => 2 XDBXC\n15 KTJDG, 12 BHXH => 5 XCVML\n3 BHXH, 2 VRPVC => 7 MZWV\n121 ORE => 7 VRPVC\n7 XCVML => 6 RJRHP\n5 BHXH, 4 VRPVC => 5 LTCX",
        2210736).


fuel_produced(ReactionData, Ore, Fuel) :-
    reactions(ReactionData, Reactions),
    fuel_produced_(Reactions, 0, 1000000000000, Ore, Fuel).

% Binary search
fuel_produced_(Reactions, Offset, 1, OreTarget, Result) :-
    !,
    Result = Offset,
    % Sanity check
    fuel_requirements(Requirements, Offset),
    reaction_sequence(Reactions, Requirements, Resources),
    get_assoc('ORE', Resources, Ore),
    Ore =< OreTarget.
fuel_produced_(Reactions, Offset, Size, OreTarget, Result) :-
    !,
    HalfSize is ceil(Size / 2),
    HalfPoint is Offset + HalfSize,
    fuel_requirements(Requirements, HalfPoint),
    reaction_sequence(Reactions, Requirements, Resources),
    get_assoc('ORE', Resources, Ore),
    (Ore >= OreTarget
        -> fuel_produced_(Reactions, Offset, HalfSize, OreTarget, Result)
        ; (
            NextOffset is Offset + HalfSize,
            fuel_produced_(Reactions, NextOffset, HalfSize, OreTarget, Result)
        )
    ).

test_fuel_produced :-
    fuel_produced(
        "157 ORE => 5 NZVS\n165 ORE => 6 DCFZ\n44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL\n12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ\n179 ORE => 7 PSHF\n177 ORE => 5 HKGWZ\n7 DCFZ, 7 PSHF => 2 XJWVT\n165 ORE => 2 GPVTF\n3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT",
        1000000000000,
        82892753),
    fuel_produced(
        "2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG\n17 NVRVD, 3 JNWZP => 8 VPVL\n53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL\n22 VJHF, 37 MNCFX => 5 FWMGM\n139 ORE => 4 NVRVD\n144 ORE => 7 JNWZP\n5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC\n5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV\n145 ORE => 6 MNCFX\n1 NVRVD => 8 CXFTF\n1 VJHF, 6 MNCFX => 4 RFSQX\n176 ORE => 6 VJHF",
        1000000000000,
        5586022),
    fuel_produced(
        "171 ORE => 8 CNZTR\n7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL\n114 ORE => 4 BHXH\n14 VRPVC => 6 BMBT\n6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL\n6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT\n15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW\n13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW\n5 BMBT => 4 WPTQ\n189 ORE => 9 KTJDG\n1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP\n12 VRPVC, 27 CNZTR => 2 XDBXC\n15 KTJDG, 12 BHXH => 5 XCVML\n3 BHXH, 2 VRPVC => 7 MZWV\n121 ORE => 7 VRPVC\n7 XCVML => 6 RJRHP\n5 BHXH, 4 VRPVC => 5 LTCX",
        1000000000000,
        460664).


test :-
    test_reactions(),
    test_add_assoc_chemicals(),
    test_reaction_sequence(),
    test_ore_requirement(),
    test_fuel_produced().
