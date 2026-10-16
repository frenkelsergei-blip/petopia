"""Check the actual hosted release bytes before announcing a GitHub release."""
import argparse,gzip,hashlib,json,subprocess,time

def _verify_once(base,version=None,commit=None):
 base=base.rstrip('/')+'/'
 def fetch(name):return subprocess.run(['curl','--fail','--silent','--show-error',base+name],capture_output=True,check=True).stdout
 release=json.loads(fetch('release.json'))
 if version:assert release['version']==version,'Hosted version differs'
 if commit:assert release['commit']==commit,'Hosted source commit differs'
 wasm=gzip.decompress(fetch('index.wasm.bin'))
 assert wasm[:4]==b'\0asm','Hosted transport did not decode to WebAssembly'
 js=fetch('index.js')
 assert b"new DecompressionStream('gzip')" in js,'Explicit browser decoder absent'
 manifest=json.loads(fetch('game-pack.json'));digest=hashlib.sha256();total=0
 for part in manifest['parts']:
  data=fetch(part['file']);assert len(data)==part['bytes'] and len(data)<=25*1024*1024
  digest.update(data);total+=len(data)
 assert total==manifest['bytes'] and digest.hexdigest()==manifest['sha256']==release['pack_sha256'],'Hosted pack mismatch'
 print(json.dumps({'url':base,'version':release['version'],'commit':release['commit'],'wasm_decoded_bytes':len(wasm),'pack_sha256':digest.hexdigest(),'result':'PASS'}))
 return release

def verify(base,version=None,commit=None):
 # Pages reports a completed deployment before the stable alias reaches every
 # edge. Retry a bounded propagation window; never announce mismatched bytes.
 for attempt in range(6):
  try:return _verify_once(base,version,commit)
  except (AssertionError,subprocess.CalledProcessError,json.JSONDecodeError,OSError) as error:
   if attempt==5:raise
   print('Hosted release not ready: '+str(error)+'. Rechecking in3 seconds.',flush=True)
   time.sleep(3)

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('url');p.add_argument('--version');p.add_argument('--commit');a=p.parse_args();verify(a.url,a.version,a.commit)
