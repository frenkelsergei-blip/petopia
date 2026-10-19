#!/bin/sh
# A59: cut every P69 Codex sheet (assets/ui/*-p69/source/kit-raw.png).
set -e
B="python3 tools/build_blue_kit.py --rows"
$B assets/ui/frame-p69 close plaque coins menu_btn big_green green price cream tile item row tab_on tab badge free lock dashed question
$B assets/ui/controls-p69 group track fill knob switch_on switch_off left right bar bar_fill game_card head_tile stage stage_on
$B assets/ui/ball-p69 meter pointer throw ball score hint star star_empty popup reward
$B assets/ui/overlay-p69 world world_locked lock_popup tray item_tile soon sign banner ability_frame part_slot pin_btn goal_row
$B assets/ui/pictures-p69 catch hide dig result beach forest picnic bunny bird child teen adult
python3 tools/build_magenta_kit.py assets/ui/icons-p69 6,8,8,3 food happy energy clean health bond music sound voice hint arrow pin size hand details adventures shop games collection decorate settings home coin paw heart
python3 tools/build_shadow_kit.py
