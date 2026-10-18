"""Render docs/roadmap.json into docs/roadmap.html (the project plan page).

Usage: python3 tools/build_roadmap.py
The JSON is the source of truth: add or move tasks there, then rebuild.
"""
import html, json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def esc(value):
    return html.escape(str(value))

def pill(status, labels):
    return f'<span class="pill {status}">{esc(labels[status])}</span>'

def main():
    data = json.loads((ROOT / 'docs/roadmap.json').read_text())
    labels = data['statuses']
    tasks = [t for p in data['phases'] for t in p['tasks']]
    done = sum(t['s'] == 'done' for t in tasks)
    doing = sum(t['s'] == 'doing' for t in tasks)
    # The phase with the most active work is the one being worked on.
    # Working phase: the first phase with build work left (doing/next), ignoring
    # standing process tasks such as phone checks.
    def open_work(p): return [t for t in p['tasks'] if t['s'] in ('doing', 'next') and not t.get('standing')]
    current = next((p for p in data['phases'] if open_work(p)), data['phases'][-1])
    phases = []
    for p in data['phases']:
        n = len(p['tasks']); d = sum(t['s'] == 'done' for t in p['tasks'])
        state = 'done' if d == n else ('doing' if any(t['s'] in ('doing', 'done') for t in p['tasks']) else 'planned')
        rows = ''.join(
            f'<li class="task" data-s="{t["s"]}">{pill(t["s"], labels)}'
            f'<div class="tt"><p>{esc(t["t"])}</p><p class="meta">{esc(t.get("src", ""))}'
            f'{" · v" + esc(t["v"]) if t.get("v") else ""}{" · " + esc(t["note"]) if t.get("note") else ""}</p></div></li>'
            for t in p['tasks'])
        phases.append(f'''
<section class="phase {"current" if p is current else ""}" id="{p["id"]}">
 <header class="ph">
  <div class="phid">{esc(p["id"])}</div>
  <div class="phtext"><h2>{esc(p["name"])}</h2><p>{esc(p["goal"])}</p><p class="meta">{esc(p["gdd"])}</p></div>
  <div class="phstat"><span class="count">{d}/{n}</span>{pill(state, {"done": "Complete", "doing": "Active", "planned": "Planned"})}</div>
 </header>
 <div class="bar" role="img" aria-label="{d} of {n} tasks done"><span style="width:{100*d/max(1,n):.0f}%"></span></div>
 <ul class="tasks">{rows}</ul>
</section>''')
    acceptance = ''.join(f'<li class="task" data-s="{a["s"]}">{pill(a["s"], labels)}<div class="tt"><p>{esc(a["t"])}</p></div></li>' for a in data['acceptance'])
    inbox = ''.join(f'<tr><td class="num">{esc(i["date"])}</td><td>{esc(i["t"])}</td><td>{esc(i["to"])}</td></tr>' for i in data['inbox'])
    page = TEMPLATE.format(
        title=esc(data['title']), version=esc(data['version']), updated=esc(data['updated']), rule=esc(data['rule']),
        source=esc(data['source']), done=done, total=len(tasks), doing=doing, pct=round(100 * done / len(tasks)),
        current=esc(current['id'] + ' · ' + current['name']), current_id=current['id'],
        phases=''.join(phases), acceptance=acceptance, inbox=inbox,
        nav=''.join(f'<a href="#{p["id"]}">{esc(p["id"])}</a>' for p in data['phases']))
    (ROOT / 'docs/roadmap.html').write_text(page)
    print(f'roadmap: {done}/{len(tasks)} done, current {current["id"]}')

TEMPLATE = '''<title>{title}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Lilita+One&family=Nunito+Sans:opsz,wght@6..12,400;6..12,600;6..12,800&display=swap">
<style>
/* Layout: one reading column; a summary strip, then phases in order, each a ruled block with its own progress bar. */
:root {{
 --paper:#f5f7ef; --panel:#ffffff; --ink:#1b2a4a; --muted:#5d6a63; --rule:#dfe5d6;
 --meadow:#3c8d4a; --sky:#2e7dc2; --gold:#d9991a; --planned:#8a948d;
 --display:"Lilita One","Trebuchet MS",sans-serif; --body:"Nunito Sans",system-ui,sans-serif;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
 --paper:#111a16; --panel:#18231e; --ink:#e6eee6; --muted:#9fb0a5; --rule:#2a382f;
 --meadow:#5fbf6e; --sky:#62a8e6; --gold:#f0b53c; --planned:#7f8b84; color-scheme:dark }} }}
:root[data-theme="dark"] {{
 --paper:#111a16; --panel:#18231e; --ink:#e6eee6; --muted:#9fb0a5; --rule:#2a382f;
 --meadow:#5fbf6e; --sky:#62a8e6; --gold:#f0b53c; --planned:#7f8b84; color-scheme:dark }}
* {{ box-sizing:border-box }}
body {{ background:var(--paper); color:var(--ink); font:16px/1.5 var(--body); margin:0 }}
.wrap {{ max-width:880px; margin:0 auto; padding-inline:16px; padding-block:28px 64px; display:grid; gap:28px }}
h1,h2 {{ font-family:var(--display); font-weight:400; text-wrap:balance; margin:0; letter-spacing:.01em }}
h1 {{ font-size:clamp(2rem,6vw,2.8rem); line-height:1.05 }}
h2 {{ font-size:1.35rem; line-height:1.15 }}
p {{ margin:0 }}
.meta {{ color:var(--muted); font-size:.82rem }}
.top {{ display:grid; gap:10px }}
.eyebrow {{ text-transform:uppercase; letter-spacing:.12em; font-size:.72rem; font-weight:800; color:var(--meadow) }}
.rule {{ max-width:65ch; color:var(--muted) }}
.summary {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(160px,1fr)); gap:1px; background:var(--rule); border:1px solid var(--rule); border-radius:12px; overflow:hidden }}
.summary div {{ background:var(--panel); padding:14px 16px; display:grid; gap:2px; min-width:0 }}
.summary b {{ font-family:var(--display); font-weight:400; font-size:1.6rem; font-variant-numeric:tabular-nums }}
nav {{ display:flex; flex-wrap:wrap; gap:6px; align-items:center }}
nav a, .filters button {{ font:600 .85rem var(--body); color:var(--ink); text-decoration:none; border:1px solid var(--rule); background:var(--panel); border-radius:999px; padding:6px 12px; cursor:pointer }}
nav a:hover, .filters button:hover {{ border-color:var(--meadow) }}
.filters {{ display:flex; flex-wrap:wrap; gap:6px }}
.filters button[aria-pressed="true"] {{ background:var(--ink); color:var(--paper); border-color:var(--ink) }}
:focus-visible {{ outline:3px solid var(--sky); outline-offset:2px }}
.phase {{ border-top:2px solid var(--rule); padding-top:18px; display:grid; gap:12px }}
.phase.current {{ border-top-color:var(--meadow) }}
.ph {{ display:grid; grid-template-columns:auto 1fr auto; gap:14px; align-items:start }}
.phid {{ font-family:var(--display); font-size:1.1rem; color:var(--paper); background:var(--ink); border-radius:8px; padding:2px 9px; font-variant-numeric:tabular-nums }}
.current .phid {{ background:var(--meadow) }}
.phtext {{ display:grid; gap:4px; min-width:0 }}
.phstat {{ display:grid; justify-items:end; gap:4px }}
.count {{ font-family:var(--display); font-size:1.15rem; font-variant-numeric:tabular-nums }}
.bar {{ height:8px; background:var(--rule); border-radius:999px; overflow:hidden }}
.bar span {{ display:block; height:100%; background:var(--meadow); border-radius:999px }}
.tasks {{ list-style:none; margin:0; padding:0; display:grid; gap:2px }}
.task {{ display:grid; grid-template-columns:7.2rem 1fr; gap:12px; align-items:start; padding:8px 10px; border-radius:8px; background:var(--panel) }}
.tt {{ display:grid; gap:2px; min-width:0 }}
.pill {{ justify-self:start; font-size:.72rem; font-weight:800; letter-spacing:.04em; text-transform:uppercase; border-radius:999px; padding:3px 9px; border:1.5px solid currentColor; white-space:nowrap }}
.pill.done {{ color:var(--meadow) }} .pill.doing {{ color:var(--sky) }} .pill.next {{ color:var(--gold) }} .pill.planned {{ color:var(--planned) }}
.pill.done {{ background:color-mix(in srgb,var(--meadow) 12%,transparent) }}
.pill.doing {{ background:color-mix(in srgb,var(--sky) 12%,transparent) }}
.hidden-by-filter {{ display:none }}
table {{ width:100%; border-collapse:collapse; font-size:.92rem }}
.tablebox {{ overflow-x:auto; border:1px solid var(--rule); border-radius:12px; background:var(--panel) }}
th,td {{ text-align:left; padding:9px 12px; border-bottom:1px solid var(--rule); vertical-align:top }}
th {{ font-size:.72rem; text-transform:uppercase; letter-spacing:.08em; color:var(--muted) }}
tr:last-child td {{ border-bottom:0 }}
.num {{ font-variant-numeric:tabular-nums; white-space:nowrap }}
@media (max-width:560px) {{ .ph {{ grid-template-columns:auto 1fr }} .phstat {{ grid-column:1/-1; justify-items:start; grid-auto-flow:column; justify-content:start }} .task {{ grid-template-columns:1fr }} }}
@media (prefers-reduced-motion: reduce) {{ * {{ scroll-behavior:auto }} }}
</style>
<div class="wrap">
 <div class="top">
  <p class="eyebrow">Game version {version} · updated {updated}</p>
  <h1>{title}</h1>
  <p class="rule">{rule}</p>
  <p class="meta">Source: {source}</p>
 </div>
 <div class="summary">
  <div><span class="meta">Tasks done</span><b>{done} / {total}</b></div>
  <div><span class="meta">In progress</span><b>{doing}</b></div>
  <div><span class="meta">Overall</span><b>{pct}%</b></div>
  <div><span class="meta">Working on</span><b style="font-size:1.05rem">{current}</b></div>
 </div>
 <nav aria-label="Phases">{nav}<a href="#acceptance">Goal</a><a href="#inbox">Requests</a></nav>
 <div class="filters" role="group" aria-label="Show tasks">
  <button type="button" id="f-all" data-f="all" aria-pressed="true">All</button>
  <button type="button" id="f-doing" data-f="doing" aria-pressed="false">In progress</button>
  <button type="button" id="f-next" data-f="next" aria-pressed="false">Next</button>
  <button type="button" id="f-planned" data-f="planned" aria-pressed="false">Planned</button>
  <button type="button" id="f-done" data-f="done" aria-pressed="false">Done</button>
 </div>
 {phases}
 <section class="phase" id="acceptance">
  <header class="ph"><div class="phid">✓</div><div class="phtext"><h2>V2 acceptance goal</h2><p>From the design document: what a child can do when V2 is complete.</p></div></header>
  <ul class="tasks">{acceptance}</ul>
 </section>
 <section class="phase" id="inbox">
  <header class="ph"><div class="phid">+</div><div class="phtext"><h2>Requests log</h2><p>Every new request, with the phase it was added to.</p></div></header>
  <div class="tablebox"><table><thead><tr><th>Date</th><th>Request</th><th>Placed in</th></tr></thead><tbody>{inbox}</tbody></table></div>
 </section>
</div>
<script>
const buttons=[...document.querySelectorAll('.filters button')];
function show(f){{
 buttons.forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.f===f)));
 document.querySelectorAll('.task').forEach(t=>t.classList.toggle('hidden-by-filter',f!=='all'&&t.dataset.s!==f));
 try{{localStorage.setItem('petopia-roadmap-filter',f)}}catch(e){{}}
}}
buttons.forEach(b=>b.addEventListener('click',()=>show(b.dataset.f)));
try{{const saved=localStorage.getItem('petopia-roadmap-filter');if(saved)show(saved)}}catch(e){{}}
</script>
'''

if __name__ == '__main__':
    main()
