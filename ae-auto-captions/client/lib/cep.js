// Minimal bridge to the CEP host, talking directly to the native
// window.__adobe_cep__ object instead of pulling in Adobe's full
// CSInterface.js (which this extension doesn't otherwise need).

function evalScript(script) {
  return new Promise((resolve, reject) => {
    if (!window.__adobe_cep__) {
      reject(new Error('Not running inside a CEP host (After Effects).'));
      return;
    }
    window.__adobe_cep__.evalScript(script, (result) => {
      if (typeof result === 'string' && result.indexOf('EvalScript error') === 0) {
        reject(new Error(result));
        return;
      }
      resolve(result);
    });
  });
}

async function callHost(fnName, ...args) {
  const argList = args.map((a) => JSON.stringify(a)).join(', ');
  const raw = await evalScript(`${fnName}(${argList})`);
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (e) {
    throw new Error(`Could not parse response from After Effects: ${raw}`);
  }
  if (parsed && parsed.error) {
    throw new Error(parsed.error);
  }
  return parsed;
}
