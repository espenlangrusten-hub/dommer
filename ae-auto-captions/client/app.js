const $ = (id) => document.getElementById(id);

const state = {
  layer: null,
  words: null, // flat word list from the API, offset into comp time
};

// --- persist API key locally -------------------------------------------------

$('apiKey').value = localStorage.getItem('autocaptions_openai_key') || '';
$('apiKey').addEventListener('change', () => {
  localStorage.setItem('autocaptions_openai_key', $('apiKey').value.trim());
});

function setStatus(msg, isError) {
  const el = $('status');
  el.textContent = msg || '';
  el.style.color = isError ? '#ff6b6b' : '#ffb454';
}

// --- step 1: grab the selected layer from After Effects ---------------------

$('useLayerBtn').addEventListener('click', async () => {
  setStatus('Reading selected layer...');
  try {
    const info = await callHost('getSelectedLayerInfo');
    state.layer = info;
    $('layerInfo').textContent =
      `Comp: ${info.compName}\nLayer: ${info.layerName}\nSource: ${info.filePath}`;
    $('transcribeBtn').disabled = false;
    setStatus('Layer ready.');
  } catch (e) {
    state.layer = null;
    $('transcribeBtn').disabled = true;
    $('layerInfo').textContent = '';
    setStatus(e.message, true);
  }
});

// --- step 2: transcribe with word-level timestamps ---------------------------

$('transcribeBtn').addEventListener('click', async () => {
  if (!state.layer) return;
  const apiKey = $('apiKey').value.trim();
  if (!apiKey) {
    setStatus('Enter your OpenAI API key first.', true);
    return;
  }

  $('transcribeBtn').disabled = true;
  setStatus('Uploading audio and transcribing... this can take a while for longer clips.');

  try {
    const language = $('language').value.trim() || undefined;
    const result = await transcribeAudio(state.layer.filePath, apiKey, language);

    const rawWords = result.words || [];
    if (rawWords.length === 0) {
      throw new Error('No speech detected in this clip.');
    }

    // Offset from "seconds into the file" to "seconds on the comp timeline".
    const offset = state.layer.layerStartTime;
    state.words = rawWords.map((w) => ({
      word: w.word.trim(),
      start: w.start + offset,
      end: w.end + offset,
    })).filter((w) => w.word.length > 0);

    renderPreview(state.words);
    $('previewSection').style.display = 'block';
    setStatus(`Transcribed ${state.words.length} words.`);
  } catch (e) {
    setStatus(e.message, true);
  } finally {
    $('transcribeBtn').disabled = false;
  }
});

function renderPreview(words) {
  $('transcript').textContent = words.map((w) => w.word).join(' ');
}

// --- step 3: build caption groups and hand them to the host script ----------

$('applyBtn').addEventListener('click', async () => {
  if (!state.words) return;
  $('applyBtn').disabled = true;
  setStatus('Creating text layers in After Effects...');

  try {
    const mode = $('mode').value;
    const groups = mode === 'word' ? groupByWord(state.words) : groupByPhrase(state.words);

    const payload = {
      compId: state.layer.compId,
      groups,
      options: {
        fontSize: parseInt($('fontSize').value, 10) || 60,
        position: $('position').value,
        fontFamily: 'Arial-BoldMT',
        fillColor: '#FFFFFF',
        stroke: true,
      },
    };

    const result = await callHost('createCaptions', payload);
    setStatus(`Done — created ${result.count} caption layer(s).`);
  } catch (e) {
    setStatus(e.message, true);
  } finally {
    $('applyBtn').disabled = false;
  }
});

function groupByWord(words) {
  return words.map((w) => ({ start: w.start, end: w.end, words: [w] }));
}

function groupByPhrase(words) {
  const MAX_WORDS = 6;
  const GAP_THRESHOLD = 0.6; // seconds of silence that force a new phrase
  const groups = [];
  let current = [];

  for (const w of words) {
    const prev = current[current.length - 1];
    if (current.length > 0 && (current.length >= MAX_WORDS || w.start - prev.end > GAP_THRESHOLD)) {
      groups.push(current);
      current = [];
    }
    current.push(w);
  }
  if (current.length > 0) groups.push(current);

  return groups.map((words) => ({
    start: words[0].start,
    end: words[words.length - 1].end,
    words,
  }));
}

// --- OpenAI Whisper API call (Node.js, available via CEP's mixed context) ---

function transcribeAudio(filePath, apiKey, language) {
  return new Promise((resolve, reject) => {
    const fs = require('fs');
    const https = require('https');
    const path = require('path');

    let fileBuffer;
    try {
      fileBuffer = fs.readFileSync(filePath);
    } catch (e) {
      reject(new Error(`Could not read source file: ${filePath}`));
      return;
    }

    const MAX_BYTES = 25 * 1024 * 1024;
    if (fileBuffer.length > MAX_BYTES) {
      reject(new Error('Source file is over the 25MB Whisper API limit. Trim or compress the clip first.'));
      return;
    }

    const fileName = path.basename(filePath);
    const ext = path.extname(fileName).toLowerCase().replace('.', '');
    const mimeMap = {
      mp3: 'audio/mpeg', mp4: 'video/mp4', mpeg: 'video/mpeg', mpga: 'audio/mpeg',
      m4a: 'audio/mp4', wav: 'audio/wav', webm: 'video/webm', mov: 'video/quicktime',
    };
    const mime = mimeMap[ext];
    if (!mime) {
      reject(new Error(`Unsupported source format ".${ext}". Use mp3, mp4, mov, m4a, wav or webm.`));
      return;
    }

    const boundary = '----AutoCaptionsBoundary' + Date.now();
    const fields = [
      { name: 'model', value: 'whisper-1' },
      { name: 'response_format', value: 'verbose_json' },
      { name: 'timestamp_granularities[]', value: 'word' },
    ];
    if (language) fields.push({ name: 'language', value: language });

    const parts = [];
    for (const f of fields) {
      parts.push(Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="${f.name}"\r\n\r\n${f.value}\r\n`
      ));
    }
    parts.push(Buffer.from(
      `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
      `Content-Type: ${mime}\r\n\r\n`
    ));
    parts.push(fileBuffer);
    parts.push(Buffer.from(`\r\n--${boundary}--\r\n`));
    const body = Buffer.concat(parts);

    const req = https.request({
      hostname: 'api.openai.com',
      path: '/v1/audio/transcriptions',
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Content-Length': body.length,
      },
    }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString('utf8');
        if (res.statusCode !== 200) {
          reject(new Error(`OpenAI API error (${res.statusCode}): ${text}`));
          return;
        }
        try {
          resolve(JSON.parse(text));
        } catch (e) {
          reject(new Error('Could not parse response from OpenAI.'));
        }
      });
    });

    req.on('error', (e) => reject(new Error(`Network error: ${e.message}`)));
    req.write(body);
    req.end();
  });
}
