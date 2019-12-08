string_code_number(Index, String, Number) :-
    RealIndex is Index + 1,
    string_code(RealIndex, String, Code),
    Number is Code - 48.

test_string_code_number :-
    string_code_number(0, "5962140", 5),
    string_code_number(1, "5962140", 9),
    string_code_number(2, "5962140", 6),
    string_code_number(3, "5962140", 2),
    string_code_number(4, "5962140", 1),
    string_code_number(5, "5962140", 4),
    string_code_number(6, "5962140", 0).


digit_string("", []).
digit_string(Data, [Element|Row]) :-
    string_code_number(0, Data, Element),
    sub_string(Data, 1, _, 0, RemainingData),
    digit_string(RemainingData, Row).

test_digit_string :-
    digit_string("123", [1, 2, 3]),
    digit_string("12673170823", [1, 2, 6, 7, 3, 1, 7, 0, 8, 2, 3]).


sif(Size, Data, Layers) :-
    sif_layers(Size, Data, Layers).

sif_layers(_, "", []).
sif_layers(-(Width, Height), Data, [Layer|Layers]) :-
    LayerSize is Width * Height,
    sub_string(Data, 0, LayerSize, _, LayerData),
    sub_string(Data, LayerSize, _, 0, RemainingData),
    string_length(LayerData, LayerSize),
    sif_layer(Width, LayerData, Layer),
    sif_layers(-(Width, Height), RemainingData, Layers).

sif_layer(_, "", []).
sif_layer(Width, Data, [Row|Layer]) :-
    sub_string(Data, 0, Width, _, RowData),
    sub_string(Data, Width, _, 0, RemainingData),
    string_length(RowData, Width),
    digit_string(RowData, Row),
    sif_layer(Width, RemainingData, Layer).

test_sif :-
    sif(
        -(3, 2),
        "123456789012",
        [
            [
                [1, 2, 3],
                [4, 5, 6]
            ],
            [
                [7, 8, 9],
                [0, 1, 2]
            ]
        ]
    ).


sif_check(Size, Data, Sum) :-
    sif(Size, Data, Layers),
    % Count zero digits for all layers
    maplist(
        [Layer, Count]>>(
            findall(Pixel, (
                    member(Row, Layer),
                    member(Pixel, Row),
                    Pixel = 0
                ),
                ZeroPixels),
            length(ZeroPixels, Count)
        ),
        Layers,
        ZeroPixelCounts),
    % Find index of layer with fewest zero digits
    min_list(ZeroPixelCounts, MinZeroPixels),
    nth0(Index, ZeroPixelCounts, MinZeroPixels),
    nth0(Index, Layers, CheckLayer),
    % Count 1 and 2 digits
    findall(P, (member(Row, CheckLayer), member(P, Row), P = 1), OneDigitsList),
    length(OneDigitsList, OneDigits),
    findall(P, (member(Row, CheckLayer), member(P, Row), P = 2), TwoDigitsList),
    length(TwoDigitsList, TwoDigits),
    Sum is OneDigits * TwoDigits.

test_sif_check :-
    sif_check(-(3, 2), "123456789012", 1).


combine_layers([], _).
combine_layers([Layer|Layers], Result) :-
    maplist(
        [LayerRow, ResultRow]>>maplist(
            [LayerPixel, ResultPixel]>>(
                % We essentially just use the first instantiation of ResultPixel
                % to combine layers here
                (\+ number(ResultPixel), LayerPixel \= 2)
                -> ResultPixel = LayerPixel
                ; true
            ),
            LayerRow,
            ResultRow
        ),
        Layer,
        Result),
    combine_layers(Layers, Result).

test_combine_layers :-
    sif(2-2, "0222112222120000", Layers),
    combine_layers(
        Layers,
        [
            [0, 1],
            [1, 0]
        ]).


image(Size, Data, Result) :-
    sif(Size, Data, Layers),
    combine_layers(Layers, Result).
