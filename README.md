# 像素挂机勇者 Demo

一个使用 Godot 4.3 制作的 2.5D 像素风格自动挂机 RPG Demo，灵感来自经典《勇者斗恶龙》系列。

## 核心玩法

- **自动战斗**：勇者会自动攻击敌人，无需手动操作。
- **挂机升级**：击败敌人获得 EXP 和金币，自动升级提升属性。
- **关卡推进**：普通敌人随波次增强，每 5 关可挑战一次 Boss。
- **Boss 挑战**：点击「挑战 Boss」按钮讨伐更强的敌人，胜利后进入下一区域。
- **装备系统**：击败敌人会掉落武器、头盔、护甲、鞋子、戒指，装备后可大幅提升战力。
- **装备栏**：点击战斗界面的「🎒 装备栏」按钮管理已装备与背包中的装备，支持装备、卸下、出售、一键最佳、强化。
- **技能系统**：战斗中积攒能量，释放治疗术、重击、狂暴三种主动技能。
- **商店系统**：点击「🏪 商店」购买生命药水、属性强化、经验药水、装备宝箱。
- **统计面板**：点击「📊 统计」查看击杀数、金币、伤害、死亡次数、最高关卡等数据。
- **暂停菜单**：按 ESC 打开暂停菜单，可继续、返回标题、重置存档、退出。
- **自动存档**：游戏每 10 秒自动保存进度，关闭后可通过标题画面「继续游戏」读取。
- **音效与 BGM**：包含攻击、受击、升级、金币音效及 8-bit 风格循环背景音乐。

## 项目结构

```
pixel-idle-hero/
├── project.godot          # Godot 项目配置
├── export_presets.cfg     # Web 导出预设
├── assets/
│   ├── fonts/             # 中文字体（Noto Sans CJK SC）
│   ├── images/            # 由 MCP（百智云生图）生成的像素素材
│   ├── sounds/            # 由脚本生成的 8-bit 音效与 BGM
│   └── themes/            # 全局主题，使用中文默认字体
├── scripts/
│   ├── player_data.gd     # 玩家属性、升级、伤害计算、统计
│   ├── enemy_data.gd      # 敌人数据与生成、Boss 特殊机制
│   ├── battle_manager.gd  # 自动战斗计时与伤害结算
│   ├── game_manager.gd    # 关卡、Boss、奖励、复活、存档逻辑
│   ├── equipment_data.gd  # 装备数据与稀有度
│   ├── equipment_manager.gd # 装备掉落、装备/卸下/出售
│   ├── skill_data.gd      # 技能数据
│   ├── skill_manager.gd   # 技能释放、能量、冷却
│   ├── shop_manager.gd    # 商店商品与购买逻辑
│   ├── save_manager.gd    # 本地存档读写
│   ├── audio_manager.gd   # 音效与背景音乐管理
│   ├── floating_text_manager.gd # 伤害数字飘字
│   ├── floating_text.gd   # 飘字动画
│   ├── title_screen.gd    # 标题画面逻辑
│   ├── player.gd          # 勇者视觉表现与动画
│   └── enemy.gd           # 敌人视觉表现与动画
├── scenes/
│   ├── title_screen.tscn  # 标题/封面场景
│   ├── main.tscn          # 主游戏场景
│   ├── player.tscn        # 勇者节点
│   ├── enemy.tscn         # 敌人节点
│   └── audio_manager.tscn # 音频管理器
├── ui/
│   ├── battle_ui.tscn     # 战斗 UI 布局
│   ├── battle_ui.gd       # 战斗 UI 更新与日志
│   ├── equipment_ui.tscn  # 装备栏 UI 布局
│   ├── equipment_ui.gd    # 装备栏交互逻辑
│   ├── shop_ui.tscn       # 商店 UI
│   ├── shop_ui.gd         # 商店交互逻辑
│   ├── stats_ui.tscn      # 统计面板 UI
│   ├── stats_ui.gd        # 统计面板逻辑
│   ├── pause_menu.tscn    # 暂停菜单 UI
│   ├── pause_menu.gd      # 暂停菜单逻辑
│   └── floating_text.tscn # 飘字节点
└── tools/
    ├── generate_assets.py # MCP 生图脚本
    ├── process_images.py  # 图片后处理脚本
    └── generate_sounds.py # 音效生成脚本
```

## 运行方式

### 1. 在 Godot 编辑器中运行

1. 用 Godot 4.3 打开 `pixel-idle-hero/` 文件夹。
2. 按 **F5** 或点击「运行项目」。

### 2. 命令行运行（无窗口验证）

```bash
./Godot_v4.3-stable_win64_console.exe --headless --path . --quit-after 3000
```

### 3. Web 导出

已配置 Web 导出预设，可通过 Godot 的「项目 > 导出 > Web」导出为 HTML5。

```bash
./Godot_v4.3-stable_win64_console.exe --headless --path . --export-release "Web" ../web-export/index.html
```

导出后启动本地服务器即可在浏览器中游玩：

```bash
cd ../web-export
python -m http.server 8765
# 浏览器打开 http://localhost:8765
```

## 操作说明

- 启动后进入标题画面，可选择「继续游戏」或「开始新游戏」。
- 勇者会自动攻击当前敌人。
- 观察顶部状态栏：等级、HP、EXP、金币、关卡、能量。
- 点击底部「🎒 装备栏」按钮打开装备管理界面。
  - 左侧为已装备槽位，右侧为背包。
  - 点击装备查看详情，可装备、卸下、出售、强化。
  - 「一键最佳」会自动把背包中评分最高的装备穿到身上。
- 点击「🏪 商店」购买药水、属性强化、经验药水或装备宝箱。
- 点击「📊 统计」查看完整冒险数据。
- 技能条显示在敌人面板下方，能量足够且冷却完毕时点击释放。
- 到达第 5 关后，底部「挑战 Boss」按钮会亮起，点击即可挑战 Boss。
- 战斗中按 **ESC** 打开暂停菜单。
- 若勇者战败，会在 2 秒后自动复活并继续挂机。

## 中文显示说明

本项目使用 **Noto Sans CJK SC（思源黑体）** 作为默认字体，已在 `assets/themes/default_theme.tres` 中配置，并通过 `project.godot` 的全局主题生效，确保 Label、Button、RichTextLabel 等 UI 控件正确显示中文。

> 注意：完整中文字体文件约 16 MB，Web 导出的 `.pck` 会因此变大。如需优化加载速度，可替换为只包含常用汉字的子集字体。

## 美术与音频素材说明

- **图片素材**：所有图片均通过 **百智云生图 MCP** 自动生成，包括勇者、敌人、装备图标、标题背景。生成后经本地脚本自动去背、裁剪、缩放。
- **音效与 BGM**：使用 Python 脚本程序化生成 8-bit 风格 WAV 文件，包括攻击、受击、升级、金币音效和循环背景音乐。

## 后续可扩展方向

- 技能树与更多主动/被动技能
- 宠物/伙伴系统
- 转生（Prestige）与天赋系统
- 更多 Boss 机制与阶段
- 成就系统与每日任务
- 云端存档与排行榜
