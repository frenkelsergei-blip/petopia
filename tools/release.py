"""Versioned PETOPIA release: checks -> web -> Git tag -> Pages -> GitHub release.
Uses the user's existing gh/Wrangler login; stores no credentials in the project.
"""
import argparse,hashlib,json,re,shutil,subprocess
from pathlib import Path
from build_web import ROOT,build
from verify_web import verify

def run(args,capture=False):
 result=subprocess.run(args,cwd=ROOT,text=True,capture_output=capture,check=True)
 if capture: print(result.stdout);return result.stdout
 return ''

def prepare(version):
 if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-z0-9.]+)?',version):raise SystemExit('Use a semantic version such as0.1.1.')
 (ROOT/'VERSION').write_text(version+'\n')
 p=ROOT/'project.godot';p.write_text(re.sub(r'config/version="[^"]*"','config/version="'+version+'"',p.read_text()))
 notes=ROOT/'release-notes'/('v'+version+'.md')
 if not notes.exists():notes.write_text('# PETOPIA '+version+'\n\nDescribe the player-visible changes and validation before publishing.\n')
 run(['python3','tools/run_checks.py']);build()
 print('Prepared v'+version+'. Review changes, update notes, commit to main, then run: python3 tools/release.py publish')

def publish():
 version=(ROOT/'VERSION').read_text().strip();tag='v'+version
 if run(['git','status','--porcelain'],True).strip():raise SystemExit('Commit reviewed sources and validation before publishing; the release must identify a clean commit.')
 if run(['git','branch','--show-current'],True).strip()!='main':raise SystemExit('Publish from main.')
 notes=ROOT/'release-notes'/(tag+'.md')
 if not notes.is_file():raise SystemExit('Write release-notes/'+tag+'.md before publishing.')
 # Always run the complete current suites for a published version.
 run(['python3','tools/run_checks.py']);output=build()
 commit=run(['git','rev-parse','HEAD'],True).strip()
 existing=subprocess.run(['git','rev-parse','--verify','refs/tags/'+tag+'^{commit}'],cwd=ROOT,text=True,capture_output=True)
 if existing.returncode==0 and existing.stdout.strip()!=commit:raise SystemExit(tag+' already belongs to a different commit. Bump the version; release tags are immutable.')
 if existing.returncode:run(['git','tag','-a',tag,'-m','PETOPIA '+version])
 run(['git','push','origin','main']);run(['git','push','origin',tag])
 config=json.loads((ROOT/'deploy/cloudflare.json').read_text())
 deployed=run(['npx','--yes','wrangler@'+config['wrangler_version'],'pages','deploy',str(output),'--project-name',config['project'],'--branch',config['production_branch'],'--commit-hash',commit,'--commit-message','PETOPIA '+tag,'--commit-dirty=false'],True)
 links=re.findall(r'https://[a-zA-Z0-9.-]+\.pages\.dev',deployed)
 verify(config['url'],version,commit)
 folder=ROOT/'builds/releases'/tag;folder.mkdir(parents=True,exist_ok=True)
 archive=Path(shutil.make_archive(str(folder/('petopia-'+tag+'-web')),'zip',output))
 checksums=folder/'SHA256SUMS';checksums.write_text(hashlib.sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
 release_url=run(['gh','release','create',tag,str(archive),str(checksums),'--verify-tag','--prerelease','--title','PETOPIA '+version,'--notes-file',str(notes)],True).strip()
 receipt={'version':version,'tag':tag,'commit':commit,'play_url':config['url'],'deployment_url':links[-1] if links else None,'release_url':release_url,'archive':str(archive),'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
 (folder/'deployment.json').write_text(json.dumps(receipt,indent=2)+'\n')
 print(json.dumps(receipt,indent=2))

if __name__=='__main__':
 parser=argparse.ArgumentParser();sub=parser.add_subparsers(dest='action',required=True)
 p=sub.add_parser('prepare');p.add_argument('version');sub.add_parser('publish');args=parser.parse_args()
 prepare(args.version) if args.action=='prepare' else publish()
