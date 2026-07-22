# RBCT Helicopter Dashboard Widget

**Author / 作者**: 雷恩 / Ryan Kuo

### Standard UI (預設標準介面)
![Standard UI](Standard%20UI.jpg)

### Clean UI (透明背景模式)
![Clean UI](Clean%20UI.jpg)

### Transparent UI (TRN 全透無框模式)
![Transparent UI](Transparent%20UI.jpg)

### Logbook UI (飛行日誌與雙層曲線圖)
![Logbook UI](Logbook%20UI.jpg)



**RBCT** 是一個專為 EdgeTX 開發的直昇機儀表板小工具 (Widget)，支援多種螢幕解析度自動適應，完美適配 RadioMaster TX16S MK3 (800x480)、TX16S MKII (480x272) 以及 TX15 MAX (480x320) 等全彩觸控螢幕。提供完整、直覺的飛行數據監控介面。

## 🌟 核心功能

*   **跨機種解析度自適應**：自動偵測螢幕大小，無論是 800x480 或 480 寬度的螢幕，皆能自動調整字體與圖片比例，維持最佳顯示效果。
*   **黑盒子與五線譜飛行圖表 (Logbook & Chart Analyzer)**：透過實體開關 (Logbook Sw) 一鍵叫出，提供：
    *   **歷史數據表格**：自動記錄近期航班的極值摘要（MAX RPM, MAX A, MIN V, MIN BEC, MAX TMP, mAh）。
    *   **零負載極速繪圖引擎**：完全由記憶體運作的 5 線譜折線圖（綠線 RPM、橘線 電壓、紅線 電流、藍線 BEC、黃線 溫度），精準分析劇烈動作時的電壓陡降與掉轉現象。在解鎖狀態下甚至能呈現「即時調機」效果！
*   **自動飛行次數計數器 (Flight Counter)**：獨立追蹤每台機型的「今日飛行次數 (Today)」與「歷史總飛行次數 (Total)」，皆以純文字檔儲存於 SD 卡，支援手動編輯。
*   **即時遙測數據顯示**：監控並顯示包含電池總電壓 (Vbat)、電流 (A)、消耗容量 (mAh)、BEC 電壓、單節最低電壓 (Cell) 以及 ESC / MCU 溫度。
*   **旋翼轉速監控 (Headspeed)**：即時顯示目前轉速 (RPM)，並記錄飛行過程中的最高 (max) 與最低 (min) 轉速。
*   **定速狀態指示 (Governor)**：提供醒目直覺的定速開啟/關閉 (ON/OFF) 狀態圖示。
*   **FBL 停懸段數 (Banks)**：根據您設定的遙控器開關或通道，動態顯示當前使用的 FBL 停懸段數 (Bank)。
*   **自訂儀表板主題色**：內建 9 種高對比主題色彩 (紅、橘、黃、綠、藍、靛、紫、黑、TRN 全透明、粉紅)，可依個人喜好自由切換。
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
*   **Bank Source (段數來源)**：選擇用來控制 FBL Bank 切換的通道 (Channel) 或開關。
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

### v1.0.003
*   **功能新增 (重大升級)**：「雙重真實計數器」！現在畫面上會同時顯示 `Today` (今日次數) 與 `Total` (終身總次數)。
*   **功能新增 (終極日誌)**：加入**「飛行日誌報表 (Flight Logbook)」**！降落後只需三段開關切換，畫面會立刻翻轉為該台直昇機最近 10 趟的飛行報表。表格內詳細記載每趟的：`起飛時間`、`飛行時長`、`最高轉速`、`最大電流`、`最低電壓`、`消耗容量`、`最高溫度` 與 `最低 BEC`。
*   **版面重構 (雙層專業圖表)**：日誌下方新增即時「五線譜分析圖表」。並將圖表物理分割為上下兩層 (上層：轉速/電壓/電流，下層：溫度/BEC)，讓飛手能精準比對「大螺距電流突波」與「BEC掉壓」的毫秒級關聯！
*   **核心優化 (安全極限防爆)**：圖表引擎導入「動態降採樣 (Dynamic Downsampling)」與「FIFO 環狀緩衝區」航太級安全技術。
  *   *記憶體防爆*：不管滯空時間多長，陣列永遠只保留最新 200 筆資料 (約最後 10 分鐘的精華)，保證記憶體不溢位。
  *   *處理器防爆*：繪圖引擎自動等比例抽出 50 個關鍵點繪製趨勢。保證 CPU常數級極低負載，徹底消滅 `CPU LIMIT` 崩潰風險，連續解鎖 48 小時也絕對安全！
*   **邏輯升級 (智慧防呆計數器)**：大幅強化防呆過濾機制。現在解鎖超過 60 秒後，還必須偵測到 `轉速 > 1000 RPM` 或 `電流 > 5A` 才會判定為真實飛行並計數 +1。在桌上拔馬達除錯一整天也絕對不會誤判產生「幽靈航班」！
*   **功能新增**：結合 SD 卡記憶功能 (依模型獨立存放)，關機不遺失。並具備「跨日自動歸零」的貼心設計，每天開機 `Today` 會自動從 0 開始，而 `Total` 會持續累積。
*   **功能新增**：在設定選單中新增 `Reset FlyCount` (歸零來源) 選項。可指派遙控器實體開關 (如 SH 彈回開關)，撥動瞬間即可手動將 `Today` 歸零 (不會影響終身總次數)。
*   **介面自訂**：在 `Theme` 及 `LED Color` 選項中新增了 `Pink` (粉紅) 新色彩，提供更豐富的主題搭配。

### v1.0.002
*   **介面自訂**：在 `Theme` 中新增了 `TRN` (全透明) 主題，選擇此主題將會隱藏所有背景底色與邊框線條，並自動為文字加上黑色陰影，提供最乾淨的無框架視覺效果且保持極高辨識度。
*   **介面自訂**：新增 `Transp BG` (透明背景) 開關，開啟後可隱藏主背景底色以露出遙控器桌布，但貼心地保留了各資訊面板的半透明底色，維持閱讀清晰度。
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

## ⚠️ 免責聲明 (Disclaimer)

本小工具 (RBCT Widget) 係以「現狀 (AS IS)」原則免費提供，不提供任何形式之明示或默示擔保。

1. **飛行安全**：遙控直昇機具備高轉速與高能量之物理危險性。飛手 (Pilot in Command) 須對每一次飛行之操作、設定及安全負完全責任。
2. **數據僅供參考**：儀表板顯示之遙測數據、極值紀錄與歷史圖表僅供飛行調機及狀態參考，不應作為判斷飛行安全之唯一依據。
3. **損害免責**：作者 (Author) 對於因安裝、使用或無法使用本小工具所導致之任何遙控設備故障、機體墜毀、財產損失或人員傷害，概不負任何法律與賠償責任。

使用本小工具即代表您已閱讀、理解並同意上述所有條款。
---

## 🇬🇧 English Description

**RBCT** is a comprehensive and visually rich helicopter dashboard widget designed specifically for EdgeTX. Featuring dynamic resolution scaling, it perfectly supports RadioMaster TX16S MK3 (800x480), TX16S MKII (480x272), and TX15 MAX (480x320) color touchscreens to deliver an intuitive and complete flight telemetry monitoring interface.

### Features

*   **Dynamic Resolution Scaling**: Automatically adapts layout, font sizes, and image scaling for different screens (800x480 or 480-width displays), maintaining optimal visual clarity across multiple radio models.
*   **Black Box & Chart Analyzer (Logbook & Chart Analyzer)**: Triggered instantly via a physical 3-position switch (`Logbook Sw`), offering:
    *   **Historical Data Table**: Automatically logs flight summaries of extreme values (MAX RPM, MAX A, MIN V, MIN BEC, MAX TMP, mAh).
    *   **Zero-Overhead Memory Chart Engine**: Pure in-memory 5-line chart (Green: RPM, Orange: Voltage, Red: Current, Blue: BEC, Yellow: Temperature) to precisely analyze voltage sags and headspeed drops during aggressive 3D maneuvers. Displays live real-time tuning data while ARMED!
*   **Automatic Flight Counter**: Independently tracks daily flights (`Today`) and lifetime total flights (`Total`) per model, stored in plain text files on the SD card with manual edit support.
*   **Real-Time Telemetry Display**: Monitors and displays critical flight data including Battery Voltage (Vbat), Current (A), Capacity Consumed (mAh), BEC Voltage, Lowest Cell Voltage (Cell), and ESC / MCU Temperature.
*   **Headspeed Tracking**: Displays current Headspeed (RPM) along with maximum (max) and minimum (min) RPM statistics recorded during flight.
*   **Governor Status**: Clear visual indicator for Governor ON/OFF state.
*   **FBL Bank Switching**: Dynamically displays the active FBL (Flybarless) Bank number based on your switch or channel configuration.
*   **Customizable Color Themes**: Includes 9 high-contrast color themes (Red, Orange, Yellow, Green, Blue, Indigo, Violet, Black, TRN Transparent, Pink) for personalized aesthetics.
*   **Transparent Background Support**:
    *   Toggle `Transp BG`: Hides the main background color while retaining semi-transparent panel frames for readability.
    *   Select `TRN` theme: Full transparent background with no borders/frames, letting your custom radio wallpaper take center stage!
*   **Physical Gimbal LED Ring Control**: Directly synchronizes and controls physical RGB gimbal ring lighting on supported radios (such as TX16S MK3) with 9 selectable colors, Rainbow mode, or OFF.
*   **Dynamic Model Images**: Automatically loads model pictures from `/IMAGES` or `/WIDGETS/RBCT/modelImage/`. Falls back to a default helicopter image if no matching image is found.
*   **Flight Timer Integration**: Displays your selected radio flight timer prominently on the dashboard.

### Installation

1. Download and copy the entire `RBCT` folder into the `WIDGETS` directory on your radio's SD card (path: `/WIDGETS/RBCT`).
2. On your radio, navigate to the Telemetry setup screen.
3. Add a full-screen layout block and select the `RBCT` widget.

### Widget Options

Customize the following settings in the widget menu:
*   **Timer**: Select which flight timer (Timer 1~3) to display on screen.
*   **Bank Source**: Select the channel or switch controlling FBL Bank switching.
*   **Arm Source**: Select the switch or channel assigned to your ARM function for synchronized status display.
*   **Arm Invert**: Reverse the ARM / SAFE logic to match your switch habits.
*   **Logbook Sw**: Assign a physical switch (e.g. 3-position switch) to toggle the Logbook report and chart analyzer on demand.
*   **Reset FlyCount**: Assign a physical switch (e.g. SH momentary switch) to manually reset `Today` flights to 0 without affecting `Total` flights.
*   **Theme**: Choose your preferred panel color theme (including Black, TRN Transparent, and Pink).
*   **Transp BG**: Enable to make the main background transparent to reveal your wallpaper, while preserving semi-transparent panel borders for contrast.
*   **LED Color**: Select physical gimbal RGB ring lighting colors (9 options, Pink, Peach, Rainbow, or OFF).
*   **UserName**: Custom pilot signature to replace the "NO DATA" block in the bottom right corner when telemetry is active.

### Model Image Setup

To customize the helicopter picture on your dashboard:
*   Prepare a transparent `.png` image.
*   Place the file in `/WIDGETS/RBCT/modelImage/` named exactly matching your EdgeTX model name.
*   Alternatively, assign a bitmap in native EdgeTX Model Setup, which RBCT will automatically detect and display.

### Changelog (v1.0.003)

*   **New Feature (Major Upgrade)**: **Dual Dynamic Flight Counter**! Displays `Today` (daily flights) and `Total` (lifetime flights) side-by-side on the main screen.
*   **New Feature (Ultimate Logbook)**: Added **Flight Logbook Report**! After landing, toggle the assigned 3-position switch to instantly flip the screen into a 10-flight report table for the current model. Logs per-flight: `Start Time`, `Flight Duration`, `Max RPM`, `Max Current`, `Min Voltage`, `mAh Consumed`, `Max Temp`, and `Min BEC`.
*   **Layout Redesign (Dual-Layer Chart Analyzer)**: Added a 5-line real-time chart below the log table, split physically into two layers (Top: RPM / Voltage / Amps; Bottom: Temp / BEC) allowing pilots to analyze millisecond-level correlation between heavy pitch pitch-pumps and BEC voltage sags!
*   **Core Optimization (Aerospace Safety Protection)**: Engineered chart engine with Dynamic Downsampling and FIFO Ring Buffer technology:
    *   *Memory Overflow Protection*: Maintains a strict max 200 data points buffer regardless of flight duration (preserving ~10 min of peak flight data).
    *   *CPU Load Protection*: Automatically downsamples to 50 key trend points for rendering. Guarantees constant, minimal CPU load to eliminate `CPU LIMIT` crash risks even during continuous 48-hour ARMED sessions!
*   **Logic Upgrade (Smart Anti-Ghost Debounce)**: Enhanced debounce verification. Flight count +1 is only awarded after being ARMED for over 60 seconds AND detecting `RPM > 1000 RPM` or `Current > 5A`. Prevents "ghost flights" while debugging on the bench with motors disconnected all day!
*   **New Feature**: SD card persistence (stored independently per model) across power cycles. Features automatic daily reset (`Today` resets to 0 at midnight while `Total` continues accumulating).
*   **New Feature**: Added `Reset FlyCount` option in widget settings. Assign a momentary switch (e.g. SH) to manually zero `Today` flight count instantly.
*   **Customization**: Added `Pink` option to `Theme` and `LED Color` settings for expanded aesthetic customization.

### Changelog (v1.0.002)

*   **Customization**: Added `TRN` (Fully Transparent) theme, hiding all background panels and borders while adding drop shadows to text for maximum readability on custom wallpapers.
*   **Customization**: Added `Transp BG` (Transparent Background) toggle to hide main background color while retaining semi-transparent panel borders for clear readability.
*   **Customization**: Added `Black` theme for a subtle, low-key look, and set default theme to `Blue`.
*   **New Feature**: Added `Rainbow` option in `LED Color` settings to display a dynamic flowing rainbow lighting effect on physical gimbal RGB rings.
*   **New Feature**: Added dynamic Battery Bar on the left panel driven by `Bat%` telemetry (Green > 30%, Orange 15%~30%, Red < 15%).
*   **UI Optimization**: Universal drop-shadows applied to all dashboard text (titles, values, UserName) in transparent mode (`Transp BG`) for legibility across any wallpaper.
*   **UI Optimization**: Full-screen layout recalibration: extended left panel to cover battery info, standardized right panel gaps to 15px, and aligned GOV/STATUS blocks flush with the Battery Bar.
*   **UI Optimization**: Improved battery bar rendering in TRN mode with dedicated black outline even at 0%.
*   **Layout Fix**: Adjusted vertical alignment for `f_mid` font in status blocks (OFF / SAFE / NO DATA / UserName) for perfect vertical centering.

### Changelog (v1.0.001 Major Update & Bug Fixes)

*   **Customization**: Added `UserName` option to replace "NO DATA" with a clean white pilot signature when telemetry is active.
*   **New Feature**: Added `Arm Invert` option in settings to reverse ARM / SAFE logic to fit personal switch preferences.
*   **UI Optimization**: Removed redundant `/` symbol between Tx voltage and clock; added subtle version watermark (`v 1.0.001`) in bottom left.
*   **Layout Fix**: Fixed text overlap between battery info and "NO DATA" block in bottom left corner upon battery connection.
*   **Logic Fix (Critical)**: Removed incorrect >200A current scaling cap that reduced heavy currents by 10x, enabling accurate display for 700/800 class helicopters!
*   **Logic Fix**: Fixed `Arm Source` setting switch reading bug that caused ARMED status to get stuck in SAFE mode.
*   **Logic Fix**: Cell count (S) is now locked upon battery connection to prevent erratic S-count jumps caused by voltage sags during pitch-pumps.
*   **Logic Fix**: Lowered single-cell voltage warning threshold from 3.8V to a realistic 3.5V to avoid false red alarms during flight.
*   **Logic Fix**: Fixed script crash when using Logical Switches as the Arm Source.
*   **Logic Fix**: Fixed issue where Min/Max telemetry values (voltage/RPM) failed to reset when swapping batteries and remained stuck at 0.
  
### ⚠️ Disclaimer

This widget (RBCT) is provided "AS IS" without warranty of any kind, express or implied.

1. **Flight Safety**: Operating remote-controlled helicopters involves inherent physical risks. The pilot in command assumes full responsibility for flight safety, equipment setup, and operation.
2. **Data for Reference Only**: All real-time telemetry values, extreme statistics, and logbook charts displayed by this widget are provided strictly for reference and tuning purposes. They should not be relied upon as the sole basis for flight safety.
3. **Limitation of Liability**: In no event shall the author be held liable for any direct, indirect, incidental, or consequential damages, equipment loss, crashes, or personal injuries resulting from the use or misuse of this widget.

By using this widget, you acknowledge that you have read, understood, and agreed to these terms.
