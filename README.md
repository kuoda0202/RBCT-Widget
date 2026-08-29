# RBCT Helicopter Dashboard Widget

**Author / 作者**: 雷恩 / Ryan Kuo
### Standard UI (預設標準介面)
![Standard UI](Pic/Standard%20UI.jpg?v=1.0.8)

### Clean UI (半透背景模式)
![Clean UI](Pic/Clean%20UI.jpg?v=1.0.8)

### Transparent UI (TRN 全透無框模式)
![Transparent UI](Pic/Transparent%20UI.jpg?v=1.0.8)

### Nitro UI (燃油引擎專屬模式)
![Nitro UI](Pic/Nitro%20UI.jpg?v=1.0.8)

### Turbine UI (渦輪噴射專屬模式)
![Turbine UI](Pic/Turbine%20UI.jpg?v=1.0.8)

### Battery Fleet Manager UI (機隊電池管理總表)
![Battery Fleet Manager UI](Pic/Battery%20UI.jpg?v=1.0.8)

### Logbook & Chart UI (飛行日誌與曲線圖表)
![Logbook UI](Pic/Logbook%20UI.jpg?v=1.0.8)

### Multilingual Widget Settings Menu (小工具設定選單)
![Menu UI](Pic/Menu%20UI.jpg?v=1.0.8)

### Multilingual UI (多語系主畫面)
![Menu UI](Pic/Standard%20UI_tw.jpg?v=1.0.8)

### Flight session stats UI (觸控子畫面)
![Menu UI](Pic/Flight%20session%20stats.jpg?v=1.0.8)

### Battery Health (多語系主畫面)
![Menu UI](Pic/Battery%20Health.jpg?v=1.0.8)

### Headspeed (多語系主畫面)
![Menu UI](Pic/Headspeed.jpg?v=1.0.8)

(English below)

**RBCT** 是一個專為 EdgeTX 開發的直昇機儀表板小工具 (Widget)，支援多種螢幕解析度自動適應，完美適配 RadioMaster TX16S MK3 (800x480)、TX16S MKII (480x272) 以及 TX15 MAX (480x320) 等全彩觸控螢幕。提供完整、直覺的飛行數據監控介面。

## 🌟 核心功能

*   **飛行日誌與 5 色曲線分析圖 (Logbook & Chart Analyzer)**：透過實體開關 (Logbook Sw) 一鍵叫出，提供：
    *   **9 欄歷史數據表格**：自動記錄近期航班極值（起飛時間 RTC、飛行時長、最高轉速 MAX RPM、最高電流 MAX A、最高功率 MAX PWR、最低電壓 MIN V、最低接收 MIN 1RSS、電變最高溫 MAX TMP、已消耗 mAh）。
    *   **最新一次飛行 5 色動態曲線圖**：綠線 RPM、橘線 電壓、紅線 電流、藍線 BEC、黃線 溫度，呈現劇烈 3D 動作時的電壓陡降與掉轉現象，降落上鎖 (DISARM) 自動存檔關機不遺失！
*   **機隊電池管理總表 (Battery Fleet Manager)**：自動獨立追蹤每包電池 (BAT 1 ~ BAT 6) 的循環次數、歷史最低電壓、電變最高溫 (MAX ESC TMP) 與平均航程。
*   **自動飛行次數計數器 (Flight Counter)**：獨立追蹤每台機型的「今日飛行次數 (Today)」與「歷史總飛行次數 (Total)」，皆以純文字檔儲存於 SD 卡，支援手動編輯。
*   **即時遙測數據顯示**：監控並顯示包含電池總電壓 (Vbat)、電流 (A)、消耗容量 (mAh)、BEC 電壓、單節最低電壓 (Cell) 以及 ESC / MCU 溫度。
*   **智慧電池 S 數演算法與通電鎖定 (Smart Battery S-Cell Engine)**：
*   **主旋翼轉速監控 (Headspeed)**：即時顯示目前轉速 (RPM)，並記錄飛行過程中的最高 (max) 與最低 (min) 轉速。
*   **定速狀態指示 (Governor)**：提供醒目直覺的定速開啟/關閉 (ON/OFF) 狀態圖示。
*   **特技模式通道對映(Banks)**：根據您設定的遙控器開關或通道，動態顯示當前使用的 FBL 停懸段數 (Bank)。
*   **多套儀表板主題配色**：內建 11 種高對比主題色彩 (Red, Orange, Yellow, Green, Blue, Cyan, Violet, Black, TRN 全透明, Pink, LCD 高反差)，可依個人喜好自由切換，支援透明背景與磨砂顯示**：
*   **搖桿光圈控制**：搖桿 RGB 光圈控制，支援 9 種顏色與關閉選項。
*   **動態模型圖片**：自動讀取位於 `/IMAGES` 或 `/WIDGETS/RBCT/modelImage/` 的模型圖片。若無圖片則自動載入預設圖。
*   **飛行計時器整合**：於儀表板顯眼處同步顯示所選的遙控器計時器。
*   **全方位三語系 UI 即時自動切換 (繁中 / 簡中 / 英文)三種語系UI**：
    *   *三種飛行切換模式*：支援 電動/燃油引擎/噴射等三種動力直升機模式。
    *   *全介面完整覆蓋*：主儀表板 HUD、三大觸控診斷彈窗（電池狀態、轉速與飛行曲線、飛行統計）、黑盒子日誌 (Tab 1) 與機隊電池管理總表 (Tab 2) 全面支援即時多語系對映。

## 📥 安裝說明

1. **複製小工具**：下載並將 `RBCT` 資料夾完整複製到遙控器 SD 卡內的 `WIDGETS` 目錄下 (路徑為 `/WIDGETS/RBCT`)。
2. **語音包安裝（將SOUNDS.RAR 解壓複製到記憶卡根目錄 /SOUNDS/）🌟**：
   * **繁體中文用戶（推薦 🌟）**：MK3 / EdgeTX 系統原生提供「繁體中文 (`tw`)」語音選項。若記憶卡無 `tw` 目錄，建議先將記憶卡根目錄的 `/SOUNDS/cn/` **複製一份並命名為 `tw`**（路徑為 `/SOUNDS/tw/`），再將專案 `SOUND/tw/` 內所有檔案**複製並覆蓋**進去，最後於系統設定將語音指向 **`tw`**。
3. **新增小工具**：在遙控器上進入 Telemetry (遙測) 畫面設定，新增一個全螢幕 (Full screen) 區塊，並選擇 `RBCT` 小工具。

## 🚁 模型圖片設定

若要自訂儀表板上的直昇機圖片：
*   請準備 `.png` 格式的去背圖片。
*   將圖片放入 `/WIDGETS/RBCT/modelImage/` 或 `/IMAGES/` 目錄，並將檔名命名為與「模型名稱」完全一致。
*   或者直接透過 EdgeTX 系統內建的模型圖片設定，小工具也會自動抓取顯示。

## 📝 版本更新歷程 (Release Notes)

### v1.0.8 (目前最新版)
* **功能新增**：**三語系 UI 即時切換，支援 `自動 (Auto)`、`英文 (English)`、`中文 (TW)`、`中文 (CN)`，且與語音播報完全獨立運作。
* **防護升級**：**飛行架次嚴格三重防呆鎖** - 偵測到直升機通電連線 (`Vbat >= 5.0V` 或 `BEC >= 3.5V`) 且有效解鎖 >15 秒或轉速 >400 RPM 才計次；遙控器未連線直升機或工作台除錯絕不誤計次。
* **功能新增**：**渦輪噴射直昇機模式支援** - 即時監控 `EGT` 尾氣溫度（超溫大紅字警報）、`CORE RPM` 100k+ 超高核心轉速、`FUEL %` 油量百分比與低油位語音提醒、以及 `ECU STATE` 即時狀態碼（OFF / START / RUN / COOL / ERROR）。
* **功能新增**：**跟随RF 模型名稱動態辨識 (Craft Name Auto-Sync)** - 自動讀取飛控廣播之"Craft Name"，比對 SD 卡同名圖檔載入愛機照片，並將飛行架次、機隊電池與飛行日曲線依機型獨立歸檔，達成一組設定通用全機隊。
* **介面優化**：**模型圖片全解析度自適應** - 原生支援 PNG/JPG/BMP 全格式，大圖自動等比超採樣壓縮並觸發抗鋸齒，小圖自動等比放大填滿，支援 2D 水平與垂直置中。
* **介面優化**：**新增全螢幕觸控引擎** - 劃分左上（飛行數據）、左下（電池健康度）與右上（轉速與 ESC 極值）三大獨立觸控熱區，極速秒開子頁。
* **介面優化**：**模型上電提示橫幅與音效回饋** - 插上電池彈出 10 秒平滑倒數條（顯示 `電池已連線: 將記錄於 BAT 1`）與提示音，解鎖後(ARM) 瞬間自動隱藏。
* **介面優化**：**圖示與曲線計算顯示優化**。
* **介面優化**：**日誌與機隊總表隔行斑馬紋色塊美化** - Logbook (Tab 1) 飛行日誌表與 Battery Fleet (Tab 2) 機隊總表導入交替色塊背景 (`C.panel`) 與當前選定電池高亮框 (`C.panel2` + `C.blue`)，大幅提升橫向數據檢視舒適度。
* **邏輯修復**：**機型預設值校正** - 新增模型預設動力模式一律對齊為 `電機 (Electric)` 模式。

### v1.0.7 / v1.0.701
* **介面自訂**：**液晶高反差強光主題 (LCD Theme)** - 新增低飽和綠灰液晶底色 (`RGB: 212, 224, 206`) 搭配高反差深墨綠文字 (`RGB: 15, 25, 20`)，戶外強光大太陽直射下閱讀清晰度大幅提升。
* **功能新增**：**光感應主題自動切換** - 選單新增 `光感主題開關`，支援實體光感應器或邏輯開關。感應到強光持續 1.5 秒防抖自動切換至 LCD 高反差主題；回歸陰影處自動恢復，解鎖飛行中自動鎖定當前主題。
* **功能新增**：**語音警示自訂門檻** - 選單可直接調整 `BEC 電壓警示` (5.0V~8.0V，8段)、`電變高溫警示` (40°C~110°C) 與 `油機高溫警示` (80°C~160°C)。
* **功能新增**：**階梯式電量語音提醒** - 支援 30%、20%、15% 跨階自動播報剩餘電量百分比，10% 沒電觸發強烈震動與急促警報音，換充飽新電池 (Bat% > 90%) 自動無感重置。
* **邏輯升級**：**智慧電池 S (CELL)數修正** - 優先讀取飛控原生 `Cel#` 感測器，並以 $\text{round}(V_{bat} / V_{cel})$ 原生比例精確計算。完美支援存儲未充飽 (12S @ 45.9V) 與高壓 LiHV (12S @ 52.2V)；通電即鎖定至記憶體，3D 抽電壓降不跳 S 數。

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
* **介面優化**：**曲線分析圖表物理分層** - 日誌下方新增即時曲線圖表，物理分割為上下兩層 (上層：轉速/電壓/電流，下層：溫度/BEC)，解決刻度重疊並完美對齊時間 X 軸。
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

### v1.0.000 (初始上線版本)
* **初始發布**：**RBCT 直昇機儀表板小工具正式上線** - 專為 EdgeTX 與 Rotorflight 飛控打造的高階直昇機全彩儀表板小工具，支援 480×272、480×320 及 800×480 多解析度自適應座艙介面。
* **核心功能**：**即時遙測 HUD 監控** - 整合監控電池總電壓 (Vbat)、單芯電壓 (Cell)、即時電流 (A)、消耗電量 (mAh)、旋翼轉速 (RPM)、定速 (GOV)、BEC 供電電壓與 ESC 電變溫度。
* **核心功能**：**FBL 段數與解鎖指示** - 動態顯示當前 FBL PID Bank 段數與 ARMED / SAFE 解鎖狀態圖示。
* **介面自訂**：**多款色彩主題與模型圖片** - 內建 8 種高對比主題色彩，支援讀取 SD 卡 `/IMAGES/` 模型同名圖片顯示。

---

## 🇺🇸 English Documentation

**RBCT** is a helicopter dashboard telemetry widget crafted for EdgeTX, featuring multi-resolution auto-adaptation to perfectly fit full-color touchscreens such as RadioMaster TX16S MK3 (800x480), TX16S MKII (480x272), and TX15 MAX (480x320). It provides a comprehensive and intuitive flight telemetry monitoring interface.

## 🌟 Core Features

*   **Logbook & 5-Color Telemetry Chart Analyzer**: Summoned instantly via a physical switch (`Logbook Sw`), offering:
    *   **9-Column Historical Data Table**: Automatically logs flight extremes (Takeoff RTC Time, Duration, MAX RPM, MAX Current (A), MAX Power (PWR), MIN Voltage (V), MIN Receiver (1RSS), MAX ESC Temperature (TMP), and mAh Consumed).
    *   **Latest Flight 5-Color Dynamic Chart**: Visualizes RPM (Green), Voltage (Orange), Current (Red), BEC (Blue), and Temperature (Yellow) to display voltage sag and headspeed drop during extreme 3D maneuvers; auto-saved upon landing/disarm (DISARM) without data loss!
*   **Battery Fleet Manager**: Independently tracks each battery pack (BAT 1 ~ BAT 6) for cycle counts, lowest historical voltage, peak ESC temperature (MAX ESC TMP), and average flight duration.
*   **Automatic Flight Counter**: Independently tracks "Today's Flights (Today)" and "Lifetime Total Flights (Total)" per model profile, both stored as plain-text files on the SD card for manual editing.
*   **Real-Time Telemetry Data Display**: Monitors and displays total battery voltage (Vbat), current (A), consumed capacity (mAh), BEC voltage, lowest single-cell voltage (Cell), and ESC / MCU temperatures.
*   **Smart Battery S-Cell Engine & Power-On Lock**: Accurately calculates cell count upon power-on and locks it in memory to prevent cell count shifting during heavy 3D load voltage sags.
*   **Rotor Headspeed Monitoring**: Displays live RPM and records maximum (max) and minimum (min) headspeed throughout the flight.
*   **Governor Status Indicator**: Provides prominent and intuitive Governor ON/OFF status icons.
*   **Flight Mode / Bank Channel Mapping**: Dynamically displays the active FBL bank / profile based on your configured radio switch or channel.
*   **Multiple Dashboard Color Themes**: Built-in 11 high-contrast color themes (Red, Orange, Yellow, Green, Blue, Cyan, Violet, Black, TRN full transparency, Pink, LCD high contrast), freely switchable with support for transparent background and frosted glass effects.
*   **Gimbal Stick LED Control**: Gimbal RGB LED ring control with 9 colors and OFF mode.
*   **Dynamic Craft Model Pictures**: Automatically loads model pictures from `/IMAGES/` or `/WIDGETS/RBCT/modelImage/`. Loads a default image if no matching image is found.
*   **Flight Timer Integration**: Prominently displays the selected radio timer on the dashboard.
*   **Comprehensive Tri-Language Real-Time UI Switcher (Traditional Chinese / Simplified Chinese / English)**:
    *   *Three Flight Modes*: Supports Electric, Nitro Engine, and Turbine Jet helicopter modes.
    *   *Full Interface Coverage*: Main HUD, 3 touch diagnostic popups (Battery Health, RPM & Flight Curves, Flight Stats), Blackbox Logbook (Tab 1), and Battery Fleet Manager (Tab 2) all feature synchronized real-time multi-language localization.

## 📥 Installation Instructions

1. **Copy Widget**: Download and copy the entire `RBCT` folder into the `WIDGETS` directory on your radio's SD card (path: `/WIDGETS/RBCT`).
2. **Voice Pack Installation (Extract SOUNDS.RAR to the SD card root `/SOUNDS/`) 🌟**:
   * **Traditional Chinese Users (Recommended 🌟)**: MK3 / EdgeTX natively provides a "Traditional Chinese (`tw`)" voice option. If the SD card lacks a `tw` directory, it is recommended to **duplicate `/SOUNDS/cn/` and rename it to `tw`** (path: `/SOUNDS/tw/`), then **copy and overwrite** all files from the project's `SOUND/tw/` into it, and finally set the system voice language to **`tw`** in system settings.
3. **Add Widget**: Enter Telemetry screen setup on your radio, add a Full Screen zone, and select the `RBCT` widget.

## 🚁 Model Picture Setup

To customize the helicopter picture on the dashboard:
*   Prepare a transparent `.png` image.
*   Place the image in `/WIDGETS/RBCT/modelImage/` or `/IMAGES/` on your SD card, naming the file identically to your "Model Name".
*   Alternatively, assign a model image via the native EdgeTX Model Setup menu; the widget will also automatically load and display it.

## 📝 Release Notes & Version History

### v1.0.8 (Current Release)
* **New Feature**: **Tri-Language UI Real-Time Switcher** - Supports `Auto`, `English`, `Chinese (TW)`, and `Chinese (CN)`, operating completely independently from voice alerts.
* **Safety Upgrade**: **Triple-Shield Flight Count Protection** - Counts flights only when heli telemetry connection is detected (`Vbat >= 5.0V` or `BEC >= 3.5V`) and armed for >15s or rotor RPM >400. Powered-off radio bench debugging will never false-count.
* **New Feature**: **Turbine Jet Helicopter Mode Support** - Real-time monitoring of `EGT` exhaust gas temperature (large red over-temp warning), `CORE RPM` 100k+ high core speed, `FUEL %` fuel percentage with low fuel voice alerts, and `ECU STATE` live status codes (OFF / START / RUN / COOL / ERROR).
* **New Feature**: **Craft Name Auto-Sync** - Automatically reads "Craft Name" broadcasted by flight controller, matches the same-named image on the SD card to load the model photo, and archives flight counts, fleet batteries, and flight charts independently per craft, enabling a single configuration for your entire fleet.
* **UI Optimization**: **Universal Model Image Auto-Fit** - Native support for all PNG/JPG/BMP formats, automatically supersampling and downscaling large images with anti-aliasing, scaling up small images proportionally to fill, and supporting 2D horizontal and vertical centering.
* **UI Optimization**: **Full-Screen Touch Engine** - Divides into top-left (Flight Data), bottom-left (Battery Health), and top-right (RPM & ESC Extremes) three independent touch zones for instant subpage access.
* **UI Optimization**: **Power-On Battery Prompt Banner & Audio Feedback** - Displays a 10-second smooth countdown bar upon battery plug-in (showing `Battery Connected: Logging to BAT 1`) with prompt tone, automatically hiding immediately after arming (ARM).
* **UI Optimization**: **Icon & Chart Calculation Display Optimization**.
* **UI Optimization**: **Zebra Row Striping for Tables** - Introduced alternating row background color blocks (`C.panel`) and active pack row highlight (`C.panel2` + `C.blue` border) across Logbook (Tab 1) and Battery Fleet Manager (Tab 2) tables for optimal reading legibility.
* **Logic Fix**: **Default Heli Mode Calibration** - Defaults new model power mode to `Electric` mode.

### v1.0.7 / v1.0.701
* **UI Customization**: **LCD High-Contrast Sunlight Theme (LCD Theme)** - Added low-saturation pale green-gray LCD background (`RGB: 212, 224, 206`) with high-contrast dark green text (`RGB: 15, 25, 20`), dramatically improving legibility under bright outdoor direct sunlight.
* **New Feature**: **Light Sensor Auto Theme Switching** - Added `Light Theme Sw` in settings, supporting physical light sensors or logical switches. Automatically switches to LCD high-contrast theme when strong light is detected for 1.5s (debounce buffer); restores automatically in the shade, and locks current theme during armed flight.
* **New Feature**: **Custom Voice Warning Thresholds** - Directly configure `BEC Voltage Warn` (5.0V~8.0V, 8 steps), `ESC Temp Warn` (40°C~110°C), and `Nitro Temp Warn` (80°C~160°C) in the menu.
* **New Feature**: **Stepped Battery Voice Alerts** - Automatically announces remaining battery percentage across stepped tiers at 30%, 20%, and 15%; triggers strong vibration and urgent alarm tone at 10% critical battery; automatically resets silently upon inserting a fresh charged battery (Bat% > 90%).
* **Logic Upgrade**: **Smart Battery S (Cell) Count Correction** - Prioritizes flight controller native `Cel#` sensor and calculates precisely with native $\text{round}(V_{bat} / V_{cel})$ ratio. Perfectly supports storage-charge un-topped packs (12S @ 45.9V) and high-voltage LiHV packs (12S @ 52.2V); locks to RAM upon power-on so aggressive 3D voltage sag will not alter cell count.

### v1.0.6
* **New Feature**: **Battery Fleet Manager** - Automatically senses physical switches or logical switches (6P1..6P6, SW1..SW6, L1..L6) or Bat Track settings to independently track BAT 1 ~ BAT 6. Each battery pack has independent flight count, lowest voltage, highest temperature, average flight duration, and log chart files.
* **New Feature**: **3-Position Switch Instant Fleet Summary View** - Controlled via 3-position `Logbook Sw`: switch to MID position to display 5-line real-time chart; switch to DOWN position to display BATTERY FLEET MANAGER summary table, highlighting active selected battery with a green border and displaying current battery number watermark in the bottom-left corner (e.g. BAT 1).
* **Bug Fix**: **English System UI Language Detection Fix** - Fixed an issue where under pure English system settings, residual Chinese voice folders on the SD card caused widget setting menu items to render blank due to missing font support for Chinese characters, now strictly prioritizing system language for evaluation.

### v1.0.5 / v1.0.501
* **New Feature**: **Smart Dynamic Scaling System** - Introduced an uncapped dynamic ceiling algorithm for chart axes. Whether for 700-class (12S/14S, 200A+ high current), 450-class (6S), or micro helis (high speed 10,000+ RPM), the scale ceiling dynamically expands with live telemetry data, ensuring curves never clip or overflow the frame.
* **New Feature**: **Last Flight Chart SD Card Auto-Persistence (SD Persistence)** - Automatically writes current 200 sample points to SD card (`/WIDGETS/RBCT/chart_<craft>.txt`) upon disarming (DISARM). Powering down, rebooting, or opening Logbook at any time will fully restore the dynamic telemetry chart of the previous flight.
* **Logic Fix**: **Bank Priority Reading from Flight Controller PID# Sensor** - Fixed Bank display logic in Auto mode by prioritizing Rotorflight active PID Profile sensors (`PID#` / `PID` / `Pid#` / `Bank`) over Flight Mode (`FM`), resolving the issue where Bank was stuck on `BANK 1` when switching banks.
* **UI Optimization**: **Nitro RX PACK Voltage Centering Adjustment** - Fine-tuned the horizontal X-axis offset for the oversized RX PACK voltage number and unit (e.g. 8.3V) in Nitro mode for precise visual centering within the panel frame.
* **UI Optimization**: **Permanent Scale Labels Display** - Decoupled axis scale labels from conditional rendering so that regardless of whether real-time chart data exists in memory, numerical scale labels on both sides of the chart remain permanently and clearly visible when entering the Logbook interface.

### v1.0.003
* **New Feature**: **Dual Today / Total Flight Counters** - Upgraded static text to "Dual Real Counters", simultaneously displaying `Today` (today's flights) and `Total` (lifetime total flights).
* **New Feature**: **Flight Logbook Report (Flight Logbook)** - Tap the screen or short-press the roller after landing to flip to the recent 10-flight report for the model, logging takeoff time, flight duration, max headspeed, max current, min voltage, consumed capacity, max temperature, and min BEC voltage.
* **UI Optimization**: **Dual-Layer Telemetry Chart Separation** - Added real-time telemetry chart below logbook, physically divided into upper and lower layers (Upper: RPM/Voltage/Current, Lower: Temperature/BEC), eliminating scale overlap and perfectly aligning the time X-axis.
* **Logic Upgrade**: **Smart Filter Counter Protection** - After arming for over 60 seconds, requires `RPM > 1000 RPM` or `Current > 5A` to qualify as a real flight and increment counter by 1; bench testing with motor unplugged will never count "ghost flights".
* **New Feature**: **Auto Midnight Reset & SD Persistence** - `Today` resets to 0 automatically across midnight upon power-on while `Total` continues accumulating, archived independently per model across power cycles.
* **New Feature**: **Manual Independent Reset Switch (`Reset FlyCount`)** - Assign a physical switch (e.g. SH) in settings to reset `Today` count to zero instantly (without affecting `Total`).
* **UI Customization**: **Pink Color Option for Theme & LED** - Added `Pink` color option to `Theme` and `LED Color` menus.

### v1.0.002
* **UI Customization**: **Added `TRN` (Fully Transparent) Theme** - Hides all background panels and borders, automatically adding black drop shadows to text for a clean, frameless visual aesthetic.
* **UI Customization**: **Added `Transp BG` (Transparent Background) Option** - Hides the main background to reveal radio wallpaper while preserving semi-transparent background on informational blocks.
* **UI Customization**: **Added Black Theme** - Added stealth Black style; updated default theme to `Blue`.
* **New Feature**: **Added `Rainbow` Flowing LED Marquee** - Added Rainbow effect to `LED Color` menu, displaying an animated rainbow flow on gimbal stick LED rings.
* **New Feature**: **Added Dynamic Battery Bar** - Added 3-color dynamic battery percentage bar to left panel (>30% Green, 15%~30% Orange, <15% Red).
* **UI Optimization**: **Universal Text Drop Shadows** - Added soft black shadows to all text (titles, values, and signature) in TRN mode for maximum contrast and legibility over any wallpaper.
* **UI Optimization**: **Full-Screen Layout Proportions Fine-Tuning** - Extended left panel to wrap battery info, equalized right panel vertical spacing to 15px, and widened GOV/STATUS blocks flush with the Battery Bar.
* **UI Optimization**: **TRN Battery Bar Border Optimization** - Preserves border frame even at 0% battery in TRN mode.
* **Bug Fix**: **Status Text Vertical Centering Fix** - Corrected `f_mid` font rendering low in status boxes (OFF / SAFE / NO DATA / UserName), fine-tuning Y-axis for perfect vertical centering.

### v1.0.001 Major Update & Bug Fixes
* **UI Customization**: **Pilot Callsign Digital Signature** - When telemetry signal is active, replaces the bottom-right "NO DATA" block with custom pilot callsign signature (clean white font without background box).
* **New Feature**: **Inverted Arm Icon Option** - Provides an option to invert arm icon display (display only, does not invert switch logic).
* **UI Optimization**: **Header Visual Cleanup & Version Watermark** - Removed redundant slash `/` between voltage and time in top-right header; added subtle version watermark (`v 1.0.001`) in bottom-left corner.
* **Bug Fix**: **Battery Info & NO DATA Overlap Fix** - Fixed display bug where battery info overlapped "NO DATA" text in bottom-left corner upon battery connection.
* **Logic Fix**: **High Current 200A+ 10x Scale Down Bug Fix (Critical)** - Fixed severe bug where current exceeding 200A was forcibly divided by 10, now accurately displaying high current for 700/800 class helicopters.
* **Logic Fix**: **`Arm Source` Physical Switch Read Fix** - Fixed issue where failing to read physical switch caused locked (SAFE) state.
* **Logic Fix**: **Power-On Battery S Count Lock** - Fixed issue where cell count jumped during high-pitch voltage sag in flight, accurately locking cell count upon battery connection.
* **Logic Fix**: **Single Cell Low Voltage Threshold Adjustment** - Lowered single-cell red warning threshold from overly high 3.8V to reasonable 3.5V to prevent visual distraction during normal flight.
* **Logic Fix**: **Logical Switch Arm Crash Fix** - Fixed script crash when using a Logical Switch to trigger arming.

### v1.0.000 (Initial Release)
* **Initial Release**: **RBCT Helicopter Dashboard Widget Official Launch** - Advanced full-color helicopter telemetry dashboard widget crafted for EdgeTX and Rotorflight, supporting 480×272, 480×320, and 800×480 multi-resolution adaptive cockpit interface.
* **Core Feature**: **Real-Time Telemetry HUD Monitoring** - Integrates monitoring of total battery voltage (Vbat), single-cell voltage (Cell), real-time current (A), consumed capacity (mAh), rotor headspeed (RPM), governor status (GOV), BEC supply voltage, and ESC temperature.
* **Core Feature**: **FBL Bank & Arming Indicator** - Dynamically displays active FBL PID Bank profile and ARMED / SAFE status icons.
* **UI Customization**: **Multiple Color Themes & Model Image** - Built-in 8 high-contrast color themes, with support for loading matching model images from SD card `/IMAGES/`.
