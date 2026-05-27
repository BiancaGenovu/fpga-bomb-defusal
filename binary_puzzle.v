// =============================================================
// binary_puzzle.v  –  Mini-joc 1: Codul Binar
//
// Jucatorul trebuie sa seteze SW[3:0] = 1101 (13 in zecimal)
// pentru a rezolva puzzle-ul.
//
// Hint afisat pe display:  HEX1="1", HEX0="3"
// (deci tinta e numarul 13, care in binar e 1101)
//
// Logica e pur combinationala (fara clock) – simplu si robust.
// LEDR[3:0] oglindeste switch-urile ca feedback vizual.
// =============================================================
module binary_puzzle (
    input  [3:0] sw,     // SW[3:0] de pe DE2
    output       done,   // 1 cand combinatia corecta e setata
    output [3:0] leds    // oglinda switch-uri → LEDR[3:0]
);
    localparam TARGET = 4'b1101; // tinta: 13 in zecimal

    assign done = (sw == TARGET);
    assign leds = sw;

endmodule
