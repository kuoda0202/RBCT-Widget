# RBCT Helicopter Dashboard Widget

**Author / 作者**: 雷恩 / Ryan Kuo
### Standard UI (預設標準介面)
![Standard UI](Pic/Standard%20UI.jpg)

### Clean UI (半透背景模式)
![Clean UI](Pic/Clean%20UI.jpg)

### Transparent UI (TRN 全透無框模式)
![Transparent UI](Pic/Transparent%20UI.jpg)

### Nitro UI (燃油引擎專屬模式)
![Nitro UI](Pic/Nitro%20UI.jpg)

### Battery Fleet Manager UI (機隊電池管理總表)
![Battery Fleet Manager UI](Pic/Battery%20UI.jpg)

### Logbook & Chart UI (飛行日誌與五線譜圖表)
![Logbook UI](Pic/Logbook%20UI.jpg)

### Widget Settings Menu (小工具設定選單)
![Menu UI](Pic/Menu%20UI.jpg)

(English below)

**RBCT** 是一個專為 EdgeTX 開發的直昇機儀表板小工具 (Widget)，支援多種螢幕解析度自動適應，完美適配 RadioMaster TX16S MK3 (800x480)、TX16S MKII (480x272) 以及 TX15 MAX (480x320) 等全彩觸控螢幕。提供完整、直覺的飛行數據監控介面。

## 🌟 核心功能

*   **跨機種解析度自適應**：自動偵測螢幕大小，無論是 800x480 或 480 寬度的螢幕，皆能自動調整字體與圖片比例，維持最佳顯示效果。
*   **黑盒子與五線譜飛行圖表 (Logbook & Chart Analyzer)**：透過實體開關 (Logbook Sw) 一鍵叫出，提供：
    *   **歷史數據表格**：自動記錄近期航班的極值摘要（MAX RPM, MAX A, MIN V, MIN BEC, MAX TMP, mAh）。
    *   **零負載極速繪圖引擎**：完全由記憶體運作的 5 線譜折線圖（綠線 RPM、橘線 電壓、紅線 電流、藍線 BEC、黃線 溫度），精準分析劇烈動作時的電壓陡降與掉轉現象。在解鎖狀態下甚至能呈現「即時調機」效果！
*   **自動飛行次數計數器 (Flight Counter)**：獨立追蹤每台機型的「今日飛行次數 (Today)」與「歷史總飛行次數 (Total)」，皆以純文字檔儲存於 SD 卡，支援手動編輯。
*   **即時遙測數據顯示**：監控並顯示包含電池總電壓 (Vbat)、電流 (A)、消耗容量 (mAh)、BEC 電壓、單節最低電壓 (Cell) 以及 ESC / MCU 溫度。
*   **智慧電池 S 數演算法與通電鎖定 (Smart Battery S-Cell Engine)**：
    *   *第一優先 (Native Telemetry)*：直接讀取 Rotorflight / EdgeTX 原生電池 S 數感測器 (`Cel#` / `Cells` / `Cels`)。
    *   *第二優先 (Exact Ratio)*：依總電壓與單芯電壓比例精確換算 $\text{S} = \text{round}(V_{bat} / V_{cel})$。完美解決未充飽/存儲電壓 (如 12S @ 45.9V/3.82V) 誤判為 11S，以及高壓鋰電 LiHV (如 12S @ 52.2V/4.35V) 誤判為 13S 的問題。
    *   *通電記憶體鎖定 (S-Lock)*：通電完成偵測後即將 S 數鎖定於記憶體，飛行中大螺距瞬間壓降絕不跳動；換電池或斷電自動重置。
*   **旋翼轉速監控 (Headspeed)**：即時顯示目前轉速 (RPM)，並記錄飛行過程中的最高 (max) 與最低 (min) 轉速。
*   **定速狀態指示 (Governor)**：提供醒目直覺的定速開啟/關閉 (ON/OFF) 狀態圖示。
*   **FBL 停懸段數 (Banks)**：根據您設定的遙控器開關或通道，動態顯示當前使用的 FBL 停懸段數 (Bank)。
*   **自訂儀表板主題色**：內建 9 種高對比主題色彩 (紅、橘、黃、綠、藍、靛、紫、黑、TRN 全透明)，可依個人喜好自由切換。
*   **支援透明背景**：
    *   開啟獨立的「透明背景」開關：隱藏主底色，但保留各資訊面板的半透明框。
    *   選擇 `TRN` 主題：全透底、無框架模式，讓你的遙控器桌布成為絕對主角！
*   **實體方向桿光圈控制**：直接在小工具中同步控制支援此功能的遙控器 (如 TX16S MK3) 方向桿 RGB 光圈，支援 9 種顏色與關閉選項。
*   **動態模型圖片**：自動讀取位於 `/IMAGES` 或 `/WIDGETS/RBCT/modelImage/` 的模型圖片。若無圖片則自動載入預設圖。
*   **飛行計時器整合**：於儀表板顯眼處同步顯示所選的遙控器計時器。

## 📥 安裝說明

1. 下載並將 `RBCT` 資料夾完整複製到遙控器 SD 卡內的 `WIDGETS` 目錄下 (路徑為 `/WIDGETS/RBCT`)。
2. 在遙控器上進入 Telemetry (遙測) 畫面設定。
3. 新增一個全螢幕 (Full screen) 區塊，並選擇 `RBCT` 小工具。

## ⚙️ 設定選項

在小工具設定選單中，您可以自訂以下項目：
*   **Timer (計時器)**：選擇要在畫面上顯示哪一個計時器 (Timer 1~3)。
*   **BANK開關 (---為Auto)**：選擇用來控制 FBL Bank 切換的通道或開關。**預設為 `---` (Auto)**，將自動讀取飛控 RF 遙測回傳；若指定實體開關，則優先依據開關位置切換。
*   **Arm Source (解鎖來源)**：選擇對應您遙控器上解鎖 (ARM) 功能的開關或通道，讓畫面能準確同步顯示。
*   **Banks (段數數量)**：設定可用的 Bank 總數 (2 至 6 段)。
*   **Theme (主題)**：選擇您喜歡的面板顏色 (包含新增的黑色與 TRN 全透明主題)。
*   **Transp BG (透明背景)**：開啟後主背景會變成透明，露出底層桌布，但保留各個資訊面板的半透明底色以維持辨識度。
*   **LED Color (光圈顏色)**：設定遙控器實體方向桿光圈的顏色 (9色可選或 OFF)。

## 🚁 模型圖片設定

若要自訂儀表板上的直昇機圖片：
*   請準備 `.png` 格式的去背圖片。
*   將圖片放入 `/WIDGETS/RBCT/modelImage/` 目錄，並將檔名命名為與「模型名稱」完全一致。
*   或者直接透過 EdgeTX 系統內建的模型圖片設定，小工具也會自動抓取顯示。

## 📝 最新更新 (Latest Updates)

### v1.0.701
*   **修正電池 S 數判斷優化 (Battery S Detection)*：修正未滿電 (如 12S 45.9V/3.82V) 誤判為 11S 或高壓鋰電 LiHV (12S 52.2V/4.35V) 誤判為 13S 的問題。現在優先讀取 Rotorflight 原生 `Cel#` 遙測感測器與 `Vbat/Vcel` 精確比值，並在接上電池期間鎖定 S 數，徹底避免飛行壓降跳動。
    *   *程式優化與修正。

### v1.0.7
*   **功能升級 (自訂語音警示門檻、液晶高反差主題與光感自動切換)**：
    *   *液晶高反差主題 (LCD Theme)*：新增低飽和綠灰液晶底色 (`RGB: 212, 224, 206`) 搭配高反差深墨綠文字 (`RGB: 15, 25, 20`)，戶外強光下閱讀清晰度大幅提升。
    *   *光感自動切換 (Auto LCD Theme)*：選單新增 `光感應LCD主題` (Light Sens) 設定。支援實體光感應器或邏輯開關 (True/False)。當偵測到強光或開關打開時，僅需極短的 0.2 秒防抖緩衝，即會瞬間切換至 LCD 高反差主題；回歸一般光線時亦然，提供最即時的戶外強光閱讀體驗。
    *   *小工具自訂門檻 (Custom Thresholds)*：選單可直接調整 `BEC 警告` (5.0V~8.0V)、`電變高溫警告` (40°C~110°C) 與 `油機高溫警告` (80°C~160°C)。
    *   *動力電池電量語音提醒 (Bat% Voice)*：支援低電量階梯語音報警、臨界沒電連續音告警與換新電池自動重置。

### v1.0.6
*   **功能新增 (電池 Fleet 管理與多電池獨立追蹤 Battery Fleet Manager)：
    *   *多電池槽獨立日誌：自動感測實體開關或邏輯開關 (6P1..6P6, 6POS1..6POS6, SW1..SW6, L1..L6) 或 Bat Track 設定，支援自動切換 BAT 1 ~ BAT 6。每包電池皆有獨立的起降次數、最低電壓、最高溫度、平均飛行時間與曲線紀錄 (log_<機型>_BAT<1..6>.txt, logbook_<機型>_BAT<1..6>.txt, chart_<機型>_BAT<1..6>.txt)。
    *   *3段式日誌與電池 Fleet 表格：透過 Logbook Sw 三段開關控制：
    *   *切至中段 (MID)：顯示 Tab 1 飛行日誌與 5 線譜即時折線圖。
    *   *切至下段 (DOWN)：顯示 Tab 2 BATTERY FLEET MANAGER 機隊電池管理總表（列出 BAT 1 ~ BAT 6 的循環次數 CYCLES、歷史最低電壓 MIN VOLT、最高溫度 MAX TMP 與平均航程 AVG DUR），當前選取的電池以高亮綠框醒目標示。
    *   *左下角電池槽狀態顯示：左下角版本水印自動擴充顯示當前選定的電池編號（如 v1.0.6 | BAT 1）。
*   **錯誤修復 (純英文系統介面顯示異常)：修復在純英文語系設定下，若 SD 卡內殘留中文語音包資料夾，會導致 Widget 設定選單文字因字型不支援中文字元而顯示空白的問題。現在將嚴格優先依據系統語言進行判斷。

### v1.0.501
*   **遙測判斷修復 (Bank 優先讀取 PID#)**：修復 Auto 模式下 Bank 顯示邏輯，優先讀取 Rotorflight active PID Profile 感測器 (`PID#` / `PID` / `Pid#` / `Bank`) 而非 Flight Mode (`FM`)，解決切換 Bank 時畫面卡在 `BANK 1` 的問題。
*   **視覺優化 (油機 RX PACK 電壓置中微調)：微調油機模式右側 RX PACK 特大電壓數字與單位 (如 8.3V) 之橫向繪製 X 軸偏移量，使其於面板框內視覺呈現更加精確置中。
*   **變更版本號為v1.0.5xx

### v1.0.005
*   **功能新增 (Auto-Scaling 智慧動態刻度系統)**：圖表座標軸導入「無上限動態天井與智慧比例換算演算法」。
    *   *全機型自適應*：無論是 700 級 (12S/14S, 200A+ 大電流)、450/500 級 (6S)，或是 200 級 / 微型電直 (高轉速 3500+ ~ 10,000+ RPM, 2S/3S 電壓)，圖表刻度上限與區間皆會根據該趟飛行的實際數據自動動態推升（例如轉速自動以 500 RPM 為一階向上擴充），曲線絕對不破頂、不掉框。
*   **介面修復 (常態刻度標籤)**：座標軸左右刻度文字標籤解鎖抽離條件式，不論記憶體內是否有實時曲線數據，進入 Logbook 介面時圖表左右兩側的刻度數值標籤永遠固定清晰顯示。
*   **功能新增 (最後一趟曲線 SD 卡持久化)**：飛行結束切回上鎖 (DISARM) 時，自動將當前 200 個採樣點寫入 SD 卡 (`/WIDGETS/RBCT/chart_<機型>.txt`)。關機重開機或隨時點進 Logbook 都能完整還原上一趟飛行的動態遙測曲線！

### v1.0.003
*   **功能新增 (重大升級)**：將畫面上的 `0 Flights` 靜態文字升級為「雙重真實計數器」！現在畫面上會同時顯示 `Today` (今日次數) 與 `Total` (終身總次數)。
*   **功能新增 (終極日誌)**：加入**「無感飛行日誌報表 (Flight Logbook)」**！降落後只需在螢幕輕點一下 (或短按滾輪)，畫面會立刻翻轉為該台直昇機最近 10 趟的飛行報表。表格內詳細記載每趟的：`起飛時間`、`飛行時長`、`最高轉速`、`最大電流`、`最低電壓`、`消耗容量`、`最高溫度` 與 `最低 BEC`。
*   **版面重構 (雙層專業圖表)**：日誌下方新增即時「五線譜分析圖表」。並將圖表物理分割為上下兩層 (上層：轉速/電壓/電流，下層：溫度/BEC)。不僅解決了刻度重疊問題，更完美對齊了時間軸 (X軸)，讓飛手能精準比對「大螺距電流突波」與「BEC掉壓」的毫秒級關聯！
*   **核心優化 (安全極限防爆)**：圖表引擎導入「動態降採樣 (Dynamic Downsampling)」與「FIFO 環狀緩衝區」航太級安全技術。
  *   *記憶體防爆*：不管滯空時間多長，陣列永遠只保留最新 200 筆資料 (約最後 10 分鐘的精華)，保證記憶體不溢位。
  *   *處理器防爆*：繪圖引擎自動等比例抽出 50 個關鍵點繪製趨勢。保證 CPU $O(1)$ 常數級極低負載，徹底消滅 `CPU LIMIT` 崩潰風險，連續解鎖 48 小時也絕對安全！
*   **邏輯升級 (智慧防呆計數器)**：大幅強化防呆過濾機制。現在解鎖超過 60 秒後，還必須偵測到 `轉速 > 1000 RPM` 或 `電流 > 5A` 才會判定為真實飛行並計數 +1。在桌上拔馬達除錯一整天也絕對不會誤判產生「幽靈航班」！
*   **功能新增**：結合 SD 卡記憶功能 (依模型獨立存放)，關機不遺失。並具備「跨日自動歸零」的貼心設計，每天開機 `Today` 會自動從 0 開始，而 `Total` 會持續累積。
*   **功能新增**：在設定選單中新增 `Reset FlyCount` (歸零來源) 選項。可指派遙控器實體開關 (如 SH 彈回開關)，撥動瞬間即可手動將 `Today` 歸零 (不會影響終身總次數)。
*   **介面自訂**：在 `Theme` 及 `LED Color` 選項中新增了 `Pink` (粉紅) 與 `Peach` (桃色) 兩種新色彩，提供更豐富的主題搭配。

### v1.0.002
*   **介面自訂**：在 `Theme` 中新增了 `TRN` (全透明) 主題，選擇此主題將會隱藏所有背景底色與邊框線條，並自動為文字加上黑色陰影，提供最乾淨的無框架視覺效果且保持極高辨識度。
*   **介面自訂**：新增 `Transp BG` (透明背景) 開關，開啟後可隱藏主背景底色以露出遙控器桌布，但貼心地保留了各資訊區塊的半透明底色，維持閱讀清晰度。
*   **介面自訂**：在 `Theme` 中新增了「黑色 (Black)」主題，提供更多樣的低調風格選擇，並將預設主題更改為 `Blue` (藍色)。
*   **功能新增**：在 `LED Color` 選單中新增了 `Rainbow` (全彩) 選項，選擇後遙控器實體光圈將呈現隨時間流動的動態彩虹跑馬燈特效。
*   **功能新增**：在左側面板新增動態「電量橫條 (Battery Bar)」，直接讀取 `Bat%` 遙測數據。電量大於 30% 顯示綠色，15%~30% 顯示橘色，低於 15% 顯示紅色。
*   **介面優化**：全面升級全透模式 (`Transp BG`) 的文字辨識度，為全域所有儀表文字 (包含標題、數值與使用者名稱) 加上黑色陰影，確保在任何顏色的桌布下皆清晰可讀。
*   **介面優化**：重新計算並調整全螢幕版面比例，包含延伸左側大面板以完整包覆電池資訊、均分右側三大面板的垂直間隙為標準 15px，以及加寬 GOV/STATUS 狀態框與電池 BAR 完美切齊，使整體視覺對齊更加工整舒適。
*   **介面優化**：針對全透背景 (TRN) 模式優化電量條顯示，即使電量為 0% 也能顯示專屬黑框。
*   **版面修復**：修正了 `f_mid` 字體在各狀態方塊 (OFF / SAFE / NO DATA / UserName) 中視覺偏下的問題，將 Y 軸微調以達到完美垂直置中。

### v1.0.001 重大更新與 Bug 修復
*   **介面自訂**：新增 `UserName` 選項，在有遙測訊號時，可將右下角的 "NO DATA" 區塊替換為您專屬的英文簽名 (無底框純白字體設計)。
*   **功能新增**：在設定選單中新增 `Arm Invert` (反向解鎖) 功能，方便不同遙控器開關習慣的飛友自行反轉 ARM/SAFE 的判斷邏輯。
*   **介面優化**：移除右上角電壓與時間中間多餘的斜線 `/`，讓畫面更乾淨；並於左下角加入淡淡的版本號浮水印 (`v 1.0.001`)。
*   **版面修復**：修正接上電池後，左下角電池資訊與 "NO DATA" 文字發生重疊的顯示錯誤。
*   **邏輯修復 (重大)**：修正了原版程式碼會將超過 200A 的電流強制縮小 10 倍的嚴重 Bug，現在 700/800 級直昇機的大電流也能精準顯示！
*   **邏輯修復**：修正了 `Arm Source` 設定無法正確讀取實體開關，導致上鎖 (SAFE) 狀態卡住的問題。
*   **邏輯修復**：修正了飛行中因大螺距壓降導致「電池 S 數」亂跳的問題，現在 S 數會在接上電池時準確鎖定。
*   **邏輯修復**：將單芯電壓的紅色警告閾值由過高的 3.8V 調降至合理的 3.5V，避免正常飛行時產生視覺干擾。
*   **邏輯修復**：修正使用邏輯開關 (Logical Switch) 觸發解鎖 (Arm) 時會導致腳本崩潰的錯誤。
*   **邏輯修復**：修正更換電池時，最高/最低電壓與轉速不會自動重置，且最低數值永遠卡在 0 的問題。

---

## 🇬🇧 English Description

**RBCT** is a comprehensive and visually rich helicopter dashboard widget for EdgeTX. It features dynamic resolution scaling, perfectly supporting the RadioMaster TX16S MK3 (800x480), TX16S MKII (480x272), and TX15 MAX (480x320) color displays. 

### Features

*   **Dynamic Resolution Scaling**: Automatically adapts layout, font sizes, and image scaling for different screens, ensuring a perfect fit across multiple radio models.
*   **Real-Time Telemetry Display**: Monitors and displays critical flight data including Battery Voltage, Current (Amps), Capacity (mAh), BEC Voltage, Lowest Cell Voltage, and ESC/MCU Temperatures.
*   **Smart Battery S-Cell Engine & S-Lock**:
    *   *Native Telemetry Priority*: Directly reads Rotorflight/EdgeTX `Cel#` (or `Cells`/`Cels`) sensor.
    *   *Exact Ratio Priority*: Derives cell count via $\text{round}(V_{bat} / V_{cel})$. Accurately identifies partially charged packs (e.g. 12S @ 45.9V/3.82V as 12S) and High Voltage LiHV packs (e.g. 12S @ 52.2V/4.35V as 12S).
    *   *Memory S-Lock*: Locks S-count into memory upon battery connection, preventing erratic S-count fluctuations during high-pitch punch-out voltage sags. Resets automatically upon battery disconnection.
*   **Headspeed Tracking**: Displays current Headspeed (RPM) along with maximum and minimum RPM statistics during the flight.
*   **Governor Status**: Clear visual indicator for Governor ON/OFF state.
*   **FBL Bank Switching**: Dynamically displays the current FBL (Flybarless) Bank number based on your switch configuration.
*   **Customizable Themes**: Choose from 9 built-in color themes (Red, Orange, Yellow, Green, Blue, Indigo, Violet, Black, TRN Transparent) to match your preference.
*   **Transparent Background Support**: 
    *   Toggle on `Transp BG` to make the main background transparent while keeping panel backgrounds for readability.
    *   Or select the `TRN` theme for a completely frameless, fully transparent experience.
*   **Physical Gimbal LED Control**: Directly control the physical RGB gimbal rings on supported radios (like TX16S MK3) from the widget, with 9 color options or OFF.
*   **Dynamic Model Images**: Automatically loads model pictures from `/IMAGES` or `/WIDGETS/RBCT/modelImage/`. Falls back to a default image if no specific image is found.
*   **Timer Integration**: Displays your selected flight timer prominently on the dashboard.

### Installation
1. Copy the `RBCT` folder into the `WIDGETS` directory on your SD card (`/WIDGETS/RBCT`).
2. On your radio, navigate to the Telemetry screen setup.
3. Select the `RBCT` widget and assign it to a full-screen layout.

### Changelog (v1.0.701)
*   **Feature Upgrade (Custom Voice Thresholds, LCD Theme & Auto Light Sensor)**:

    *   *LCD High Contrast Theme*: Added a low-saturation pale green-gray background with dark green text, dramatically improving readability under direct harsh sunlight.
    *   *Auto LCD Theme*: Added `Light Sens` to the widget menu. Supports both analog light sensors and logical/physical boolean switches (True/False). With a lightning-fast 0.2s debounce buffer, the dashboard instantly morphs into the LCD high-contrast theme when exposed to bright light or when the switch is flipped.
    *   *Custom Thresholds*: You can now directly set thresholds for `BEC Warn V` (5.0V~8.0V), `ESC Temp Warn` (40°C~110°C), and `Nitro Temp Warn` (80°C~160°C) directly from the widget menu.
    *   *Battery % Voice Assistant*: Added stepped low battery voice alarms, critical continuous alarms, and auto-reset when changing battery packs.
    *   *Bitmap Font Compatibility*: Optimized Chinese localization strings (`電池日誌` and `光感應LCD主題`) to perfectly match the EdgeTX MK3 dot-matrix font, eliminating missing character boxes.
    *   *Turbine Jet Module*: Added `Turbine` to the Heli Type options. Implements a stunning, true-to-life Glass Cockpit (EICAS) interface for Jet pilots, dynamically displaying `EGT`, `CORE RPM`, `FUEL %`, and `ECU STATE`.
    *   *Smart Battery S-Cell Detection*: Fixed issues where partially charged batteries (e.g. 12S @ 45.9V) were misidentified as 11S or 12S LiHV @ 52.2V as 13S. The widget now prioritizes Rotorflight native `Cel#` sensor and exact `Vbat/Vcel` ratio with in-flight S-locking.

### Changelog (v1.0.003)
*   **New Feature (Major)**: Upgraded the static `0 Flights` text to a Dual Dynamic Flight Counter! The dashboard now simultaneously displays `Today` (today's flights) and `Total` (lifetime total flights).
*   **New Feature (Ultimate Logbook)**: Added an **"On-Screen Flight Logbook Viewer"**! After landing, simply tap the screen (or short press the roller button) to flip the dashboard into a beautifully formatted table showing the last 10 flights for the current model. The table logs: `Time`, `Duration`, `Max RPM`, `Max Amps`, `Min Cell Voltage`, and `mAh consumed`.
  *   *Safety Guarantee*: Built with extreme optimization, zero SD card writes and zero data arrays are processed while ARMED, ensuring absolute safety with no UI stutter or telemetry lag during flight!
*   **New Feature**: Features SD card persistence with per-model tracking. Includes an auto-reset function where the `Today` count automatically resets to 0 on a new day, while the `Total` count continues to accumulate.
*   **New Feature**: Added a **60-Second Debounce Timer**. A flight is only counted and added to the logs if the helicopter remains ARMED for at least 60 continuous seconds. This prevents "ghost flights" from being recorded during quick bench testing or setup.
*   **New Feature**: Added a `Reset FlyCount` option in the widget settings. You can assign a physical switch (like a momentary SH switch) to manually reset the `Today` counter to 0 at any time (the lifetime total is safely preserved).
*   **Customization**: Added `Pink` and `Peach` options to both the dashboard `Theme` and the physical gimbal `LED Color` settings.

### Changelog (v1.0.002)
*   **Customization**: Added a `TRN` (Fully Transparent) theme. Selecting this theme removes all background panels and borders, and automatically applies a drop shadow to all text for perfect readability on any wallpaper.
*   **Customization**: Added a `Transp BG` (Transparent Background) toggle. When enabled, the main background becomes transparent to show your custom radio wallpaper, while the info panels retain their semi-dark background for readability.
*   **Customization**: Added a "Black" theme option for the dashboard `Theme`, offering a sleek and stealthy look. The default theme is now set to `Blue`.
*   **New Feature**: Added a `Rainbow` option to `LED Color`. When selected, the physical gimbal LEDs will display a dynamic, animated flowing rainbow effect.
*   **New Feature**: Added a dynamic Battery Bar to the left panel using `Bat%` telemetry. The bar changes color automatically (Green > 30%, Orange > 15%, Red <= 15%).
*   **UI Tweaks**: Upgraded text legibility in Transparent (`Transp BG`) mode by universally applying a black drop-shadow to all dashboard text (including titles, values, and UserName) for perfect contrast against any wallpaper.
*   **UI Tweaks**: Completely recalibrated the full-screen layout proportions. Extended the left main panel to fully enclose battery info, equalized the vertical gaps between the right panels to a standard 15px, and widened the GOV/STATUS blocks to perfectly align with the Battery Bar for a much cleaner and symmetrical look.
*   **UI Tweaks**: Optimized the battery bar for `TRN` (Transparent) mode with a visible border even at 0%.
*   **UI Fix**: Fixed vertical text alignment for "OFF", "SAFE", "NO DATA", and "UserName" to achieve perfect visual centering.

### Changelog (v1.0.001)
*   **Customization**: Added a `UserName` option to display your custom pilot name (clean white text with no frame) instead of "NO DATA" when telemetry is active.
*   **New Feature**: Added an `Arm Invert` option in the settings to easily reverse the physical switch logic for ARMED/SAFE statuses.
*   **UI Tweaks**: Removed the redundant `/` symbol between Tx voltage and clock for a cleaner header, and added a faint version watermark (`v 1.0.001`) below the battery capacity.
*   **UI Fix**: Fixed a layout bug where battery information overlapped with the "NO DATA" text in the bottom left corner when a battery was connected.
*   **Critical Fix**: Removed an incorrect >200A limit that caused high currents (common in 700/800 class helicopters) to be displayed 10x smaller.
*   **Bug Fix**: Fixed the `Arm Source` setting so it correctly reads physical switches, preventing the ARMED status from getting stuck.
*   **Bug Fix**: Locked the automatic battery cell count (S) to the maximum recorded voltage to prevent the cell count from randomly changing during in-flight voltage sag.
*   **Bug Fix**: Lowered the overly sensitive single-cell voltage warning threshold from 3.8V to 3.5V to avoid false red alarms during normal flights.
*   **Bug Fix**: Fixed a script crash when using Logical Switches (boolean values) as the Arm Source.
*   **Bug Fix**: Fixed an issue where Min/Max telemetry values (like lowest voltage) would get stuck at 0 and fail to automatically reset when changing to a new battery.
