local _, PDS = ...

-- Initialize Localization namespace
PDS.L = {}
local L = PDS.L

-- Get the client's locale
local locale = GetLocale()

-- Default locale (English)
local defaultLocale = "enUS"

-- Localization tables
local Locales = {}

-- English (Default)
Locales["enUS"] = {
    -- Stat Names
    ["STAT_STRENGTH"] = "Strength",
    ["STAT_AGILITY"] = "Agility",
    ["STAT_INTELLECT"] = "Intellect",
    ["STAT_STAMINA"] = "Stamina",
    ["STAT_HASTE"] = "Haste",
    ["STAT_CRIT"] = "Critical Strike",
    ["STAT_MASTERY"] = "Mastery",
    ["STAT_VERSATILITY"] = "Versatility",
    ["STAT_VERSATILITY_DAMAGE"] = "Versatility (Damage)",
    ["STAT_VERSATILITY_DEFENSE"] = "Versatility (Defense)",
    ["STAT_SPEED"] = "Speed",
    ["STAT_LEECH"] = "Leech",
    ["STAT_AVOIDANCE"] = "Avoidance",
    ["STAT_DEFENSE"] = "Defense",
    ["STAT_DODGE"] = "Dodge",
    ["STAT_PARRY"] = "Parry",
    ["STAT_BLOCK"] = "Block",
    ["STAT_ARMOR_PENETRATION"] = "Armor Penetration",
    
    -- Commands
    ["CMD_TOGGLE"] = "Toggle stats display",
    ["CMD_CONFIG"] = "Open configuration panel",
    ["CMD_HELP"] = "Show available commands",
    
    -- Config UI - Section Headers
    ["CONFIG_DISPLAY_SETTINGS"] = "Display Settings",
    ["CONFIG_STAT_OPTIONS"] = "Stat Options",
    ["CONFIG_BAR_APPEARANCE"] = "Bar Appearance",
    ["CONFIG_SPEC_SETTINGS"] = "Specialization Settings",
    ["CONFIG_TEXT_SETTINGS"] = "Text Settings",
    
    -- Config UI - Display Settings
    ["CONFIG_FRAME_DIMENSIONS"] = "Frame Dimensions:",
    ["CONFIG_FRAME_WIDTH"] = "Frame Width",
    ["CONFIG_BG_OPACITY"] = "Background Opacity",
    ["CONFIG_VISIBILITY_OPTIONS"] = "Visibility Options:",
    ["CONFIG_SHOW_TITLE_BAR"] = "Show Title Bar",
    ["CONFIG_LOCK_POSITION"] = "Lock Frame Position",
    ["CONFIG_HIDE_OUT_OF_COMBAT"] = "Hide When Out of Combat",
    ["CONFIG_DISPLAY_MODE"] = "Display Mode",
    ["CONFIG_DISPLAY_MODE_ALWAYS"] = "Always Show",
    ["CONFIG_DISPLAY_MODE_PARTY"] = "Show in Party Only",
    ["CONFIG_DISPLAY_MODE_RAID"] = "Show in Raid Only",
    
    -- Config UI - Stat Options
    ["CONFIG_PRIMARY_STATS"] = "Primary Stats",
    ["CONFIG_PRIMARY_STATS_DESC"] = "Primary stats are calculated as percentages, starting at 100% (base value). Buffs, talents, and equipment can increase these values beyond 100%. Higher percentages represent better performance.",
    ["CONFIG_SECONDARY_STATS"] = "Secondary Stats",
    ["CONFIG_SECONDARY_STATS_DESC"] = "Secondary stats enhance your character's performance: Crit, Haste, Mastery, Versatility, etc.",
    ["CONFIG_SHOW_STAT"] = "Show %s",
    ["CONFIG_BAR_COLOR"] = "Bar Color:",
    
    -- Config UI - Bar Appearance
    ["CONFIG_BAR_DIMENSIONS"] = "Bar Dimensions:",
    ["CONFIG_BAR_HEIGHT"] = "Bar Height",
    ["CONFIG_BAR_SPACING"] = "Bar Spacing",
    ["CONFIG_BAR_BG_OPACITY"] = "Bar Background Opacity",
    ["CONFIG_BAR_OPACITY"] = "Bar Fill Opacity",
    ["CONFIG_BAR_STYLE"] = "Bar Style:",
    ["CONFIG_BAR_TEXTURE"] = "Bar Texture",
    ["CONFIG_ADDITIONAL_BAR_OPTIONS"] = "Additional Bar Options:",
    ["CONFIG_SHOW_STAT_CHANGES"] = "Show Stat Value Changes",
    ["CONFIG_SHOW_RATINGS"] = "Show Rating Values",
    ["CONFIG_SHOW_OVERFLOW_BARS"] = "Show Overflow Bars",
    ["CONFIG_ENABLE_TALENT_ADJUSTMENTS"] = "Enable Talent Adjustments (Rogue: Thief's Versatility)",
    
    -- Config UI - Spec Settings
    ["CONFIG_SPEC_DESC"] = "Control whether your addon settings should be shared between all specializations or customized per spec.",
    ["CONFIG_USE_SHARED_SPEC"] = "Use same settings for all specializations",
    ["CONFIG_SPEC_INFO"] = "When enabled, your stat visibility, bar appearance, and other settings will be the same for all specs. When disabled, each spec can have unique settings.",
    ["CONFIG_SPEC_SHARED_MSG"] = "Settings will now be shared across all specializations",
    ["CONFIG_SPEC_SEPARATE_MSG"] = "Each specialization will now use its own settings",
    
    -- Config UI - Text Settings
    ["CONFIG_FONT_SELECTION"] = "Font Selection:",
    ["CONFIG_FONT"] = "Font",
    ["CONFIG_FONT_SIZE"] = "Font Size",
    ["CONFIG_FONT_STYLE"] = "Font Style:",
    ["CONFIG_FONT_OUTLINE"] = "Outlined Font",
    ["CONFIG_FONT_SHADOW"] = "Font Shadow",
    
    -- Messages
    ["MSG_ADDON_LOADED"] = "PeaversDynamicStats loaded. Type /pds for commands.",
    ["MSG_SHOWN"] = "PeaversDynamicStats shown.",
    ["MSG_HIDDEN"] = "PeaversDynamicStats hidden.",
    
    -- Config UI - Template Settings
    ["CONFIG_TEMPLATE_SETTINGS"] = "Template Management",
    ["CONFIG_TEMPLATE_DESC"] = "Save your current settings as named templates (e.g., 'DPS Setup', 'Tank Setup') that can be applied to any character or spec. Templates are shared across all characters.",
    ["CONFIG_CREATE_TEMPLATE"] = "Create New Template:",
    ["CONFIG_CREATE_TEMPLATE_BTN"] = "Save Current Settings as Template",
    ["CONFIG_MANAGE_TEMPLATES"] = "Available Templates:",
    ["CONFIG_NO_TEMPLATES"] = "No templates created yet. Create one from your current settings!",

    -- Template Operations
    ["TEMPLATE_CREATE_PROMPT"] = "Enter a name for the new template:",
    ["TEMPLATE_APPLY_CONFIRM"] = "Apply template '%s' to your current settings? This will overwrite your current configuration.",
    ["TEMPLATE_DELETE_CONFIRM"] = "Delete template '%s'? This cannot be undone.",
    ["TEMPLATE_RENAME_PROMPT"] = "Enter a new name for template '%s':",

    -- Template Messages
    ["TEMPLATE_CREATED"] = "Template '%s' created successfully!",
    ["TEMPLATE_APPLIED"] = "Template '%s' applied successfully!",
    ["TEMPLATE_DELETED"] = "Template '%s' deleted.",
    ["TEMPLATE_RENAMED"] = "Template renamed from '%s' to '%s'.",

    -- Template Errors
    ["TEMPLATE_ERROR_EMPTY_NAME"] = "Template name cannot be empty.",
    ["TEMPLATE_ERROR_DUPLICATE"] = "A template with this name already exists.",
    ["TEMPLATE_ERROR_NOT_FOUND"] = "Template not found.",
    ["TEMPLATE_ERROR_NO_PROFILE"] = "No active profile to create template from.",
    ["TEMPLATE_ERROR_INVALID_DATA"] = "Invalid profile data.",
    ["TEMPLATE_ERROR_CORRUPTED"] = "Template data is corrupted.",

    -- Common Buttons
    ["CREATE"] = "Create",
    ["APPLY"] = "Apply",
    ["DELETE"] = "Delete",
    ["RENAME"] = "Rename",
    ["CANCEL"] = "Cancel",

    -- Misc
    ["NEW_BADGE"] = "NEW!",
}

-- Simplified Chinese (简体中文)
Locales["zhCN"] = {
    -- Stat Names
    ["STAT_STRENGTH"] = "力量",
    ["STAT_AGILITY"] = "敏捷",
    ["STAT_INTELLECT"] = "智力",
    ["STAT_STAMINA"] = "耐力",
    ["STAT_HASTE"] = "急速",
    ["STAT_CRIT"] = "暴击",
    ["STAT_MASTERY"] = "精通",
    ["STAT_VERSATILITY"] = "全能",
    ["STAT_VERSATILITY_DAMAGE"] = "全能（伤害）",
    ["STAT_VERSATILITY_DEFENSE"] = "全能（防御）",
    ["STAT_SPEED"] = "速度",
    ["STAT_LEECH"] = "吸血",
    ["STAT_AVOIDANCE"] = "闪避",
    ["STAT_DEFENSE"] = "防御",
    ["STAT_DODGE"] = "躲闪",
    ["STAT_PARRY"] = "招架",
    ["STAT_BLOCK"] = "格挡",
    ["STAT_ARMOR_PENETRATION"] = "护甲穿透",
    
    -- Commands
    ["CMD_TOGGLE"] = "切换属性显示",
    ["CMD_CONFIG"] = "打开配置面板",
    ["CMD_HELP"] = "显示可用命令",
    
    -- Config UI - Section Headers
    ["CONFIG_DISPLAY_SETTINGS"] = "显示设置",
    ["CONFIG_STAT_OPTIONS"] = "属性选项",
    ["CONFIG_BAR_APPEARANCE"] = "进度条外观",
    ["CONFIG_SPEC_SETTINGS"] = "专精设置",
    ["CONFIG_TEXT_SETTINGS"] = "文字设置",
    
    -- Config UI - Display Settings
    ["CONFIG_FRAME_DIMENSIONS"] = "框架尺寸：",
    ["CONFIG_FRAME_WIDTH"] = "框架宽度",
    ["CONFIG_BG_OPACITY"] = "背景透明度",
    ["CONFIG_VISIBILITY_OPTIONS"] = "可见性选项：",
    ["CONFIG_SHOW_TITLE_BAR"] = "显示标题栏",
    ["CONFIG_LOCK_POSITION"] = "锁定框架位置",
    ["CONFIG_HIDE_OUT_OF_COMBAT"] = "脱离战斗时隐藏",
    ["CONFIG_DISPLAY_MODE"] = "显示模式",
    ["CONFIG_DISPLAY_MODE_ALWAYS"] = "始终显示",
    ["CONFIG_DISPLAY_MODE_PARTY"] = "仅在小队中显示",
    ["CONFIG_DISPLAY_MODE_RAID"] = "仅在团队中显示",
    
    -- Config UI - Stat Options
    ["CONFIG_PRIMARY_STATS"] = "主要属性",
    ["CONFIG_PRIMARY_STATS_DESC"] = "主要属性以百分比计算，从100%（基础值）开始。增益、天赋和装备可以将这些值提高到100%以上。百分比越高代表性能越好。",
    ["CONFIG_SECONDARY_STATS"] = "次要属性",
    ["CONFIG_SECONDARY_STATS_DESC"] = "次要属性增强你的角色性能：暴击、急速、精通、全能等。",
    ["CONFIG_SHOW_STAT"] = "显示%s",
    ["CONFIG_BAR_COLOR"] = "进度条颜色：",
    
    -- Config UI - Bar Appearance
    ["CONFIG_BAR_DIMENSIONS"] = "进度条尺寸：",
    ["CONFIG_BAR_HEIGHT"] = "进度条高度",
    ["CONFIG_BAR_SPACING"] = "进度条间距",
    ["CONFIG_BAR_BG_OPACITY"] = "进度条背景透明度",
    ["CONFIG_BAR_OPACITY"] = "进度条填充透明度",
    ["CONFIG_BAR_STYLE"] = "进度条样式：",
    ["CONFIG_BAR_TEXTURE"] = "进度条材质",
    ["CONFIG_ADDITIONAL_BAR_OPTIONS"] = "其他进度条选项：",
    ["CONFIG_SHOW_STAT_CHANGES"] = "显示属性值变化",
    ["CONFIG_SHOW_RATINGS"] = "显示等级值",
    ["CONFIG_SHOW_OVERFLOW_BARS"] = "显示溢出条",
    ["CONFIG_ENABLE_TALENT_ADJUSTMENTS"] = "启用天赋调整（盗贼：盗贼的全能）",
    
    -- Config UI - Spec Settings
    ["CONFIG_SPEC_DESC"] = "控制插件设置是在所有专精之间共享还是为每个专精单独定制。",
    ["CONFIG_USE_SHARED_SPEC"] = "所有专精使用相同设置",
    ["CONFIG_SPEC_INFO"] = "启用时，你的属性可见性、进度条外观和其他设置将在所有专精中保持一致。禁用时，每个专精可以有独特的设置。",
    ["CONFIG_SPEC_SHARED_MSG"] = "设置现在将在所有专精之间共享",
    ["CONFIG_SPEC_SEPARATE_MSG"] = "每个专精现在将使用自己的设置",
    
    -- Config UI - Text Settings
    ["CONFIG_FONT_SELECTION"] = "字体选择：",
    ["CONFIG_FONT"] = "字体",
    ["CONFIG_FONT_SIZE"] = "字体大小",
    ["CONFIG_FONT_STYLE"] = "字体样式：",
    ["CONFIG_FONT_OUTLINE"] = "字体描边",
    ["CONFIG_FONT_SHADOW"] = "字体阴影",
    
    -- Messages
    ["MSG_ADDON_LOADED"] = "PeaversDynamicStats 已加载。输入 /pds 查看命令。",
    ["MSG_SHOWN"] = "PeaversDynamicStats 已显示。",
    ["MSG_HIDDEN"] = "PeaversDynamicStats 已隐藏。",
    
    -- Config UI - Template Settings
    ["CONFIG_TEMPLATE_SETTINGS"] = "模板管理",
    ["CONFIG_TEMPLATE_DESC"] = "将当前设置保存为命名模板（例如"输出配置"、"坦克配置"），可应用于任何角色或专精。模板在所有角色间共享。",
    ["CONFIG_CREATE_TEMPLATE"] = "创建新模板：",
    ["CONFIG_CREATE_TEMPLATE_BTN"] = "将当前设置保存为模板",
    ["CONFIG_MANAGE_TEMPLATES"] = "可用模板：",
    ["CONFIG_NO_TEMPLATES"] = "尚未创建模板。从当前设置创建一个吧！",

    -- Template Operations
    ["TEMPLATE_CREATE_PROMPT"] = "请输入新模板的名称：",
    ["TEMPLATE_APPLY_CONFIRM"] = "将模板'%s'应用到当前设置？这将覆盖你的当前配置。",
    ["TEMPLATE_DELETE_CONFIRM"] = "删除模板'%s'？此操作无法撤销。",
    ["TEMPLATE_RENAME_PROMPT"] = "请输入模板'%s'的新名称：",

    -- Template Messages
    ["TEMPLATE_CREATED"] = "模板'%s'创建成功！",
    ["TEMPLATE_APPLIED"] = "模板'%s'应用成功！",
    ["TEMPLATE_DELETED"] = "模板'%s'已删除。",
    ["TEMPLATE_RENAMED"] = "模板已从'%s'重命名为'%s'。",

    -- Template Errors
    ["TEMPLATE_ERROR_EMPTY_NAME"] = "模板名称不能为空。",
    ["TEMPLATE_ERROR_DUPLICATE"] = "已存在同名模板。",
    ["TEMPLATE_ERROR_NOT_FOUND"] = "未找到模板。",
    ["TEMPLATE_ERROR_NO_PROFILE"] = "没有可用的配置文件来创建模板。",
    ["TEMPLATE_ERROR_INVALID_DATA"] = "配置文件数据无效。",
    ["TEMPLATE_ERROR_CORRUPTED"] = "模板数据已损坏。",

    -- Common Buttons
    ["CREATE"] = "创建",
    ["APPLY"] = "应用",
    ["DELETE"] = "删除",
    ["RENAME"] = "重命名",
    ["CANCEL"] = "取消",

    -- Misc
    ["NEW_BADGE"] = "新功能！",
}

-- Traditional Chinese (繁體中文)
Locales["zhTW"] = {
    -- Stat Names
    ["STAT_STRENGTH"] = "力量",
    ["STAT_AGILITY"] = "敏捷",
    ["STAT_INTELLECT"] = "智力",
    ["STAT_STAMINA"] = "耐力",
    ["STAT_HASTE"] = "加速",
    ["STAT_CRIT"] = "致命一擊",
    ["STAT_MASTERY"] = "精通",
    ["STAT_VERSATILITY"] = "臨機應變",
    ["STAT_VERSATILITY_DAMAGE"] = "臨機應變（傷害）",
    ["STAT_VERSATILITY_DEFENSE"] = "臨機應變（防禦）",
    ["STAT_SPEED"] = "速度",
    ["STAT_LEECH"] = "汲取",
    ["STAT_AVOIDANCE"] = "迴避",
    ["STAT_DEFENSE"] = "防禦",
    ["STAT_DODGE"] = "閃躲",
    ["STAT_PARRY"] = "招架",
    ["STAT_BLOCK"] = "格擋",
    ["STAT_ARMOR_PENETRATION"] = "護甲穿透",
    
    -- Commands
    ["CMD_TOGGLE"] = "切換屬性顯示",
    ["CMD_CONFIG"] = "開啟設定面板",
    ["CMD_HELP"] = "顯示可用指令",
    
    -- Config UI - Section Headers
    ["CONFIG_DISPLAY_SETTINGS"] = "顯示設定",
    ["CONFIG_STAT_OPTIONS"] = "屬性選項",
    ["CONFIG_BAR_APPEARANCE"] = "進度條外觀",
    ["CONFIG_SPEC_SETTINGS"] = "專精設定",
    ["CONFIG_TEXT_SETTINGS"] = "文字設定",
    
    -- Config UI - Display Settings
    ["CONFIG_FRAME_DIMENSIONS"] = "框架尺寸：",
    ["CONFIG_FRAME_WIDTH"] = "框架寬度",
    ["CONFIG_BG_OPACITY"] = "背景透明度",
    ["CONFIG_VISIBILITY_OPTIONS"] = "可見性選項：",
    ["CONFIG_SHOW_TITLE_BAR"] = "顯示標題列",
    ["CONFIG_LOCK_POSITION"] = "鎖定框架位置",
    ["CONFIG_HIDE_OUT_OF_COMBAT"] = "脫離戰鬥時隱藏",
    ["CONFIG_DISPLAY_MODE"] = "顯示模式",
    ["CONFIG_DISPLAY_MODE_ALWAYS"] = "總是顯示",
    ["CONFIG_DISPLAY_MODE_PARTY"] = "僅在隊伍中顯示",
    ["CONFIG_DISPLAY_MODE_RAID"] = "僅在團隊中顯示",
    
    -- Config UI - Stat Options
    ["CONFIG_PRIMARY_STATS"] = "主要屬性",
    ["CONFIG_PRIMARY_STATS_DESC"] = "主要屬性以百分比計算，從100%（基礎值）開始。增益、天賦和裝備可以將這些值提高到100%以上。百分比越高代表性能越好。",
    ["CONFIG_SECONDARY_STATS"] = "次要屬性",
    ["CONFIG_SECONDARY_STATS_DESC"] = "次要屬性增強你的角色性能：致命一擊、加速、精通、臨機應變等。",
    ["CONFIG_SHOW_STAT"] = "顯示%s",
    ["CONFIG_BAR_COLOR"] = "進度條顏色：",
    
    -- Config UI - Bar Appearance
    ["CONFIG_BAR_DIMENSIONS"] = "進度條尺寸：",
    ["CONFIG_BAR_HEIGHT"] = "進度條高度",
    ["CONFIG_BAR_SPACING"] = "進度條間距",
    ["CONFIG_BAR_BG_OPACITY"] = "進度條背景透明度",
    ["CONFIG_BAR_OPACITY"] = "進度條填充透明度",
    ["CONFIG_BAR_STYLE"] = "進度條樣式：",
    ["CONFIG_BAR_TEXTURE"] = "進度條材質",
    ["CONFIG_ADDITIONAL_BAR_OPTIONS"] = "其他進度條選項：",
    ["CONFIG_SHOW_STAT_CHANGES"] = "顯示屬性值變化",
    ["CONFIG_SHOW_RATINGS"] = "顯示等級值",
    ["CONFIG_SHOW_OVERFLOW_BARS"] = "顯示溢出條",
    ["CONFIG_ENABLE_TALENT_ADJUSTMENTS"] = "啟用天賦調整（盜賊：盜賊的臨機應變）",
    
    -- Config UI - Spec Settings
    ["CONFIG_SPEC_DESC"] = "控制插件設定是在所有專精之間共享還是為每個專精單獨定製。",
    ["CONFIG_USE_SHARED_SPEC"] = "所有專精使用相同設定",
    ["CONFIG_SPEC_INFO"] = "啟用時，你的屬性可見性、進度條外觀和其他設定將在所有專精中保持一致。停用時，每個專精可以有獨特的設定。",
    ["CONFIG_SPEC_SHARED_MSG"] = "設定現在將在所有專精之間共享",
    ["CONFIG_SPEC_SEPARATE_MSG"] = "每個專精現在將使用自己的設定",
    
    -- Config UI - Text Settings
    ["CONFIG_FONT_SELECTION"] = "字型選擇：",
    ["CONFIG_FONT"] = "字型",
    ["CONFIG_FONT_SIZE"] = "字型大小",
    ["CONFIG_FONT_STYLE"] = "字型樣式：",
    ["CONFIG_FONT_OUTLINE"] = "字型描邊",
    ["CONFIG_FONT_SHADOW"] = "字型陰影",
    
    -- Messages
    ["MSG_ADDON_LOADED"] = "PeaversDynamicStats 已載入。輸入 /pds 查看指令。",
    ["MSG_SHOWN"] = "PeaversDynamicStats 已顯示。",
    ["MSG_HIDDEN"] = "PeaversDynamicStats 已隱藏。",
    
    -- Config UI - Template Settings
    ["CONFIG_TEMPLATE_SETTINGS"] = "範本管理",
    ["CONFIG_TEMPLATE_DESC"] = "將當前設定儲存為命名範本（例如「輸出配置」、「坦克配置」），可套用於任何角色或專精。範本在所有角色間共享。",
    ["CONFIG_CREATE_TEMPLATE"] = "建立新範本：",
    ["CONFIG_CREATE_TEMPLATE_BTN"] = "將當前設定儲存為範本",
    ["CONFIG_MANAGE_TEMPLATES"] = "可用範本：",
    ["CONFIG_NO_TEMPLATES"] = "尚未建立範本。從當前設定建立一個吧！",

    -- Template Operations
    ["TEMPLATE_CREATE_PROMPT"] = "請輸入新範本的名稱：",
    ["TEMPLATE_APPLY_CONFIRM"] = "將範本'%s'套用到當前設定？這將覆蓋你的當前配置。",
    ["TEMPLATE_DELETE_CONFIRM"] = "刪除範本'%s'？此操作無法復原。",
    ["TEMPLATE_RENAME_PROMPT"] = "請輸入範本'%s'的新名稱：",

    -- Template Messages
    ["TEMPLATE_CREATED"] = "範本'%s'建立成功！",
    ["TEMPLATE_APPLIED"] = "範本'%s'套用成功！",
    ["TEMPLATE_DELETED"] = "範本'%s'已刪除。",
    ["TEMPLATE_RENAMED"] = "範本已從'%s'重新命名為'%s'。",

    -- Template Errors
    ["TEMPLATE_ERROR_EMPTY_NAME"] = "範本名稱不能為空。",
    ["TEMPLATE_ERROR_DUPLICATE"] = "已存在同名範本。",
    ["TEMPLATE_ERROR_NOT_FOUND"] = "未找到範本。",
    ["TEMPLATE_ERROR_NO_PROFILE"] = "沒有可用的設定檔來建立範本。",
    ["TEMPLATE_ERROR_INVALID_DATA"] = "設定檔資料無效。",
    ["TEMPLATE_ERROR_CORRUPTED"] = "範本資料已損壞。",

    -- Common Buttons
    ["CREATE"] = "建立",
    ["APPLY"] = "套用",
    ["DELETE"] = "刪除",
    ["RENAME"] = "重新命名",
    ["CANCEL"] = "取消",

    -- Misc
    ["NEW_BADGE"] = "新功能！",
}

-- Korean (한국어)
Locales["koKR"] = {
    -- Stat Names
    ["STAT_STRENGTH"] = "힘",
    ["STAT_AGILITY"] = "민첩성",
    ["STAT_INTELLECT"] = "지능",
    ["STAT_STAMINA"] = "체력",
    ["STAT_HASTE"] = "가속",
    ["STAT_CRIT"] = "치명타",
    ["STAT_MASTERY"] = "특화",
    ["STAT_VERSATILITY"] = "유연성",
    ["STAT_VERSATILITY_DAMAGE"] = "유연성 (공격력)",
    ["STAT_VERSATILITY_DEFENSE"] = "유연성 (방어력)",
    ["STAT_SPEED"] = "이동 속도",
    ["STAT_LEECH"] = "생명력 흡수",
    ["STAT_AVOIDANCE"] = "회피",
    ["STAT_DEFENSE"] = "방어도",
    ["STAT_DODGE"] = "회피율",
    ["STAT_PARRY"] = "무기 막기",
    ["STAT_BLOCK"] = "방패 막기",
    ["STAT_ARMOR_PENETRATION"] = "방어구 관통력",
    
    -- Commands
    ["CMD_TOGGLE"] = "능력치 표시 전환",
    ["CMD_CONFIG"] = "설정 패널 열기",
    ["CMD_HELP"] = "사용 가능한 명령어 표시",
    
    -- Config UI - Section Headers
    ["CONFIG_DISPLAY_SETTINGS"] = "표시 설정",
    ["CONFIG_STAT_OPTIONS"] = "능력치 옵션",
    ["CONFIG_BAR_APPEARANCE"] = "바 외형",
    ["CONFIG_SPEC_SETTINGS"] = "전문화 설정",
    ["CONFIG_TEXT_SETTINGS"] = "텍스트 설정",
    
    -- Config UI - Display Settings
    ["CONFIG_FRAME_DIMENSIONS"] = "프레임 크기:",
    ["CONFIG_FRAME_WIDTH"] = "프레임 너비",
    ["CONFIG_BG_OPACITY"] = "배경 투명도",
    ["CONFIG_VISIBILITY_OPTIONS"] = "표시 옵션:",
    ["CONFIG_SHOW_TITLE_BAR"] = "제목 표시줄 표시",
    ["CONFIG_LOCK_POSITION"] = "프레임 위치 잠금",
    ["CONFIG_HIDE_OUT_OF_COMBAT"] = "전투 중이 아닐 때 숨기기",
    ["CONFIG_DISPLAY_MODE"] = "표시 모드",
    ["CONFIG_DISPLAY_MODE_ALWAYS"] = "항상 표시",
    ["CONFIG_DISPLAY_MODE_PARTY"] = "파티에서만 표시",
    ["CONFIG_DISPLAY_MODE_RAID"] = "공격대에서만 표시",
    
    -- Config UI - Stat Options
    ["CONFIG_PRIMARY_STATS"] = "주 능력치",
    ["CONFIG_PRIMARY_STATS_DESC"] = "주 능력치는 백분율로 계산되며 100%(기본값)에서 시작합니다. 버프, 특성 및 장비로 이 값을 100% 이상으로 높일 수 있습니다. 백분율이 높을수록 성능이 향상됩니다.",
    ["CONFIG_SECONDARY_STATS"] = "부 능력치",
    ["CONFIG_SECONDARY_STATS_DESC"] = "부 능력치는 캐릭터의 성능을 향상시킵니다: 치명타, 가속, 특화, 유연성 등.",
    ["CONFIG_SHOW_STAT"] = "%s 표시",
    ["CONFIG_BAR_COLOR"] = "바 색상:",
    
    -- Config UI - Bar Appearance
    ["CONFIG_BAR_DIMENSIONS"] = "바 크기:",
    ["CONFIG_BAR_HEIGHT"] = "바 높이",
    ["CONFIG_BAR_SPACING"] = "바 간격",
    ["CONFIG_BAR_BG_OPACITY"] = "바 배경 투명도",
    ["CONFIG_BAR_OPACITY"] = "바 채우기 투명도",
    ["CONFIG_BAR_STYLE"] = "바 스타일:",
    ["CONFIG_BAR_TEXTURE"] = "바 텍스처",
    ["CONFIG_ADDITIONAL_BAR_OPTIONS"] = "추가 바 옵션:",
    ["CONFIG_SHOW_STAT_CHANGES"] = "능력치 변화 표시",
    ["CONFIG_SHOW_RATINGS"] = "평점 값 표시",
    ["CONFIG_SHOW_OVERFLOW_BARS"] = "오버플로우 바 표시",
    ["CONFIG_ENABLE_TALENT_ADJUSTMENTS"] = "특성 조정 활성화 (도적: 도적의 유연성)",
    
    -- Config UI - Spec Settings
    ["CONFIG_SPEC_DESC"] = "애드온 설정을 모든 전문화 간에 공유할지 또는 각 전문화별로 사용자 지정할지 제어합니다.",
    ["CONFIG_USE_SHARED_SPEC"] = "모든 전문화에 동일한 설정 사용",
    ["CONFIG_SPEC_INFO"] = "활성화하면 능력치 표시, 바 외형 및 기타 설정이 모든 전문화에서 동일하게 유지됩니다. 비활성화하면 각 전문화마다 고유한 설정을 가질 수 있습니다.",
    ["CONFIG_SPEC_SHARED_MSG"] = "이제 설정이 모든 전문화 간에 공유됩니다",
    ["CONFIG_SPEC_SEPARATE_MSG"] = "이제 각 전문화가 자체 설정을 사용합니다",
    
    -- Config UI - Text Settings
    ["CONFIG_FONT_SELECTION"] = "글꼴 선택:",
    ["CONFIG_FONT"] = "글꼴",
    ["CONFIG_FONT_SIZE"] = "글꼴 크기",
    ["CONFIG_FONT_STYLE"] = "글꼴 스타일:",
    ["CONFIG_FONT_OUTLINE"] = "글꼴 외곽선",
    ["CONFIG_FONT_SHADOW"] = "글꼴 그림자",
    
    -- Messages
    ["MSG_ADDON_LOADED"] = "PeaversDynamicStats가 로드되었습니다. /pds를 입력하여 명령어를 확인하세요.",
    ["MSG_SHOWN"] = "PeaversDynamicStats가 표시되었습니다.",
    ["MSG_HIDDEN"] = "PeaversDynamicStats가 숨겨졌습니다.",
    
    -- Config UI - Template Settings
    ["CONFIG_TEMPLATE_SETTINGS"] = "템플릿 관리",
    ["CONFIG_TEMPLATE_DESC"] = "현재 설정을 명명된 템플릿(예: 'DPS 설정', '탱커 설정')으로 저장하여 모든 캐릭터나 전문화에 적용할 수 있습니다. 템플릿은 모든 캐릭터 간에 공유됩니다.",
    ["CONFIG_CREATE_TEMPLATE"] = "새 템플릿 만들기:",
    ["CONFIG_CREATE_TEMPLATE_BTN"] = "현재 설정을 템플릿으로 저장",
    ["CONFIG_MANAGE_TEMPLATES"] = "사용 가능한 템플릿:",
    ["CONFIG_NO_TEMPLATES"] = "아직 생성된 템플릿이 없습니다. 현재 설정에서 하나 만들어 보세요!",

    -- Template Operations
    ["TEMPLATE_CREATE_PROMPT"] = "새 템플릿의 이름을 입력하세요:",
    ["TEMPLATE_APPLY_CONFIRM"] = "템플릿 '%s'을(를) 현재 설정에 적용하시겠습니까? 현재 설정이 덮어쓰기됩니다.",
    ["TEMPLATE_DELETE_CONFIRM"] = "템플릿 '%s'을(를) 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.",
    ["TEMPLATE_RENAME_PROMPT"] = "템플릿 '%s'의 새 이름을 입력하세요:",

    -- Template Messages
    ["TEMPLATE_CREATED"] = "템플릿 '%s'이(가) 성공적으로 생성되었습니다!",
    ["TEMPLATE_APPLIED"] = "템플릿 '%s'이(가) 성공적으로 적용되었습니다!",
    ["TEMPLATE_DELETED"] = "템플릿 '%s'이(가) 삭제되었습니다.",
    ["TEMPLATE_RENAMED"] = "템플릿 이름이 '%s'에서 '%s'(으)로 변경되었습니다.",

    -- Template Errors
    ["TEMPLATE_ERROR_EMPTY_NAME"] = "템플릿 이름을 입력해 주세요.",
    ["TEMPLATE_ERROR_DUPLICATE"] = "같은 이름의 템플릿이 이미 있습니다.",
    ["TEMPLATE_ERROR_NOT_FOUND"] = "템플릿을 찾을 수 없습니다.",
    ["TEMPLATE_ERROR_NO_PROFILE"] = "템플릿을 만들 활성 프로필이 없습니다.",
    ["TEMPLATE_ERROR_INVALID_DATA"] = "프로필 데이터가 잘못되었습니다.",
    ["TEMPLATE_ERROR_CORRUPTED"] = "템플릿 데이터가 손상되었습니다.",

    -- Common Buttons
    ["CREATE"] = "만들기",
    ["APPLY"] = "적용",
    ["DELETE"] = "삭제",
    ["RENAME"] = "이름 변경",
    ["CANCEL"] = "취소",

    -- Misc
    ["NEW_BADGE"] = "새로운 기능!",
}

-- Set the active locale table
local activeLocale = Locales[locale] or Locales[defaultLocale]

-- Metatable for automatic fallback to English
setmetatable(L, {
    __index = function(table, key)
        -- Try to get from active locale
        local value = activeLocale[key]
        if value then
            return value
        end
        
        -- Fallback to English
        value = Locales[defaultLocale][key]
        if value then
            return value
        end
        
        -- If still not found, return the key itself
        return key
    end
})

-- Function to get localized text with formatting
function PDS.L:Get(key, ...)
    local text = L[key]
    if ... then
        return string.format(text, ...)
    end
    return text
end

-- Function to check if a locale is available
function PDS.L:HasLocale(localeCode)
    return Locales[localeCode] ~= nil
end

-- Function to get current locale
function PDS.L:GetCurrentLocale()
    return locale
end
