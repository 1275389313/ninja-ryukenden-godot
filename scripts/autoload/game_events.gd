extends Node
## 全局信号总线（Autoload: GameEvents）。
## 所有跨模块通信只允许通过这里定义的信号，信号名与参数是全局契约，禁止修改。

signal player_health_changed(current: int, max_value: int)
signal player_lives_changed(lives: int)
signal player_died
signal score_changed(score: int)
signal enemy_killed(score_value: int)
signal boss_fight_started
signal boss_health_changed(current: int, max_value: int)
signal boss_defeated
signal level_cleared
signal game_over
signal timer_changed(seconds_left: int)
