// =============================================================
// hex_decoder.v
// Converteste un numar de 4 biti in cod 7-segment pentru DE2.
//
// Display-urile HEX pe DE2 sunt activ-LOW:
//   0 = segment APRINS, 1 = segment STINS
//
// Bit mapping: seg[6:0] = { g, f, e, d, c, b, a }
//
//      aaa
//     f   b
//     f   b
//      ggg
//     e   c
//     e   c
//      ddd
//
// Cifre 0-9 si litere A, b, C, d, E, F
// =============================================================
module hex_decoder (
    input  [3:0] digit,
    output reg [6:0] seg   // activ-LOW
);
    always @(*) begin
        case (digit)
            4'd0:  seg = 7'b1000000; // 0
            4'd1:  seg = 7'b1111001; // 1
            4'd2:  seg = 7'b0100100; // 2
            4'd3:  seg = 7'b0110000; // 3
            4'd4:  seg = 7'b0011001; // 4
            4'd5:  seg = 7'b0010010; // 5
            4'd6:  seg = 7'b0000010; // 6
            4'd7:  seg = 7'b1111000; // 7
            4'd8:  seg = 7'b0000000; // 8
            4'd9:  seg = 7'b0010000; // 9
            4'd10: seg = 7'b0001000; // A
            4'd11: seg = 7'b0000011; // b
            4'd12: seg = 7'b1000110; // C
            4'd13: seg = 7'b0100001; // d
            4'd14: seg = 7'b0000110; // E
            4'd15: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // blank (toate stinse)
        endcase
    end
endmodule
