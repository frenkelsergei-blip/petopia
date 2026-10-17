"""Export the actual Godot game and package lossless, size-safe Cloudflare assets."""
import argparse, datetime, gzip, hashlib, json, os, re, shutil, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def engine_path():
 candidates=[os.environ.get('GODOT_BIN'),'/Applications/Godot.app/Contents/MacOS/Godot',shutil.which('godot'),shutil.which('godot4')]
 return next((str(p) for p in candidates if p and Path(p).is_file()),None)

def build(output=None):
 version=(ROOT/'VERSION').read_text().strip()
 if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-z0-9.]+)?',version):raise SystemExit('VERSION must be a semantic version.')
 if f'config/version="{version}"' not in (ROOT/'project.godot').read_text():raise SystemExit('VERSION and project.godot disagree.')
 engine=engine_path()
 if not engine:raise SystemExit('Install Godot4.7.2 or set GODOT_BIN.')
 raw=ROOT/'builds/web-raw';raw.mkdir(parents=True,exist_ok=True)
 (ROOT/'builds/.gdignore').touch()  # Generated output/local backups are not Godot resources.
 output=Path(output or ROOT/'builds/web').resolve()
 output.mkdir(parents=True,exist_ok=True)
 result=subprocess.run([engine,'--headless','--path',str(ROOT),'--export-release','Web',str(raw/'index.html')],capture_output=True,text=True)
 log=result.stdout+result.stderr
 (ROOT/'test-results').mkdir(exist_ok=True)
 (ROOT/'test-results/web-export.log').write_text(log)
 if result.returncode or 'SCRIPT ERROR:' in log or '\nERROR:' in log:raise SystemExit('Web export failed; see test-results/web-export.log.')
 # Only clear the dedicated generated output, never project sources.
 for file in output.iterdir():
  if file.is_file():file.unlink()
 for file in raw.iterdir():
  if file.is_file() and file.suffix not in ['.pck','.wasm']:shutil.copy2(file,output/file.name)
 wasm=(raw/'index.wasm').read_bytes()
 (output/'index.wasm.bin').write_bytes(gzip.compress(wasm,compresslevel=9,mtime=0))
 # Pages strips Content-Encoding overrides. Decode a named transport binary in
 # the engine loader instead of depending on HTTP gzip headers.
 javascript=output/'index.js'
 source=javascript.read_text()
 anchor='loadPromise = preloader.loadPromise(`${loadPath}.wasm`, size, true);'
 if source.count(anchor)!=1:raise SystemExit('Godot engine loader changed; review the WASM transport adapter.')
 replacement="loadPromise = preloader.loadPromise(`${loadPath}.wasm.bin`, size, true).then(response => new Response(response.body.pipeThrough(new DecompressionStream('gzip')), {headers: {'Content-Type': 'application/wasm'}}));"
 source=source.replace(anchor,replacement)
 # The engine copies a preloaded pack into its in-memory filesystem. On phones
 # that second 42 MB copy, on top of the downloaded one, can end the tab;
 # let the filesystem own the downloaded buffer instead.
 copy='FS.writeFile(path,new Uint8Array(buffer))'
 if source.count(copy)!=1:raise SystemExit('Godot preload copy changed; review the pack ownership adapter.')
 source=source.replace(copy,'FS.writeFile(path,buffer instanceof Uint8Array?buffer:new Uint8Array(buffer),{canOwn:true})')
 javascript.write_text(source)
 pack=(raw/'index.pck').read_bytes();digest=hashlib.sha256(pack).hexdigest()
 parts=[];chunk_size=12*1024*1024
 for index,offset in enumerate(range(0,len(pack),chunk_size)):
  chunk=pack[offset:offset+chunk_size];name=f'game-{digest[:16]}-{index}.bin'
  (output/name).write_bytes(chunk);parts.append({'file':name,'bytes':len(chunk),'sha256':hashlib.sha256(chunk).hexdigest()})
 (output/'game-pack.json').write_text(json.dumps({'bytes':len(pack),'sha256':digest,'parts':parts},indent=2)+'\n')
 (output/'_headers').write_text('/*\n  Cache-Control: no-cache\n  X-Content-Type-Options: nosniff\n/index.wasm.bin\n  Content-Type: application/octet-stream\n/game-*.bin\n  Cache-Control: public, max-age=31536000, immutable\n')
 commit=subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,capture_output=True,text=True).stdout.strip() or None
 release={'version':version,'commit':commit,'built_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'engine':'4.7.2','platform':'Web','thread_support':False,'pack_sha256':digest,'pack_bytes':len(pack),'wasm_download_bytes':(output/'index.wasm.bin').stat().st_size}
 (output/'release.json').write_text(json.dumps(release,indent=2)+'\n')
 for file in output.iterdir():
  if file.is_file() and file.stat().st_size>25*1024*1024:raise SystemExit(f'{file.name} exceeds Cloudflare25MiB asset limit.')
 (output/'SHA256SUMS').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in sorted(output.iterdir()) if p.is_file()))
 print(json.dumps({'version':version,'output':str(output),'pack_parts':len(parts),'download_mib':round(sum(p.stat().st_size for p in output.iterdir() if p.is_file())/2**20,2)}))
 return output

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--output');args=parser.parse_args();build(args.output)
