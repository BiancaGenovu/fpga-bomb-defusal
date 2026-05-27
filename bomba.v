
//  HARTA CONTROALE
// ============================================================
//
//  KEY[0]          : RESET (tine apasat pentru reset total)
//  SW[17]          : Porneste jocul (flip sus = START)
//
//  [JOC 1 – Cod Binar]
//  SW[3:0]         : Seteaza combinatia binara
//                    Tinta: SW3=1, SW2=1, SW1=0, SW0=1  (= 13 zecimal)
//  LEDR[3:0]       : Oglinda switch-uri (feedback vizual)
//  HEX1:HEX0       : Arata tinta "13" ca hint
//
//  [JOC 2 – Simon Says]
//  LEDG[2:0]       : Arata secventa de retinut
//  KEY[1]          : Buton pentru LED 0  (keys = 001)
//  KEY[2]          : Buton pentru LED 1  (keys = 010)
//  KEY[3]          : Buton pentru LED 2  (keys = 100)
//  Secventa:         LED0(KEY1) → LED2(KEY3) → LED1(KEY2)
//
//  [JOC 3 – Taiat Fire]
//  SW[7:4]        : Fire de taiat (flip sus = "taiat")
//  LEDR[11:8]      : Progres (cate fire taiate corect)
//  Ordinea corecta:  SW4 → SW6 → SW5 → SW7
//  ATENTIE:          SW[7:4] trebuie sa fie la 0 la start!
//
// ============================================================
//  DISPLAY HEX
// ============================================================
//
//  HEX5 : HEX4  |  HEX3 : HEX2  |  HEX1 : HEX0
//  -----------------------------------------------
//  IDLE:   -- --  |   -- --      |   -- --
//  GAME1:  G  1   |  timer (s)   |   1  3  (hint)
//  GAME2:  G  2   |  timer (s)   |   -- --
//  GAME3:  G  3   |  timer (s)   |   -- --
//  WIN:    S  A   |   F  E       |   -- --   (SAFE)
//  LOSE:   L  O   |   S  E       |   -- --   (LOSE)
//
// ============================================================
//  LED STATUS
// ============================================================
//  LEDG[2:0]  : Simon Says secventa curenta
//  LEDG[3]    : Joc 1 completat
//  LEDG[4]    : Joc 2 completat
//  LEDG[5]    : Joc 3 completat (= WIN)
//  LEDG[7]    : Clipeste verde = CASTIGAT
//  LEDR[17:0] : Clipeste rosu = PIERDUT (explozie sau timp expirat)
//
// =============================================================

module bomba (
    input         CLOCK_50,
    input  [3:0]  KEY,        // KEY[0]=reset, KEY[3:1]=Simon buttons
    input  [17:0] SW,         // SW[17]=start, SW[3:0]=binary, SW[11:8]=fire
    output [17:0] LEDR,
    output [7:0]  LEDG,
    output [6:0]  HEX0,
    output [6:0]  HEX1,
    output [6:0]  HEX2,
    output [6:0]  HEX3,
    output [6:0]  HEX4,
    output [6:0]  HEX5,
    output [6:0]  HEX6,
    output [6:0]  HEX7
);

    // =========================================================
    // Constante 7-Segment (activ-LOW, seg[6:0] = {g,f,e,d,c,b,a})
    // =========================================================
    localparam SEG_OFF  = 7'b1111111;   // blank
    localparam SEG_DASH = 7'b0111111;   // -
    localparam SEG_S    = 7'b0010010;   // S
    localparam SEG_A    = 7'b0001000;   // A
    localparam SEG_F    = 7'b0001110;   // F
    localparam SEG_E    = 7'b0000110;   // E
    localparam SEG_L    = 7'b1000111;   // L
    localparam SEG_O    = 7'b1000000;   // O
    localparam SEG_G    = 7'b0000010;   // G
    localparam SEG_1    = 7'b1111001;   // 1
    localparam SEG_2    = 7'b0100100;   // 2
    localparam SEG_3    = 7'b0110000;   // 3
    localparam SEG_13H  = 7'b1111001;   // "1" pentru hint joc 1
    localparam SEG_13L  = 7'b0110000;   // "3" pentru hint joc 1

    // =========================================================
    // Reset
    // =========================================================
    wire reset_n = KEY[0];   // KEY[0] e activ-LOW pe DE2

    // =========================================================
    // Generator impuls 1 Hz (pentru cronometrul countdown)
    // 50.000.000 cicli = 1 secunda la 50 MHz → contor 26-bit
    // =========================================================
    reg [25:0] cnt_1hz;
    reg        en_1hz;

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            cnt_1hz <= 26'd0;
            en_1hz  <= 1'b0;
        end else begin
            en_1hz <= 1'b0;
            if (cnt_1hz == 26'd49999999) begin
                cnt_1hz <= 26'd0;
                en_1hz  <= 1'b1;   // puls de 1 ciclu la fiecare secunda
            end else
                cnt_1hz <= cnt_1hz + 1'b1;
        end
    end

    // =========================================================
    // Generator clipire 2 Hz (pentru animatii WIN / LOSE)
    // =========================================================
    reg [24:0] cnt_blink;
    reg        blink;

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            cnt_blink <= 25'd0;
            blink     <= 1'b0;
        end else begin
            if (cnt_blink == 25'd24_999_999) begin
                cnt_blink <= 25'd0;
                blink     <= ~blink;
            end else
                cnt_blink <= cnt_blink + 1'b1;
        end
    end

    // =========================================================
    // Debounce butoane Simon Says (KEY[3:1], activ-LOW pe DE2)
    // k1 = KEY[1], k2 = KEY[2], k3 = KEY[3]   (activ-HIGH dupa debounce)
    // =========================================================
    wire k1, k2, k3;

    debounce db1 (.clk(CLOCK_50), .reset_n(reset_n), .btn_n(KEY[1]), .btn_out(k1));
    debounce db2 (.clk(CLOCK_50), .reset_n(reset_n), .btn_n(KEY[2]), .btn_out(k2));
    debounce db3 (.clk(CLOCK_50), .reset_n(reset_n), .btn_n(KEY[3]), .btn_out(k3));

    // =========================================================
    // Masina de stari principala a jocului
    // =========================================================
    localparam IDLE  = 3'd0;
    localparam GAME1 = 3'd1;   // Cod Binar
    localparam GAME2 = 3'd2;   // Simon Says
    localparam GAME3 = 3'd3;   // Taiat Fire
    localparam WIN   = 3'd4;
    localparam LOSE  = 3'd5;

    reg [2:0] game_state;

    // Semnale de enable – fiecare modul ruleaza doar cand e randul lui
    wire binary_en = (game_state == GAME1);
    wire simon_en  = (game_state == GAME2);
    wire wire_en   = (game_state == GAME3);

    // =========================================================
    // Cronometru countdown (90 secunde, afisat ca doua cifre zecimale)
    // =========================================================
    localparam TIMER_TENS_INIT  = 4'd9;
    localparam TIMER_UNITS_INIT = 4'd0;

    reg [3:0] timer_tens, timer_units;
    reg       timer_expired;

    wire timer_running = (game_state == GAME1 ||
                          game_state == GAME2 ||
                          game_state == GAME3);

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            timer_tens    <= TIMER_TENS_INIT;
            timer_units   <= TIMER_UNITS_INIT;
            timer_expired <= 1'b0;
        end else if (timer_running && en_1hz) begin
            if (timer_units == 4'd0) begin
                if (timer_tens == 4'd0)
                    timer_expired <= 1'b1;       // 00:00 → timp expirat
                else begin
                    timer_tens  <= timer_tens  - 1'b1;
                    timer_units <= 4'd9;
                end
            end else
                timer_units <= timer_units - 1'b1;
        end
    end

    // =========================================================
    // Instantiere mini-jocuri
    // =========================================================

    // --- Joc 1: Cod Binar ---
    wire       binary_done;
    wire [3:0] binary_leds;

    binary_puzzle bp (
        .sw   (SW[3:0]),
        .done (binary_done),
        .leds (binary_leds)
    );

    // --- Joc 2: Simon Says ---
    wire       simon_win, simon_lose;
    wire [2:0] simon_leds;

    simon_says ss (
        .clk     (CLOCK_50),
        .reset_n (reset_n),
        .game_en (simon_en),
        .keys    ({k3, k2, k1}),   // keys[2]=k3, keys[1]=k2, keys[0]=k1
        .leds    (simon_leds),
        .win     (simon_win),
        .lose    (simon_lose)
    );

    // --- Joc 3: Taiat Fire ---
    // SW[11:8] → sw[3:0] intern: sw[0]=SW[8], sw[1]=SW[9], sw[2]=SW[10], sw[3]=SW[11]
    wire       wire_defused, wire_explode;
    wire [3:0] wire_progress;

    wire_puzzle wp (
        .clk          (CLOCK_50),
        .reset_n      (reset_n),
        .game_en      (wire_en),
        .sw           (SW[11:8]),
        .led_progress (wire_progress),
        .defused      (wire_defused),
        .explode      (wire_explode)
    );

    // =========================================================
    // Controler stari joc
    // =========================================================
    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            game_state <= IDLE;
        end else begin
            case (game_state)

                IDLE:
                    // SW[17] sus → porneste jocul
                    if (SW[17]) game_state <= GAME1;

                GAME1:
                    if      (timer_expired) game_state <= LOSE;
                    else if (binary_done)   game_state <= GAME3;

                GAME2:
                    if      (timer_expired || simon_lose) game_state <= LOSE;
                    else if (simon_win)                    game_state <= WIN;

                GAME3:
                    if      (timer_expired || wire_explode) game_state <= LOSE;
                    else if (wire_defused)                   game_state <= GAME2;

                WIN:  ; // ramane aici pana la reset
                LOSE: ; // ramane aici pana la reset

                default: game_state <= IDLE;
            endcase
        end
    end

    // =========================================================
    // Tracking completare jocuri (pentru LEDG[5:3])
    // =========================================================
    // LEDG[3] = Joc 1 completat (suntem in GAME2 sau mai departe)
    // LEDG[4] = Joc 2 completat (suntem in GAME3 sau mai departe)
    // LEDG[5] = Joc 3 completat (suntem in WIN)
    // Nota: in starea LOSE aceste LED-uri se sting (nu conteaza)

    assign LEDG[3] = (game_state == GAME2 || game_state == GAME3 || game_state == WIN);
    assign LEDG[4] = (game_state == GAME3 || game_state == WIN);
    assign LEDG[5] = (game_state == WIN);

    // =========================================================
    // Decodor HEX pentru cronometru
    // =========================================================
    wire [6:0] seg_timer_tens, seg_timer_units;

    hex_decoder hd_t (.digit(timer_tens),  .seg(seg_timer_tens));
    hex_decoder hd_u (.digit(timer_units), .seg(seg_timer_units));

    // =========================================================
    // Atribuire iesiri LEDR
    // =========================================================
    // LEDR[3:0]  : Joc 1 – oglinda SW[3:0]  (stins in alte stari)
    // LEDR[11:8] : Joc 3 – progres fire      (stins in alte stari)
    // LOSE       : tot LEDR clipeste rosu

    assign LEDR[3:0] =
        (game_state == LOSE)  ? {4{blink}}   :
        (game_state == GAME1) ? binary_leds  : 4'b0000;

    assign LEDR[7:4] =
        (game_state == LOSE)  ? {4{blink}}   : 4'b0000;

    assign LEDR[11:8] =
        (game_state == LOSE)  ? {4{blink}}   :
        (game_state == GAME3) ? wire_progress : 4'b0000;

    assign LEDR[17:12] =
        (game_state == LOSE)  ? {6{blink}}   : 6'b000000;

    // =========================================================
    // Atribuire iesiri LEDG
    // =========================================================
    assign LEDG[2:0] = simon_leds;        // Simon Says LED secventa
    // LEDG[3:5] deja atribuit mai sus
    assign LEDG[6]   = 1'b0;
    assign LEDG[7]   = (game_state == WIN) ? blink : 1'b0;  // clipeste verde = CASTIGAT

    // =========================================================
    // Atribuire iesiri HEX
    // =========================================================
    assign HEX7 = SEG_OFF;
    assign HEX6 = SEG_OFF;

    // HEX5:HEX4 – eticheta stare ("G1"/"G2"/"G3"/"SA"/"LO")
    assign HEX5 =
        (game_state == GAME1) ? SEG_G    :
        (game_state == GAME2) ? SEG_G    :
        (game_state == GAME3) ? SEG_G    :
        (game_state == WIN)   ? SEG_S    :   // S din "SAFE"
        (game_state == LOSE)  ? SEG_L    :   // L din "LOSE"
        SEG_DASH;                             // IDLE

    assign HEX4 =
        (game_state == GAME1) ? SEG_1    :
        (game_state == GAME2) ? SEG_2    :
        (game_state == GAME3) ? SEG_3    :
        (game_state == WIN)   ? SEG_A    :   // A din "SAFE"
        (game_state == LOSE)  ? SEG_O    :   // O din "LOSE"
        SEG_DASH;

    // HEX3:HEX2 – cronometru (in timpul jocului) sau mesaj
    assign HEX3 =
        (timer_running)       ? seg_timer_tens  :
        (game_state == WIN)   ? SEG_F           :   // F din "SAFE"
        (game_state == LOSE)  ? SEG_S           :   // S din "LOSE"
        SEG_DASH;

    assign HEX2 =
        (timer_running)       ? seg_timer_units :
        (game_state == WIN)   ? SEG_E           :   // E din "SAFE"
        (game_state == LOSE)  ? SEG_E           :   // E din "LOSE"
        SEG_DASH;

    // HEX1:HEX0 – hint joc 1 ("13") sau "- -"
    assign HEX1 =
        (game_state == GAME1) ? SEG_13H  :   // "1" – hint tinta binara
        (game_state == GAME2 ||
         game_state == GAME3) ? SEG_DASH : SEG_OFF;

    assign HEX0 =
        (game_state == GAME1) ? SEG_13L  :   // "3" – hint tinta binara
        (game_state == GAME2 ||
         game_state == GAME3) ? SEG_DASH : SEG_OFF;

endmodule

