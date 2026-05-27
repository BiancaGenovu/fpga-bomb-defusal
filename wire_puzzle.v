// =============================================================
// wire_puzzle.v  –  Mini-joc 3: Taiat Fire
//                   (VERSIUNE ACTUALIZATA PENTRU DE2)
//
// Diferente fata de versiunea ModelSim:
//   1. Stare EXPLODED explicita (inainte ramanea blocat in starea curenta)
//   2. game_en: modulul se reseteaza cand nu e randul lui
//
// Regulile jocului:
//   Taie firele IN ORDINE CORECTA, altfel BANG!
//   Ordinea corecta: SW[8] → SW[10] → SW[9] → SW[11]
//   (in modul intern: sw[0] → sw[2] → sw[1] → sw[3])
//
// ATENTIE pentru jucator:
//   Asigurati-va ca SW[11:8] sunt TOATE LA 0 inainte sa inceapa
//   jocul 3, altfel explozia se declanseaza imediat!
//
// Intrari:
//   clk      : 50 MHz
//   reset_n  : reset activ-LOW
//   game_en  : 1 = jocul acesta e activ
//   sw[3:0]  : fire (switch-uri) – switch-ul ramas sus = "taiat"
//              sw[0]=SW[8], sw[1]=SW[9], sw[2]=SW[10], sw[3]=SW[11]
//
// Iesiri:
//   led_progress[3:0] : cate fire au fost taiate corect → LEDR[11:8]
//   defused           : 1 cand toate firele sunt taiate corect
//   explode           : 1 cand s-a taiat un fir gresit
// =============================================================
module wire_puzzle (
    input        clk,
    input        reset_n,
    input        game_en,
    input  [3:0] sw,
    output reg [3:0] led_progress,
    output reg   defused,
    output reg   explode
);
    reg [2:0] state;
    localparam START    = 3'd0;   // asteapta taierea primului fir (sw[0])
    localparam WIRE1    = 3'd1;   // sw[0] taiat, asteapta sw[2]
    localparam WIRE2    = 3'd2;   // sw[2] taiat, asteapta sw[1]
    localparam WIRE3    = 3'd3;   // sw[1] taiat, asteapta sw[3]
    localparam WIN      = 3'd4;   // toate firele taiate corect
    localparam EXPLODED = 3'd5;   // fir gresit → EXPLOZIE

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state        <= START;
            explode      <= 1'b0;
            defused      <= 1'b0;
            led_progress <= 4'b0000;
				end else if (!game_en) begin
					state        <= START;
					explode      <= 1'b0;
					defused      <= 1'b0;
					led_progress <= 4'b0000;
        end else begin
            case (state)

                START: begin
                    if (sw[0]) begin
                        // Fir 0 taiat corect – urmatorul e sw[2]
                        state        <= WIRE1;
                        led_progress <= 4'b0001;
                    end else if (sw[1] || sw[2] || sw[3]) begin
                        // Alt fir taiat inainte de sw[0] → EXPLOZIE
                        state <= EXPLODED;
                    end
                end

                WIRE1: begin
                    // sw[0] e deja sus (taiat), asta e ok
                    if (sw[2]) begin
                        state        <= WIRE2;
                        led_progress <= 4'b0011;
                    end else if (sw[1] || sw[3]) begin
                        state <= EXPLODED;
                    end
                end

                WIRE2: begin
                    // sw[0] si sw[2] deja sus, ok
                    if (sw[1]) begin
                        state        <= WIRE3;
                        led_progress <= 4'b0111;
                    end else if (sw[3]) begin
                        state <= EXPLODED;
                    end
                end

                WIRE3: begin
                    // Ultimul fir: sw[3]
                    if (sw[3]) begin
                        state        <= WIN;
                        led_progress <= 4'b1111;
                    end
                end

                WIN: begin
                    defused <= 1'b1;   // semnalul ramane activ
                end

                EXPLODED: begin
                    explode <= 1'b1;   // semnalul ramane activ
                end

                default: state <= START;
            endcase
        end
    end
endmodule