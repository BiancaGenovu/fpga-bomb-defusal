// =============================================================
// simon_says.v  â  Mini-joc 2: Simon Says
//                  (VERSIUNE CORECTATA PENTRU DE2)
//
// Diferente fata de versiunea ModelSim:
//   1. Starea SHOW are timer de 1 secunda (inainte trecea instant)
//   2. Stare DARK: pauza 0.5s intre afisare si asteptare input
//   3. Detectie de FRONT (edge) la apasare buton (nu nivel)
//   4. game_en: modulul se reseteaza cand nu e randul lui
//   5. Output 'lose' pentru apasare gresita
//
// Secventa secreta (hardcodata):
//   Pas 0 â LED 0 aprins â apasa KEY[1]  (keys = 3'b001)
//   Pas 1 â LED 2 aprins â apasa KEY[3]  (keys = 3'b100)
//   Pas 2 â LED 1 aprins â apasa KEY[2]  (keys = 3'b010)
//
// Intrari:
//   clk      : 50 MHz
//   reset_n  : reset activ-LOW
//   game_en  : 1 = jocul acesta e activ
//   keys[2:0]: butoane debounced activ-HIGH din top module
//              keys[0] = KEY[1], keys[1] = KEY[2], keys[2] = KEY[3]
//
// Iesiri:
//   leds[2:0]: LED-uri secventa â LEDG[2:0]
//   win      : 1 cand secventa e corecta
//   lose     : 1 cand s-a apasat gresit
// =============================================================
module simon_says (
    input        clk,
    input        reset_n,
    input        game_en,
    input  [2:0] keys,      // debounced, activ-HIGH
    output reg [2:0] leds,
    output reg   win,
    output reg   lose
);
    // ---- Stari FSM ----
    localparam IDLE    = 3'd0;
    localparam SHOW    = 3'd1;   // afiseaza LED-ul pentru pasul curent
    localparam DARK    = 3'd2;   // pauza inainte de input
    localparam WAIT_IN = 3'd3;   // asteapta apasarea butonului
    localparam DONE    = 3'd4;   // castigat
    localparam FAIL    = 3'd5;   // pierdut (buton gresit)

    reg [2:0] state;
    reg [1:0] step;   // pasul curent (0, 1, sau 2)

    // ---- Secventa corecta per pas ----
    // Returneaza ce LED se aprinde si ce buton trebuie apasat la pasul 's'
    function [2:0] seq_led;
        input [1:0] s;
        case (s)
            2'd0: seq_led = 3'b001;   // LED 0 â KEY[1]
            2'd1: seq_led = 3'b100;   // LED 2 â KEY[3]
            2'd2: seq_led = 3'b010;   // LED 1 â KEY[2]
            default: seq_led = 3'b000;
        endcase
    endfunction

    // ---- Timere ----
    // 1 secunda  = 50.000.000 cicli la 50MHz  â contor 26-bit
    // 0.5 secunde = 25.000.000 cicli
    reg [25:0] timer;
    localparam SHOW_TIME = 26'd40_000_000;   // 1 secunda
    localparam DARK_TIME = 26'd30_000_000;   // 0.5 secunde

    // ---- Detectie front ascendent la apasarea butoanelor ----
    // keys_edge = 1 doar in ciclul in care a fost apasat (nu cat timp e tinut)
    reg  [2:0] keys_prev;
    wire [2:0] keys_edge = keys & ~keys_prev;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) keys_prev <= 3'b000;
        else          keys_prev <= keys;
    end

    // ---- FSM principal ----
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n ) begin
            // Reset complet: fie global reset, fie nu e randul acestui joc
            state <= IDLE;
            leds  <= 3'b000;
            win   <= 1'b0;
            lose  <= 1'b0;
            step  <= 2'd0;
            timer <= 26'd0;
				end else if (!game_en) begin
					if (state != DONE && state != FAIL) begin
						state <= IDLE;
						win   <= 1'b0;
						lose  <= 1'b0;
						step  <= 2'd0;
						timer <= 26'd0;
						leds  <= 3'b000;
					end
        end else begin
		  
            case (state)

                IDLE: begin
                    // Porneste jocul imediat ce game_en devine 1
                    state <= SHOW;
                    timer <= 26'd0;
                end

                SHOW: begin
                    leds <= seq_led(step);       // aprinde LED-ul pasului curent
                    if (timer < SHOW_TIME)
                        timer <= timer + 1'b1;
                    else begin
                        timer <= 26'd0;
                        leds  <= 3'b000;         // stinge LED-ul
                        state <= DARK;
                    end
                end

                DARK: begin
                    // Pauza scurta â evita ca jucatorul sa apese inainte sa vada
                    if (timer < DARK_TIME)
                        timer <= timer + 1'b1;
                    else begin
                        timer <= 26'd0;
                        state <= WAIT_IN;
                    end
                end

                WAIT_IN: begin
                    if (keys_edge != 3'b000) begin   // s-a detectat o apasare noua
                        if (keys_edge == seq_led(step)) begin
                            // Buton CORECT!
                            if (step == 2'd2) begin
                                // Ultimul pas completat â CASTIG
                                state <= DONE;
                                win   <= 1'b1;
                            end else begin
                                // Mai sunt pasi â urmatorul LED
                                step  <= step + 1'b1;
                                state <= SHOW;
                                timer <= 26'd0;
                            end
                        end else begin
                            // Buton GRESIT â PIERDUT
                            state <= FAIL;
                            lose  <= 1'b1;
                        end
                    end
                end

                DONE: leds <= 3'b111;   // toate LED-urile aprinse = victorie

                FAIL: leds <= 3'b000;   // stins = esec

                default: state <= IDLE;
            endcase
        end
    end
endmodule