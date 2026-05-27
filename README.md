# 💣 Joc de Dezamorsare a Bombei – FPGA
Un proiect în Verilog care simulează dezamorsarea unei bombe, dezvoltat în **Quartus II** și testat direct pe placa de dezvoltare **Altera DE2** (Cyclone II EP2C35F672C6).
## Cum se joacă (Gameplay)
Ai la dispoziție **90 de secunde** să rezolvi în ordine 3 mini-jocuri. Dacă timpul expiră sau greșești ordinea, bomba explodează.
| Mini-joc | Ce trebuie să faci | Controale |
|---|---|---|
| 🔢 Cod Binar | Setează switch-urile pe valoarea `1101` (13 în zecimal) | SW[3:0] |
| ✂️ Tăiat Fire | Dezactivează cele 4 „fire” în ordinea corectă | SW[11:8] |
| 🎵 Simon Says | Repetă secvența de 3 pași indicată de LED-uri | KEY[1..3] |
## Structura Proiectului (Arhitectură)
* **`bomba.v` (Modulul Top)** – Coordonează întregul joc printr-un automat de stări (FSM) principal: `IDLE` → `GAME1` → `GAME3` → `GAME2` → `WIN`/`LOSE`.
* **`binary_puzzle.v`** – Logica pur combinațională pentru primul nivel.
* **`wire_puzzle.v`** – Automat de stări care verifică ordinea corectă a firelor și declanșează explozia la greșeli.
* **`simon_says.v`** – FSM care gestionează secvențele luminoase, timerele de afișare și validarea input-ului.
* **`debounce.v`** – Modul de debouncing hardware (20ms) cu sincronizare în două etaje pentru a elimina zgomotul de pe butoane.
* **`hex_decoder.v`** – Decodor pentru display-urile pe 7 segmente (active pe `0` logic, afișează caractere de la `0` la `F`).
## Mapare I/O (Periferice Placă)
* **`LEDR[17:0]`** (LED-uri roșii) – Arată progresul în joc și pornesc o animație specifică în caz de `LOSE`.
* **`LEDG[7:0]`** (LED-uri verzi) – Afișează secvențele pentru Simon Says și animația de `WIN`.
* **`HEX0 – HEX5`** (Display-uri 7 segmente) – Afișează cronometrul, indiciile și starea curentă a jocului.
* **`KEY[0]`** – Reset general (activ pe `0`).
* **`SW[17]`** – Switch-ul de pornire a jocului (Start).
## Toolchain & Hardware
* **Software:** Quartus II 13.0 SP1
* **Limbaj:** Verilog HDL
* **Hardware:** Altera DE2 Board (FPGA Cyclone II EP2C35F672C6)

# 💣 FPGA Bomb Defusal Game
A Verilog-based bomb defusal game developed in **Quartus II** and deployed on the **Altera DE2** development board (Cyclone II EP2C35F672C6).
## Gameplay
The player has **90 seconds** to solve three mini-games in sequence. Fail to do so before the countdown hits zero, and the bomb explodes.
| Mini-game | Objective | Controls |
|---|---|---|
| 🔢 Binary Code | Set switches to `1101` (13 in decimal) | SW[3:0] |
| ✂️ Wire Cut | Flip ("cut") 4 switches in the exact correct order | SW[11:8] |
| 🎵 Simon Says | Repeat the 3-step flashing pattern shown on the LEDs | KEY[1..3] |
## Architecture & Modules
* **`bomba.v` (Top Module)** – Drives the main game loop using a finite state machine (FSM): `IDLE` → `GAME1` → `GAME3` → `GAME2` → `WIN`/`LOSE`.
* **`binary_puzzle.v`** – Pure combinational logic for the first stage.
* **`wire_puzzle.v`** – Sequential FSM that tracks the wire-cutting sequence and handles instant-fail conditions.
* **`simon_says.v`** – Handles pattern generation, display timing, and user input validation.
* **`debounce.v`** – 20ms hardware debouncer with a 2-stage synchronizer to clean up button presses.
* **`hex_decoder.v`** – 7-segment display driver (active-low, hex characters `0` to `F`).
## Peripheral Mapping (Board I/O)
* **`LEDR[17:0]`** (Red LEDs) – Displays level progress and triggers a custom animation on failure.
* **`LEDG[7:0]`** (Green LEDs) – Outputs the Simon Says patterns and triggers a celebration animation on win.
* **`HEX0 – HEX5`** (7-Segment Displays) – Shows the countdown timer, current level tags, and hints.
* **`KEY[0]`** – Master Reset (active-low).
* **`SW[17]`** – Game Start switch.
## Tools & Specs
* **Software:** Quartus II 13.0 SP1
* **Language:** Verilog HDL
* **Target Hardware:** Altera DE2 Board (Cyclone II EP2C35F672C6)
