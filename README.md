# RBCT Helicopter Dashboard Widget

**Author / 作者**: 雷恩 / Ryan Kuo
### Standard UI (預設標準介面)
![Standard UI](Pic/Standard%20UI.jpg?v=2)

### Clean UI (半透背景模式)
![Clean UI](Pic/Clean%20UI.jpg?v=2)

### Transparent UI (TRN 全透無框模式)
![Transparent UI](Pic/Transparent%20UI.jpg?v=2)

### Nitro UI (燃油引擎專屬模式)
![Nitro UI](Pic/Nitro%20UI.jpg?v=2)

### Battery Fleet Manager UI (機隊電池管理總表)
![Battery Fleet Manager UI](Pic/Battery%20UI.jpg?v=2)

### Logbook & Chart UI (飛行日誌與五線譜圖表)
![Logbook UI](Pic/Logbook%20UI.jpg?v=2)

### Widget Settings Menu (小工具設定選單)
![Menu UI](Pic/Menu%20UI.jpg?v=2)

(English below)

**RBCT** 是一個專為 EdgeTX 開發的直昇機儀表板小工具 (Widget)，支援多種螢幕解析度自動適應，完美適配 RadioMaster TX16S MK3 (800x480)、TX16S MKII (480x272) 以及 TX15 MAX (480x320) 等全彩觸控螢幕。提供完整、直覺的飛行數據監控介面。

## 🌟 核心功能

*   **跨機種解析度自適應**：自動偵測螢幕大小，無論是 800x480 或 480 寬度的螢幕，皆能自動調整字體與圖片比例，維持最佳顯示效果。
*   **黑盒子與五線譜飛行圖表 (Logbook & Chart Analyzer)**：透過實體開關 (Logbook Sw) 一鍵叫出，提供：
    *   **歷史數據表格**：自動記錄近期航班的極值摘要（MAX RPM, MAX A, MIN V, MIN BEC, MAX TMP, mAh）。
    *   **零負載極速繪圖引擎**：完全由記憶體運作的 5 線譜折線圖（綠線 RPM、橘線 電壓、紅線 電流、藍線 BEC、黃線 溫度），精準分析劇烈動作時的電壓陡降與掉轉現象。在解鎖狀態下甚至能呈現「即時調機」效果！
*   **機隊電池管理總表 (Battery Fleet Manager)**：自動獨立追蹤每包電池 (BAT 1 ~ BAT 6) 的循環次數、最低電壓、最高溫度與平均航程。
*   **自動飛行次數計數器 (Flight Counter)**：獨立追蹤每台機型的「今日飛行次數 (Today)」與「歷史總飛行次數 (Total)」，皆以純文字檔儲存於 SD 卡，支援手動編輯。
*   **即時遙測數據顯示**：監控並顯示包含電池總電壓 (Vbat)、電流 (A)、消耗容量 (mAh)、BEC 電壓、單節最低電壓 (Cell) 以及 ESC / MCU 溫度。
*   **智慧電池 S 數演算法與通電鎖定 (Smart Battery S-Cell Engine)**：
    *   *第一優先 (Native Telemetry)*：直接讀取 Rotorflight / EdgeTX 原生電池 S 數感測器 (`Cel#` / `Cells` / `Cels`)。
    *   *第二優先 (Exact Ratio)*：依總電壓與單芯電壓比例精確換算 $\\text{S} = \\text{round}(V_{bat} / V_{cel})$。完美解決未充飽/存儲電壓 (如 12S @ 45.9V/3.82V) 誤判為 11S，以及高壓鋰電 LiHV (如 12S @ 52.2V/4.35V) 誤判為 13S 的問題。
    *   *通電記憶體鎖定 (S-Lock)*：通電完成偵測後即將 S 數鎖定於記憶體，飛行中大螺距瞬間壓降絕不跳動；換電池或斷電自動重置。
*   **旋翼轉速監控 (Headspeed)**：即時顯示目前轉速 (RPM)，並記錄飛行過程中的最高 (max) 與最低 (min) 轉速。
*   **定速狀態指示 (Governor)**：提供醒目直覺的定速開啟/關閉 (ON/OFF) 狀態圖示。
*   **FBL 停懸段數 (Banks)**：根據您設定的遙控器開關或通道，動態顯示當前使用的 FBL 停懸段數 (Bank)。
*   **自訂儀表板主題色**：內建 10 種高對比主題色彩 (紅、橘、黃、綠、藍、靛、紫、黑、TRN 全透明、LCD 液晶高反差)，可依個人喜好自由切換。
*   **支援透明背景**：
    *   開啟獨立的「透明背景」開關：隱藏主底色，但保留各資訊面板的半透明框。
    *   選擇 `TRN` 主題：全透底、無框架模式，讓你的遙控器桌布成為絕對主角！
*   **實體方向桿光圈控制**：直接在小工具中同步控制支援此功能的遙控器 (如 TX16S MK3) 方向桿 RGB 光圈，支援 9 種顏色與關閉選項。
*   **動態模型圖片**：自動讀取位於 `/IMAGES` 或 `/WIDGETS/RBCT/modelImage/` 的模型圖片。若無圖片則自動載入預設圖。
*   **飛行計時器整合**：於儀表板顯眼處同步顯示所選的遙控器計時器。

## 📥 安裝說明

1. **複製小工具**：下載並將 `RBCT` 資料夾完整複製到遙控器 SD 卡內的 `WIDGETS` 目錄下 (路徑為 `/WIDGETS/RBCT`)。
2. **語音包安裝（將專案暫存 SOUND 複製到記憶卡根目錄 /SOUNDS/）🌟**：
   * **重要觀念**：專案內的 `RBCT/SOUND/`（內含 `tw`, `cn`, `en` 三套完整語音包）為**發布暫存安裝檔**；EdgeTX 運作時只會讀取**記憶卡根目錄的 `/SOUNDS/`**。
   * **繁體中文用戶（推薦 🌟）**：MK3 / EdgeTX 系統原生提供「繁體中文 (`tw`)」語音選項。若記憶卡無 `tw` 目錄，建議先將記憶卡根目錄的 `/SOUNDS/cn/` **複製一份並命名為 `tw`**（路徑為 `/SOUNDS/tw/`），再將專案 `SOUND/tw/` 內所有檔案**複製並覆蓋**進去，最後於系統設定將語音指向 **`tw`**。
   * **簡體中文用戶**：直接將專案 `SOUND/cn/` 內的所有檔案複製並覆蓋到記憶卡根目錄的 `/SOUNDS/cn/`，於系統設定將語音指向 **`cn`**。
   * **英文語音用戶**：直接將專案 `SOUND/en/` 內的所有檔案複製並覆蓋到記憶卡根目錄的 `/SOUNDS/en/`，於系統設定將語音指向 **`en`**。
3. **新增小工具**：在遙控器上進入 Telemetry (遙測) 畫面設定，新增一個全螢幕 (Full screen) 區塊，並選擇 `RBCT` 小工具。

## 🚁 模型圖片設定

若要自訂儀表板上的直昇機圖片：
*   請準備 `.png` 格式的去背圖片。
*   將圖片放入 `/WIDGETS/RBCT/modelImage/` 或 `/IMAGES/` 目錄，並將檔名命名為與「模型名稱」完全一致。
*   或者直接透過 EdgeTX 系統內建的模型圖片設定，小工具也會自動抓取顯示。

## 📝 版本更新歷程 (Release Notes)

### v1.0.7 / v1.0.701 (目前最新版)
* **介面自訂**：**液晶高反差強光主題 (LCD Theme)** - 新增低飽和綠灰液晶底色 (`RGB: 212, 224, 206`) 搭配高反差深墨綠文字 (`RGB: 15, 25, 20`)，戶外強光大太陽直射下閱讀清晰度大幅提升。
* **功能新增**：**光感應主題自動切換** - 選單新增 `光感主題開關`，支援實體光感應器或邏輯開關。感應到強光持續 1.5 秒防抖自動切換至 LCD 高反差主題；回歸陰影處自動恢復，解鎖飛行中自動鎖定當前主題。
* **功能新增**：**語音警示自訂門檻** - 選單可直接調整 `BEC 電壓警示` (5.0V~8.0V，8段)、`電變高溫警示` (40°C~110°C) 與 `油機高溫警示` (80°C~160°C)。
* **功能新增**：**階梯式電量語音提醒** - 支援 30%、20%、15% 跨階自動播報剩餘電量百分比，10% 沒電觸發強烈震動與急促警報音，換充飽新電池 (Bat% > 90%) 自動無感重置。
* **邏輯升級**：**智慧電池 S (CELL)數修正** - 優先讀取飛控原生 `Cel#` 感測器，並以 $\\text{round}(V_{bat} / V_{cel})$ 原生比例精確計算。完美支援存儲未充飽 (12S @ 45.9V) 與高壓 LiHV (12S @ 52.2V)；通電即鎖定至記憶體，3D 抽電壓降不跳 S 數。

### v1.0.6
* **功能新增**：**機隊電池管理系統** - 自動感測實體開關或邏輯開關 (6P1..6P6, SW1..SW6, L1..L6) 或 Bat Track 設定，支援獨立追蹤 BAT 1 ~ BAT 6。每包電池皆有獨立起降架次、最低電壓、最高溫度、平均飛行時間與日誌曲線檔。
* **功能新增**：**三段開關即時呼叫總表** - 透過 `Logbook Sw` 三段開關控制：切至中段 (MID) 顯示 5 線譜即時圖表；切至下段 (DOWN) 顯示 BATTERY FLEET MANAGER 機隊總表，當前選定電池以高亮綠框醒目標示，左下角浮水印同步顯示當前電池編號 (如 BAT 1)。
* **錯誤修復**：**純英文系統介面語言判斷修復** - 修復在純英文語系設定下，若 SD 卡內殘留中文語音包資料夾，會導致 Widget 設定選單文字因字型不支援中文字元而顯示空白的問題，嚴格優先依據系統語言進行判斷。

### v1.0.5 / v1.0.501
* **功能新增**：**智慧動態刻度系統** - 圖表座標軸導入無上限動態天井演算法。無論是 700 級 (12S/14S, 200A+ 大電流)、450 級 (6S) 或微型電直 (高轉速 10,000+ RPM)，刻度上限隨實際數據動態向上推升，曲線絕對不破頂、不掉框。
* **功能新增**：**最後一趟曲線 SD 卡自動存檔 (SD Persistence)** - 飛行結束切回上鎖 (DISARM) 時，自動將當前 200 個採樣點寫入 SD 卡 (`/WIDGETS/RBCT/chart_<機型>.txt`)。關機重開機或隨時點進 Logbook 都能完整還原上一趟飛行的動態遙測曲線。
* **邏輯修復**：**Bank 優先讀取飛控 PID# 遙測感測器** - 修復 Auto 模式下 Bank 顯示邏輯，優先讀取 Rotorflight active PID Profile 感測器 (`PID#` / `PID` / `Pid#` / `Bank`) 而非 Flight Mode (`FM`)，解決切換 Bank 時畫面卡在 `BANK 1` 的問題。
* **介面優化**：**油機 RX PACK 電壓置中微調** - 微調燃油模式右側 RX PACK 特大電壓數字與單位 (如 8.3V) 之橫向繪製 X 軸偏移量，使其於面板框內視覺呈現更加精確置中。
* **介面優化**：**常態刻度標籤顯示** - 座標軸左右刻度文字標籤解鎖抽離條件式，不論記憶體內是否有實時曲線數據，進入 Logbook 介面時圖表左右兩側的刻度數值標籤永遠固定清晰顯示。

### v1.0.003
* **功能新增**：**今日 / 總飛行架次雙計數器** - 將靜態文字升級為「雙重真實計數器」，畫面同時顯示 `Today` (今日次數) 與 `Total` (終身總次數)。
* **功能新增**：**無感飛行日誌報表 (Flight Logbook)** - 降落後在螢幕輕點或短按滾輪，畫面翻轉為該台直昇機最近 10 趟飛行報表，詳細記錄起飛時間、飛行時長、最高轉速、最大電流、最低電壓、消耗容量、最高溫度與最低 BEC。
* **介面優化**：**五線譜分析圖表物理分層** - 日誌下方新增 5 線譜即時圖表，物理分割為上下兩層 (上層：轉速/電壓/電流，下層：溫度/BEC)，解決刻度重疊並完美對齊時間 X 軸。
* **邏輯升級**：**智慧防呆計數過濾機制** - 解鎖超過 60 秒後，必須偵測到 `轉速 > 1000 RPM` 或 `電流 > 5A` 才會判定為真實飛行並計數 +1，桌上調機拔馬達絕不誤判「幽靈航班」。
* **功能新增**：**跨日自動歸零與 SD 卡獨立存檔** - 跨日午夜開機 `Today` 自動從 0 開始，`Total` 持續累積，依機型獨立存檔關機不遺失。
* **功能新增**：**手動獨立歸零開關 (`Reset FlyCount`)** - 設定選單可指派實體開關 (如 SH)，撥動瞬間即可手動將 `Today` 歸零 (不影響 Total)。
* **介面自訂**：**主題與光圈新增粉紅** - `Theme` 及 `LED Color` 選項新增 `Pink` 新色彩。

### v1.0.002
* **介面自訂**：**新增 `TRN` (全透明) 主題** - 隱藏所有背景底色與邊框線條，自動為文字加上黑色陰影，提供乾淨無框架視覺效果。
* **介面自訂**：**新增 `Transp BG` (透明背景) 開關** - 隱藏主背景底色露出遙控器桌布，保留各資訊區塊半透明底色。
* **介面自訂**：**新增黑色 (Black) 主題** - 新增低調暗黑風格，並將預設主題更改為 `Blue` (藍色)。
* **功能新增**：**新增 `Rainbow` (流動彩虹) 跑馬燈** - `LED Color` 選單新增 Rainbow 特效，遙控器實體光圈呈現隨時間流動的動態彩虹效果。
* **功能新增**：**新增動態電量橫條 (Battery Bar)** - 左側面板新增三色動態電量條，>30% 綠色、15%~30% 橘色、<15% 紅色。
* **介面優化**：**全域文字黑色陰影強化** - 全透模式為全域所有文字 (標題、數值與簽名) 加上柔和黑色陰影，任何桌布下皆清晰可讀。
* **介面優化**：**全螢幕版面比例精密校正** - 延伸左側面板包覆電池資訊，均分右側面板垂直間隙為 15px，加寬 GOV/STATUS 與電量條切齊。
* **介面優化**：**全透模式電量條框線優化** - TRN 模式下電量為 0% 亦保留專屬黑框。
* **錯誤修復**：**狀態文字垂直置中修復** - 修正 `f_mid` 字體在狀態方塊 (OFF / SAFE / NO DATA / UserName) 中偏下問題，微調 Y 軸達到完美垂直置中。

### v1.0.001 重大更新與 Bug 修復
* **介面自訂**：**飛手專屬數位簽名** - 有遙測訊號時，將右下角 "NO DATA" 區塊替換為專屬英文簽名 (無底框純白字體)。
* **功能新增**：**圖示反向解鎖切換** - 提供解鎖圖示反向顯示設定(僅顯示，非功能切換)。
* **介面優化**：**標頭視覺淨化與版本浮水印** - 移除右上角電壓與時間中間多餘斜線 `/`；左下角加入淡淡版本號浮水印 (`v 1.0.001`)。
* **錯誤修復**：**電池資訊與 NO DATA 重疊修復** - 修正接上電池後，左下角電池資訊與 "NO DATA" 文字發生重疊的顯示錯誤。
* **邏輯修復**：**大電流 200A+ 縮小 10 倍 Bug 修復 (重大)** - 修正原版程式碼會將超過 200A 電流強制除以 10 的嚴重 Bug，700/800 級直昇機大電流精準顯示。
* **邏輯修復**：**`Arm Source` 實體開關讀取修復** - 修正無法正確讀取實體開關導致上鎖 (SAFE) 狀態卡住問題。
* **邏輯修復**：**通電鎖定 S 數防亂跳** - 修正飛行中因大螺距壓降導致「電池 S 數」亂跳問題，接上電池時準確鎖定。
* **邏輯修復**：**單芯低壓警示門檻調整** - 將單芯電壓紅色警告閾值由過高的 3.8V 調降至合理的 3.5V，避免正常飛行產生視覺干擾。
* **邏輯修復**：**邏輯開關解鎖崩潰修復** - 修正使用邏輯開關 (Logical Switch) 觸發解鎖 (Arm) 時會導致腳本崩潰的錯誤。

---

## 🇺🇸 English Documentation

**RBCT** is an advanced helicopter dashboard telemetry widget crafted for EdgeTX, with multi-resolution scaling for RadioMaster TX16S MK3 (800x480), TX16S MKII (480x272), and TX15 MAX (480x320) full-color touchscreens.

### Changelog (v1.0.7 / v1.0.701 - Current Release)
* **UI Customization**: **LCD High-Contrast Theme** - Low-saturation pale green-gray background with dark green text for extreme direct sunlight legibility.
* **New Feature**: **Auto Light Sensor Theme Switching** - Added `Light Theme Sw` with 1.5s debounce buffer, automatically locking theme while ARMED.
* **New Feature**: **Custom Voice Warning Thresholds** - Configurable `BEC Warn V` (5.0V~8.0V), `ESC Temp Warn` (40°C~110°C), and `Nitro Temp Warn` (80°C~160°C).
* **New Feature**: **Step-Down Battery Voice Alarms** - Stepped 30%, 20%, 15% battery voice announcements, 10% critical continuous haptic alarm, and fresh battery (>90%) auto-reset.
* **Logic Upgrade**: **Smart Battery S (Cell) Count Fix** - Prioritizes Rotorflight native `Cel#` sensor and exact $\\text{round}(V_{bat}/V_{cel})$ ratio, supporting storage (12S @ 45.9V) and LiHV (12S @ 52.2V) packs with in-flight RAM S-Lock.

### Changelog (v1.0.6)
* **New Feature**: **Battery Fleet Manager** - Auto-senses switches (6P1..6P6, SW1..SW6, L1..L6) or Bat Track to independently track BAT 1 ~ BAT 6 cycles, min voltage, max temp, avg flight duration, and chart logs.
* **New Feature**: **3-Position Switch Fleet Manager View** - `Logbook Sw` MID opens 5-line chart; DOWN opens Battery Fleet Manager summary table with active pack highlighted in green and watermark showing current pack (e.g. BAT 1).
* **Bug Fix**: **English System Language Detection Fix** - Strictly prioritizes system language over residual SD audio folders to eliminate blank menu options on English radios.

### Changelog (v1.0.5 / v1.0.501)
* **New Feature**: **Smart Dynamic Ceiling Engine** - Dynamic Y-axis ceiling engine auto-expands graph scales based on live telemetry data (e.g. RPM in 500 RPM increments, current up to 200A+), preventing clipped curves across all helicopter sizes.
* **New Feature**: **SD Card Last Flight Chart Persistence** - Automatically persists 200 telemetry sampling points to SD card upon DISARM (`/WIDGETS/RBCT/chart_<craft>.txt`), allowing full chart reload after power cycling.
* **Logic Fix**: **Bank Telemetry Detection Fix** - Fixed Auto Bank detection by prioritizing Rotorflight active PID Profile sensors (`PID#` / `PID` / `Pid#` / `Bank`) over Flight Mode (`FM`), resolving stuck `BANK 1` issue.
* **UI Optimization**: **Nitro RX PACK Voltage Centering** - Fine-tuned horizontal X offset for RX PACK oversized voltage text in Nitro mode for perfect visual centering.
* **UI Optimization**: **Permanent Scale Labels** - Y-axis numerical scale labels remain permanently visible upon entering the Logbook regardless of real-time buffer state.

### Changelog (v1.0.003)
* **New Feature**: **Dual Dynamic Flight Counter** - Simultaneously displays `Today` (today's flights) and `Total` (lifetime total flights).
* **New Feature**: **On-Screen Flight Logbook Viewer** - Tap screen or short press roller to flip into recent 10-flight logbook table logging Time, Duration, Max RPM, Max Amps, Min Cell Voltage, and mAh consumed with zero SD writes while ARMED.
* **UI Optimization**: **Dual-Layer 5-Line Telemetry Chart** - Split graph into upper layer (RPM/Vbat/Amps) and lower layer (Temp/BEC) with aligned time axis.
* **Logic Upgrade**: **Anti-Crash Engine (FIFO Buffer & Dynamic Downsampling)** - 200-sample ring buffer and 50-point downsampling guarantee $O(1)$ constant CPU load without `CPU LIMIT` panic.
* **Logic Upgrade**: **60s Debounce & Threshold Filter** - Requires ARMED > 60s and RPM > 1000 or Current > 5A to count flight, eliminating bench testing ghost flights.
* **New Feature**: **Auto Midnight Reset & SD Persistence** - Today counter resets to 0 daily while Total persists per model.
* **New Feature**: **Manual Reset Switch (`Reset FlyCount`)** - Assign momentary switch (e.g. SH) to reset Today count instantly.
* **UI Customization**: **Pink Color Option** - Added `Pink` color option to `Theme` and `LED Color` menus.

### Changelog (v1.0.002)
* **UI Customization**: **`TRN` Fully Transparent Theme** - Removes background panels/borders with text drop shadows for clean frameless look.
* **UI Customization**: **`Transp BG` Transparent Background** - Hides main background while keeping translucent widget frames.
* **UI Customization**: **Black Theme** - Added stealth Black theme; updated default theme to Blue.
* **New Feature**: **Flowing Rainbow Gimbal LED** - Added dynamic animated flowing rainbow mode to `LED Color`.
* **New Feature**: **Dynamic Battery Bar** - 3-color dynamic battery percentage bar on left panel (>30% Green, 15%~30% Orange, <=15% Red).
* **UI Optimization**: **Universal Text Drop Shadows** - Added soft black shadows to all text in transparent mode for maximum contrast.
* **UI Optimization**: **Full-Screen Layout Proportions** - Equalized vertical panel spacing to 15px and aligned GOV/STATUS blocks with Battery Bar.
* **UI Optimization**: **TRN Battery Bar Border** - Preserves border frame even at 0% battery.
* **Bug Fix**: **Status Text Vertical Centering** - Corrected Y-axis alignment for "OFF", "SAFE", "NO DATA", and "UserName".

### Changelog (v1.0.001)
* **UI Customization**: **Pilot Callsign (`UserName`)** - Replaces "NO DATA" with custom pilot callsign signature in crisp white font.
* **New Feature**: **Arm Icon Invert Option** - Option to invert ARMED/SAFE icon display direction (display only, does not invert switch behavior).
* **UI Optimization**: **Header Cleanup & Version Watermark** - Removed redundant `/` in header and added faint watermark (`v 1.0.001`).
* **Bug Fix**: **Battery Info & NO DATA Overlap Fix** - Fixed text overlapping bug in bottom-left corner upon battery connection.
* **Logic Fix**: **High Current >200A Critical Fix** - Removed incorrect 10x scale division bug for 700/800 class helicopters.
* **Logic Fix**: **`Arm Source` Physical Switch Fix** - Fixed switch reading issue that caused stuck SAFE status.
* **Logic Fix**: **Battery Cell Count (S) Lock** - Locks cell count upon connection to prevent jitter during high-pitch punch-out.
* **Logic Fix**: **Single Cell Low Voltage Threshold** - Adjusted default warning threshold from 3.8V to 3.5V.
* **Logic Fix**: **Logical Switch Arm Crash Fix** - Fixed script crash when using logical boolean switches.
* **Logic Fix**: **Telemetry Min/Max Reset on Battery Swap** - Fixed issue where Min/Max telemetry values failed to reset upon battery swap.
