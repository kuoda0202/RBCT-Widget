# RBCT Helicopter Dashboard Widget

**Author / 作者**: 雷恩 / Ryan Kuo
### Standard UI (預設標準介面)
![Standard UI](Standard%20UI.jpg)

### Clean UI (透明背景模式)
![Clean UI](Clean%20UI.jpg)

### Transparent UI (TRN 全透無框模式)
![Transparent UI](Transparent%20UI.jpg)

(English below)

**RBCT** 是一個專為 EdgeTX 開發的直昇機儀表板小工具 (Widget)，支援多種螢幕解析度自動適應，完美適配 RadioMaster TX16S MK3 (800x480)、TX16S MKII (480x272) 以及 TX15 MAX (480x320) 等全彩觸控螢幕。提供完整、直覺的飛行數據監控介面。

## 🌟 核心功能

*   **跨機種解析度自適應**：自動偵測螢幕大小，無論是 800x480 或 480 寬度的螢幕，皆能自動調整字體與圖片比例，維持最佳顯示效果。

*   **即時遙測數據顯示**：監控並顯示包含電池總電壓 (Vbat)、電流 (A)、消耗容量 (mAh)、BEC 電壓、單節最低電壓 (Cell) 以及 ESC / MCU 溫度。
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
