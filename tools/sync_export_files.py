"""Add the current style kits to the web export list (export_presets.cfg).
Source sheets (any /source/ folder) are never shipped (web image budget)."""
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
KEEP=['assets/ui/menu-paper/ic_map.png','assets/ui/menu-paper/ic_gear.png','assets/ui/menu-paper/ic_pad.png','assets/ui/menu-paper/ic_play.png','assets/ui/menu-paper/ic_paw.png','assets/ui/shop-paper/armchair.png','assets/ui/roomui-paper/ic_paw.png']
KITS=['assets/art/meadow-p31','assets/art/heroes-p31/frames','assets/ui/hud-p32','assets/ui/hud2-p32','assets/ui/hud3-p32','assets/ui/menu-p32','assets/ui/pause-p32','assets/ui/roomui-p32','assets/ui/bag-p32','assets/ui/shop-p32','assets/ui/map-p32','assets/ui/details-p32','assets/ui/room-p43','assets/ui/food-p32','assets/ui/menu50-p32','assets/ui/adopt-p32','assets/ui/result-p32','assets/ui/ball-p32','assets/ui/turn-p32','assets/ui/collect-p32','assets/ui/games-p32','assets/ui/areamap-p32','assets/ui/popup-p32','assets/ui/decor-p32','assets/ui/portraits-p32','assets/ui/tama-p32','assets/ui/journey-p32','assets/ui/complete-p32','assets/ui/goals-p32','assets/ui/menu41-p32','assets/ui/frame-p68','assets/ui/frame-p69','assets/ui/controls-p69','assets/ui/ball-p69','assets/ui/shadow-p69','assets/ui/overlay-p69','assets/ui/icons-p69','assets/ui/pictures-p69','assets/ui/shadow-p70']
cfg=ROOT/'export_presets.cfg'
text=cfg.read_text()
m=re.search(r'export_files=PackedStringArray\((.*?)\)\n',text)
have=re.findall(r'"([^"]+)"',m.group(1))
add=[]
for kit in KITS:
    for f in sorted((ROOT/kit).rglob('*')):
        if f.suffix not in ('.png','.json') or '/source/' in str(f): continue
        # Superseded layer attempts (the env kits replaced them; never drawn).
        if f.parent.name=='meadow-p31' and f.name.startswith(('L_','cv_','ce_','tw_')): continue
        r='res://'+str(f.relative_to(ROOT))
        if r not in have: add.append(r)
# Pictures replaced by the P32/P43 screens: never loaded in the paper style.
DROP={'res://assets/ui/paper-pictures/garden.png','res://assets/ui/paper-pictures/picnic-finish.png','res://assets/ui/paper-pictures/world-map.png','res://assets/ui/paper-pictures/phone.png',
 'res://assets/ui/menu-paper/plate.png','res://assets/ui/room-paper/plate.png','res://assets/ui/bag-paper/base.png','res://assets/ui/shop-paper/base.png','res://assets/ui/details-paper/base.png',
 'res://assets/ui/menu-v3/lock.png','res://assets/ui/paper-pictures/care-map.png','res://assets/art/pet-v2/bathe.png','res://assets/art/pet-v2/carry.png','res://assets/art/pet-v2/drink.png','res://assets/art/pet-v2/eat.png','res://assets/art/pet-v2/sleep.png','res://assets/art/home-flow-v1/idle-actors.png','res://assets/ui/menu-p32/pair.png',
 'res://assets/art/meadow-p31/crank_wheel.png','res://assets/art/meadow-p31/rope_post.png',
 'res://assets/ui/areamap-p32/board.png','res://assets/ui/areamap-p32/map.png','res://assets/ui/areamap-p32/legend.png','res://assets/ui/areamap-p32/cloud.png',
 'res://assets/ui/bag-p32/blob.png','res://assets/ui/bag-p32/board.png','res://assets/ui/bag-p32/close.png','res://assets/ui/bag-p32/count.png','res://assets/ui/bag-p32/give.png','res://assets/ui/bag-p32/ic_bag.png','res://assets/ui/bag-p32/side.png','res://assets/ui/bag-p32/slot.png','res://assets/ui/bag-p32/slot_empty.png','res://assets/ui/bag-p32/slot_on.png','res://assets/ui/bag-p32/tab.png','res://assets/ui/bag-p32/tab_on.png','res://assets/ui/bag-p32/title.png','res://assets/ui/collect-p32/back.png','res://assets/ui/collect-p32/board.png','res://assets/ui/collect-p32/plank.png','res://assets/ui/collect-p32/section.png','res://assets/ui/collect-p32/slot.png','res://assets/ui/collect-p32/slot_empty.png','res://assets/ui/collect-p32/title.png','res://assets/ui/complete-p32/board.png','res://assets/ui/complete-p32/bond.png','res://assets/ui/complete-p32/coin.png','res://assets/ui/complete-p32/continue.png','res://assets/ui/complete-p32/heroes.png','res://assets/ui/complete-p32/mypet.png','res://assets/ui/complete-p32/ribbon.png','res://assets/ui/complete-p32/star_off.png','res://assets/ui/complete-p32/teaser.png','res://assets/ui/complete-p32/tile.png','res://assets/ui/complete-p32/xp.png','res://assets/ui/details-p32/back.png','res://assets/ui/details-p32/board.png','res://assets/ui/details-p32/care.png','res://assets/ui/details-p32/growth.png','res://assets/ui/details-p32/name.png','res://assets/ui/details-p32/photo.png','res://assets/ui/details-p32/pill_blue.png','res://assets/ui/details-p32/pill_green.png','res://assets/ui/details-p32/pill_yellow.png','res://assets/ui/details-p32/row.png','res://assets/ui/details-p32/stage.png','res://assets/ui/details-p32/stage_on.png','res://assets/ui/details-p32/title.png','res://assets/ui/food-p32/board.png','res://assets/ui/food-p32/close.png','res://assets/ui/food-p32/count.png','res://assets/ui/food-p32/free.png','res://assets/ui/food-p32/shop.png','res://assets/ui/food-p32/tile.png','res://assets/ui/food-p32/tile_off.png','res://assets/ui/food-p32/title.png','res://assets/ui/games-p32/card.png','res://assets/ui/games-p32/card_title.png','res://assets/ui/games-p32/heart.png','res://assets/ui/games-p32/info.png','res://assets/ui/games-p32/paw.png','res://assets/ui/games-p32/play.png','res://assets/ui/games-p32/reward.png','res://assets/ui/games-p32/title.png','res://assets/ui/journey-p32/board.png','res://assets/ui/journey-p32/close.png','res://assets/ui/journey-p32/frame.png','res://assets/ui/journey-p32/frame_portrait.png','res://assets/ui/journey-p32/map.png','res://assets/ui/journey-p32/plaque.png','res://assets/ui/journey-p32/row.png','res://assets/ui/journey-p32/side.png','res://assets/ui/journey-p32/slot.png','res://assets/ui/journey-p32/title.png','res://assets/ui/menu41-p32/k_coins.png','res://assets/ui/menu41-p32/m_ic_games.png','res://assets/ui/menu41-p32/m_ic_settings.png','res://assets/ui/menu41-p32/m_logo.png','res://assets/ui/menu41-p32/m_pill.png','res://assets/ui/menu41-p32/m_plank.png','res://assets/ui/menu41-p32/m_start.png','res://assets/ui/menu50-p32/board.png','res://assets/ui/menu50-p32/close.png','res://assets/ui/menu50-p32/tile.png','res://assets/ui/menu50-p32/title.png','res://assets/ui/pause-p32/card.png','res://assets/ui/pause-p32/close.png','res://assets/ui/pause-p32/panel.png','res://assets/ui/pause-p32/resume.png','res://assets/ui/pause-p32/title.png','res://assets/ui/result-p32/again.png','res://assets/ui/result-p32/board.png','res://assets/ui/result-p32/mypet.png','res://assets/ui/result-p32/row.png','res://assets/ui/result-p32/title.png','res://assets/ui/result-p32/total.png','res://assets/ui/shop-p32/board.png','res://assets/ui/shop-p32/buy.png','res://assets/ui/shop-p32/card.png','res://assets/ui/shop-p32/card_on.png','res://assets/ui/shop-p32/close.png','res://assets/ui/shop-p32/coins.png','res://assets/ui/shop-p32/ic_stall.png','res://assets/ui/shop-p32/side.png','res://assets/ui/shop-p32/tab.png','res://assets/ui/shop-p32/tab_on.png','res://assets/ui/shop-p32/title.png',
 # Old fallback screens replaced by P41/P68 (never loaded in any captured flow).
 'res://assets/ui/bag-paper/badge.png','res://assets/ui/bag-paper/button_gold.png','res://assets/ui/bag-paper/glow.png','res://assets/ui/bag-paper/items/apple.png','res://assets/ui/bag-paper/items/apple_big.png','res://assets/ui/bag-paper/items/backpack.png','res://assets/ui/bag-paper/items/basket.png','res://assets/ui/bag-paper/items/berries.png','res://assets/ui/bag-paper/items/carrot.png','res://assets/ui/bag-paper/items/cookie.png','res://assets/ui/bag-paper/items/crate.png','res://assets/ui/bag-paper/items/feather.png','res://assets/ui/bag-paper/items/fish.png','res://assets/ui/bag-paper/items/key.png','res://assets/ui/bag-paper/items/magic_carrot.png','res://assets/ui/bag-paper/items/robot_head.png','res://assets/ui/bag-paper/items/scroll.png','res://assets/ui/bag-paper/items/tab_quests.png','res://assets/ui/bag-paper/items/tab_snacks.png','res://assets/ui/bag-paper/items/tab_tools.png','res://assets/ui/bag-paper/items/tab_treasures.png','res://assets/ui/bag-paper/pill.png','res://assets/ui/bag-paper/slot.png','res://assets/ui/bag-paper/slot_on.png','res://assets/ui/bag-paper/tab_on.png','res://assets/ui/bag-paper/tab_on_0.png','res://assets/ui/bag-paper/tab_on_1.png','res://assets/ui/bag-paper/tab_on_2.png','res://assets/ui/bag-paper/tab_on_3.png','res://assets/ui/details-paper/berries.png','res://assets/ui/details-paper/card.png','res://assets/ui/details-paper/card_on.png','res://assets/ui/details-paper/check.png','res://assets/ui/details-paper/clock.png','res://assets/ui/details-paper/fill_bond.png','res://assets/ui/details-paper/fill_clean.png','res://assets/ui/details-paper/fill_energy.png','res://assets/ui/details-paper/fill_food.png','res://assets/ui/details-paper/fill_happy.png','res://assets/ui/details-paper/fill_health.png','res://assets/ui/details-paper/icon_bond.png','res://assets/ui/details-paper/icon_clean.png','res://assets/ui/details-paper/icon_energy.png','res://assets/ui/details-paper/icon_food.png','res://assets/ui/details-paper/icon_happy.png','res://assets/ui/details-paper/icon_health.png','res://assets/ui/details-paper/portrait_room.png','res://assets/ui/details-paper/stage_adult.png','res://assets/ui/details-paper/stage_adult_grey.png','res://assets/ui/details-paper/stage_baby_grey.png','res://assets/ui/details-paper/stage_child.png','res://assets/ui/details-paper/stage_child_grey.png','res://assets/ui/details-paper/stage_teen.png','res://assets/ui/details-paper/stage_teen_grey.png','res://assets/ui/details-paper/track.png','res://assets/ui/food-v1/foods.png','res://assets/ui/hud-v2/fill_blue.png','res://assets/ui/hud-v2/fill_orange.png','res://assets/ui/hud-v2/heart_empty.png','res://assets/ui/hud-v2/heart_full.png','res://assets/ui/hud-v2/icon_energy.png','res://assets/ui/hud-v2/icon_food.png','res://assets/ui/hud-v2/panel.png','res://assets/ui/hud-v2/portrait_sky.png','res://assets/ui/menu-paper/coin.png','res://assets/ui/menu-paper/coin_plaque.png','res://assets/ui/menu-paper/logo.png','res://assets/ui/menu-paper/plank_cream.png','res://assets/ui/menu-paper/plank_green.png','res://assets/ui/menu-paper/plank_grey.png','res://assets/ui/menu-paper/plank_small.png','res://assets/ui/menu-paper/tagline.png','res://assets/ui/room-paper/bed_front.png','res://assets/ui/room-paper/bowl_food.png','res://assets/ui/room-paper/bowl_food_full.png','res://assets/ui/room-paper/bowl_water.png','res://assets/ui/room-paper/bowl_water_full.png','res://assets/ui/room-paper/bubble.png','res://assets/ui/room-paper/bubbles.png','res://assets/ui/room-paper/drop.png','res://assets/ui/room-paper/duck.png','res://assets/ui/room-paper/foam.png','res://assets/ui/room-paper/fox_sleep.png','res://assets/ui/room-paper/heart.png','res://assets/ui/room-paper/kibble_bag.png','res://assets/ui/room-paper/kibble_stream.png','res://assets/ui/room-paper/tub_back.png','res://assets/ui/room-paper/tub_front.png','res://assets/ui/room-paper/water_stream.png','res://assets/ui/room-paper/watering_can.png','res://assets/ui/room-paper/zzz.png','res://assets/ui/roomui-paper/board.png','res://assets/ui/roomui-paper/board_title.png','res://assets/ui/roomui-paper/care_button.png','res://assets/ui/roomui-paper/close.png','res://assets/ui/roomui-paper/menu_button.png','res://assets/ui/roomui-paper/meter_chip.png','res://assets/ui/roomui-paper/meter_track.png','res://assets/ui/roomui-paper/need_clean.png','res://assets/ui/roomui-paper/need_energy.png','res://assets/ui/roomui-paper/need_food.png','res://assets/ui/roomui-paper/need_happy.png','res://assets/ui/roomui-paper/status.png','res://assets/ui/roomui-paper/tile.png','res://assets/ui/roomui-paper/tile_on.png','res://assets/ui/settings-paper/controls.png','res://assets/ui/settings-paper/divider.png','res://assets/ui/settings-paper/fill.png','res://assets/ui/settings-paper/ic_controls.png','res://assets/ui/settings-paper/ic_hint.png','res://assets/ui/settings-paper/ic_motion.png','res://assets/ui/settings-paper/ic_music.png','res://assets/ui/settings-paper/ic_sound.png','res://assets/ui/settings-paper/ic_timing.png','res://assets/ui/settings-paper/ic_voice.png','res://assets/ui/settings-paper/knob.png','res://assets/ui/settings-paper/pause_panel.png','res://assets/ui/settings-paper/paused_tag.png','res://assets/ui/settings-paper/plank_cream.png','res://assets/ui/settings-paper/plank_green.png','res://assets/ui/settings-paper/resting.png','res://assets/ui/settings-paper/settings_panel.png','res://assets/ui/settings-paper/stepper.png','res://assets/ui/settings-paper/title.png','res://assets/ui/settings-paper/toggle_off.png','res://assets/ui/settings-paper/toggle_on.png','res://assets/ui/settings-paper/track.png','res://assets/ui/shop-paper/ball.png','res://assets/ui/shop-paper/beach_ball.png','res://assets/ui/shop-paper/buy.png','res://assets/ui/shop-paper/card.png','res://assets/ui/shop-paper/card_on.png','res://assets/ui/shop-paper/collar.png','res://assets/ui/shop-paper/cushion.png','res://assets/ui/shop-paper/divider.png','res://assets/ui/shop-paper/lamp.png','res://assets/ui/shop-paper/plant.png','res://assets/ui/shop-paper/price.png','res://assets/ui/shop-paper/rug.png','res://assets/ui/shop-paper/tab.png','res://assets/ui/shop-paper/tab_on.png','res://assets/ui/shop-paper/toy_box.png'}
# A59: UI pieces replaced by the P69 kits (only the fallback paths used them;
# every screen was captured and none loads them). Keeps the 220 MiB budget.
# Also the unused menu41 crops (port_/land_/ui_: never referenced).
DROP|={'res://assets/ui/menu41-p32/land_block.png',
 'res://assets/ui/menu41-p32/land_coins.png',
 'res://assets/ui/menu41-p32/land_games.png',
 'res://assets/ui/menu41-p32/land_settings.png',
 'res://assets/ui/menu41-p32/port_adventures.png',
 'res://assets/ui/menu41-p32/port_coins.png',
 'res://assets/ui/menu41-p32/port_collection.png',
 'res://assets/ui/menu41-p32/port_games.png',
 'res://assets/ui/menu41-p32/port_logo.png',
 'res://assets/ui/menu41-p32/port_mypet.png',
 'res://assets/ui/menu41-p32/port_settings.png',
 'res://assets/ui/menu41-p32/port_start.png',
 'res://assets/ui/menu41-p32/ui_coins.png',
 'res://assets/ui/menu41-p32/ui_column.png',
 'res://assets/ui/menu41-p32/ui_pills.png',
 'res://assets/ui/ball-p32/back.png',
 'res://assets/ui/ball-p32/ball.png',
 'res://assets/ui/ball-p32/coins.png',
 'res://assets/ui/ball-p32/hint.png',
 'res://assets/ui/ball-p32/ic_ball.png',
 'res://assets/ui/ball-p32/marker.png',
 'res://assets/ui/ball-p32/meter.png',
 'res://assets/ui/ball-p32/paw_off.png',
 'res://assets/ui/ball-p32/paw_on.png',
 'res://assets/ui/ball-p32/score.png',
 'res://assets/ui/ball-p32/throw.png',
 'res://assets/ui/ball-p32/title.png',
 'res://assets/ui/decor-p32/card.png',
 'res://assets/ui/decor-p32/card_on.png',
 'res://assets/ui/decor-p32/close.png',
 'res://assets/ui/decor-p32/done.png',
 'res://assets/ui/decor-p32/place.png',
 'res://assets/ui/decor-p32/price.png',
 'res://assets/ui/decor-p32/title.png',
 'res://assets/ui/decor-p32/tray.png',
 'res://assets/ui/details-p32/fill_blue.png',
 'res://assets/ui/details-p32/fill_green.png',
 'res://assets/ui/details-p32/fill_yellow.png',
 'res://assets/ui/details-p32/ic_bond.png',
 'res://assets/ui/details-p32/ic_clean.png',
 'res://assets/ui/details-p32/ic_energy.png',
 'res://assets/ui/details-p32/ic_food.png',
 'res://assets/ui/details-p32/ic_happy.png',
 'res://assets/ui/details-p32/ic_health.png',
 'res://assets/ui/details-p32/track.png',
 'res://assets/ui/frame-p68/button.png',
 'res://assets/ui/frame-p68/card.png',
 'res://assets/ui/frame-p68/close.png',
 'res://assets/ui/frame-p68/plaque.png',
 'res://assets/ui/frame-p68/row.png',
 'res://assets/ui/frame-p68/slot.png',
 'res://assets/ui/frame-p68/tab.png',
 'res://assets/ui/frame-p68/tab_on.png',
 'res://assets/ui/frame-p68/tile.png',
 'res://assets/ui/games-p32/pic_ball.png',
 'res://assets/ui/games-p32/pic_dig.png',
 'res://assets/ui/games-p32/pic_hide.png',
 'res://assets/ui/journey-p32/slot_on.png',
 'res://assets/ui/map-p32/back.png',
 'res://assets/ui/map-p32/beach.png',
 'res://assets/ui/map-p32/check.png',
 'res://assets/ui/map-p32/cloud.png',
 'res://assets/ui/map-p32/forest.png',
 'res://assets/ui/map-p32/later.png',
 'res://assets/ui/map-p32/lock.png',
 'res://assets/ui/map-p32/map.png',
 'res://assets/ui/map-p32/meadows.png',
 'res://assets/ui/map-p32/node.png',
 'res://assets/ui/map-p32/node_now.png',
 'res://assets/ui/map-p32/side.png',
 'res://assets/ui/map-p32/sprig.png',
 'res://assets/ui/map-p32/start.png',
 'res://assets/ui/map-p32/title.png',
 'res://assets/ui/map-p32/world_card.png',
 'res://assets/ui/menu41-p32/m_coin_pill.png',
 'res://assets/ui/menu50-p32/ic_bag.png',
 'res://assets/ui/menu50-p32/ic_collection.png',
 'res://assets/ui/menu50-p32/ic_details.png',
 'res://assets/ui/menu50-p32/ic_games.png',
 'res://assets/ui/menu50-p32/ic_home.png',
 'res://assets/ui/menu50-p32/ic_map.png',
 'res://assets/ui/menu50-p32/ic_settings.png',
 'res://assets/ui/menu50-p32/ic_shop.png',
 'res://assets/ui/pause-p32/picture.png',
 'res://assets/ui/popup-p32/ability.png',
 'res://assets/ui/popup-p32/gotit.png',
 'res://assets/ui/popup-p32/pill.png',
 'res://assets/ui/popup-p32/set_card.png',
 'res://assets/ui/popup-p32/toast.png',
 'res://assets/ui/result-p32/basket.png',
 'res://assets/ui/result-p32/check.png',
 'res://assets/ui/result-p32/coin.png',
 'res://assets/ui/result-p32/coins.png',
 'res://assets/ui/result-p32/ic_leaf.png',
 'res://assets/ui/result-p32/ic_map.png',
 'res://assets/ui/result-p32/paw.png'}
# A60: block pieces of the first layered Meadow Fields, replaced by the painted set pieces.
DROP|={'res://assets/art/meadow-p31/cliff_fill.png','res://assets/art/meadow-p31/log_bridge.png','res://assets/art/meadow-p31/sun_gate.png','res://assets/art/meadow-p31/burrow_mouth.png','res://assets/art/meadow-p31/burrow_back.png','res://assets/art/meadow-p31/stone_wall.png','res://assets/art/meadow-p31/ivy_hang.png','res://assets/art/meadow-p31/paw_glow.png','res://assets/art/meadow-p31/windmill.png','res://assets/art/meadow-p31/windmill_sails.png'}
have=[h for h in have if '/source/' not in h and h not in DROP]
add=[a for a in add if a not in DROP]
for k in KEEP:
    if 'res://'+k not in have+add and (ROOT/k).exists(): add.append('res://'+k)
new='export_files=PackedStringArray('+', '.join(f'"{h}"' for h in have+add)+')\n'
cfg.write_text(text[:m.start()]+new+text[m.end():])
print('added',len(add))
for a in add: print(' ',a)
