// =============================================================
// debounce.v
// Debounser hardware pentru butoanele KEY de pe DE2.
//
// KEY pe DE2 este activ-LOW (0 cand e apasat).
// Acest modul:
//   - inverteaza input-ul  â btn_out=1 cand butonul E apasat
//   - asteapta ~20ms inainte sa accepte o schimbare
//     (elimina "bouncing"-ul mecanic al butonului)
// =============================================================
module debounce (
    input      clk,       // 50 MHz clock de sistem
    input      reset_n,   // reset activ-LOW (leaga la KEY[0])
    input      btn_n,     // buton raw activ-LOW de pe DE2 (ex: KEY[1])
    output reg btn_out    // iesire debounced, activ-HIGH (1 = apasat)
);
    // ---- Synchronizer cu 2 etaje (evita metastabilitate) ----
    reg sync0, sync1;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
        end else begin
            sync0 <= ~btn_n;   // invertat: 1 = buton apasat
            sync1 <= sync0;
        end
    end

    // ---- Contor debounce: ~20ms la 50MHz = 1.000.000 cicli ----
    reg [19:0] cnt;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cnt     <= 20'd0;
            btn_out <= 1'b0;
        end else if (sync1 == btn_out) begin
            cnt <= 20'd0;               // semnal stabil, resetam contorul
        end else begin
            cnt <= cnt + 1'b1;
            if (cnt == 20'd999_999) begin   // 20ms a trecut
                btn_out <= sync1;           // acceptam noua valoare
                cnt     <= 20'd0;
            end
        end
    end
endmodule