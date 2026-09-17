# Tasks

- [x] Task 1: 初始化 Godot 4 项目脚手架
  - [x] SubTask 1.1: 创建 project.godot（2D 项目，视口 256×240，窗口整数倍放大，像素风渲染设置）
  - [x] SubTask 1.2: 配置输入映射（左/右/上/下、跳跃、攻击、开始键）
  - [x] SubTask 1.3: 建立目录结构（scenes/、scripts/、assets/ 等）并创建主场景 Main.tscn，项目可运行出空窗口

- [x] Task 2: 实现玩家角色（FSM）
  - [x] SubTask 2.1: 玩家场景（CharacterBody2D + 碰撞形状 + 占位精灵 + 重力物理）
  - [x] SubTask 2.2: FSM 框架（状态基类 + 状态切换逻辑，玩家与后续敌人共用）
  - [x] SubTask 2.3: 移动状态：待机 / 奔跑 / 跳跃 / 下落
  - [x] SubTask 2.4: 攻击状态：地面与空中挥剑，攻击帧期间在身前生成 Hitbox
  - [x] SubTask 2.5: 攀墙状态：空中接触可攀爬墙体时吸附，上/下攀爬，跳跃键跳离
  - [x] SubTask 2.6: 受击与死亡状态：击退、无敌帧闪烁、死亡表现

- [x] Task 3: 战斗与生命系统
  - [x] SubTask 3.1: Hitbox / Hurtbox 组件（基于 Area2D 信号，可配置伤害值）
  - [x] SubTask 3.2: 通用生命值组件（玩家与敌人共用，含受击无敌帧回调）
  - [x] SubTask 3.3: 玩家命数与重生点重生逻辑（含掉坑即死判定接口）

- [x] Task 4: 敌人系统（基类 + 两种杂兵 + 对象池）
  - [x] SubTask 4.1: 敌人基类（复用 FSM 与生命值组件，受击闪烁、死亡爆分）
  - [x] SubTask 4.2: 奔跑杂兵：生成后向玩家方向奔跑，接触造成伤害
  - [x] SubTask 4.3: 飞行杂兵：正弦轨迹飞行，接触造成伤害
  - [x] SubTask 4.4: 敌人对象池与生成器：生成触发区随玩家推进激活，死亡/离屏回收

- [x] Task 5: 第一关关卡搭建
  - [x] SubTask 5.1: 摄像机跟随玩家（水平滚动 + 关卡左右边界限制）
  - [x] SubTask 5.2: 关卡地形：起点、平台段落、可攀爬墙体、坑洞
  - [x] SubTask 5.3: 关卡敌人布点与生成触发区摆放
  - [x] SubTask 5.4: 简单视差背景与场景占位装饰

- [x] Task 6: 关卡 Boss 与通关
  - [x] SubTask 6.1: Boss 场景：独立生命值、简单移动与攻击模式、可被玩家剑击伤害
  - [x] SubTask 6.2: Boss 战触发：进入 Boss 区域激活 Boss（预留锁屏/血条显示接口）
  - [x] SubTask 6.3: 击败 Boss 后触发通关事件

- [x] Task 7: HUD 与游戏流程
  - [x] SubTask 7.1: 游戏内 HUD：玩家血条、Boss 血条（Boss 战时显示）、命数、分数、倒计时
  - [x] SubTask 7.2: 标题画面 → 按开始键进入第一关
  - [x] SubTask 7.3: 死亡重生 / 游戏结束流程与通关结算画面
  - [x] SubTask 7.4: 倒计时归零判定玩家死亡一次

- [x] Task 8: 联调与整体验证
  - [x] SubTask 8.1: 完整流程走查：标题 → 第一关 → Boss → 通关结算，以及死亡/游戏结束分支
  - [x] SubTask 8.2: 按 checklist.md 逐项验证并修复问题

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 3
- Task 5 depends on Task 1（SubTask 5.3 另依赖 Task 4）
- Task 6 depends on Task 3 与 Task 5
- Task 7 depends on Task 3 与 Task 6
- Task 8 depends on Task 1-7
