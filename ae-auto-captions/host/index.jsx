// ExtendScript host code. Runs inside After Effects, invoked from the
// CEP panel via evalScript(). All entry points return a JSON string.

function getSelectedLayerInfo() {
  try {
    var comp = app.project.activeItem;
    if (!(comp && comp instanceof CompItem)) {
      return JSON.stringify({ error: 'Select a composition first.' });
    }
    if (comp.selectedLayers.length === 0) {
      return JSON.stringify({ error: 'Select a layer with audio/video in the composition.' });
    }
    var layer = comp.selectedLayers[0];
    if (!(layer instanceof AVLayer) || !layer.source || !(layer.source instanceof FootageItem) || !layer.source.file) {
      return JSON.stringify({ error: 'Selected layer must be footage (video or audio) with a source file on disk.' });
    }

    return JSON.stringify({
      compId: comp.id,
      compName: comp.name,
      frameRate: comp.frameRate,
      layerName: layer.name,
      layerStartTime: layer.startTime,
      filePath: layer.source.file.fsName,
    });
  } catch (e) {
    return JSON.stringify({ error: e.toString() });
  }
}

function findCompById(id) {
  for (var i = 1; i <= app.project.items.length; i++) {
    var item = app.project.items[i];
    if (item instanceof CompItem && item.id === id) return item;
  }
  return null;
}

function hexToRgb1(hex) {
  hex = hex.replace('#', '');
  return [
    parseInt(hex.substring(0, 2), 16) / 255,
    parseInt(hex.substring(2, 4), 16) / 255,
    parseInt(hex.substring(4, 6), 16) / 255,
  ];
}

// data: { compId, groups: [{ start, end, words: [{word, start, end}] }], options }
function createCaptions(data) {
  var undoStarted = false;
  try {
    var comp = findCompById(data.compId);
    if (!comp) {
      return JSON.stringify({ error: 'Composition not found — was it closed?' });
    }

    app.beginUndoGroup('Create Auto Captions');
    undoStarted = true;

    var opts = data.options || {};
    var fontSize = opts.fontSize || 60;
    var fontFamily = opts.fontFamily || 'Arial-BoldMT';
    var fillColor = hexToRgb1(opts.fillColor || '#FFFFFF');
    var position = opts.position || 'bottom';
    var useStroke = opts.stroke !== false;

    var boxWidth = comp.width * 0.9;
    var boxHeight = Math.max(fontSize * 2, 150);
    var boxX = comp.width * 0.05;
    var boxY;
    if (position === 'top') boxY = comp.height * 0.08;
    else if (position === 'center') boxY = comp.height / 2 - boxHeight / 2;
    else boxY = comp.height * 0.82 - boxHeight;

    for (var g = 0; g < data.groups.length; g++) {
      var grp = data.groups[g];
      var textLayer = comp.layers.addBoxText([boxWidth, boxHeight], '');
      textLayer.name = 'Caption ' + (g + 1) + ': ' + wordsToPreview(grp.words);
      textLayer.startTime = grp.start;
      textLayer.outPoint = grp.end + 0.05;
      textLayer.property('Transform').property('Position').setValue([boxX, boxY]);

      var textProp = textLayer.property('Source Text');
      var doc = textProp.value;
      doc.fontSize = fontSize;
      doc.font = fontFamily;
      doc.fillColor = fillColor;
      doc.justification = ParagraphJustification.CENTER_JUSTIFY;
      doc.applyFill = true;
      if (useStroke) {
        doc.applyStroke = true;
        doc.strokeColor = [0, 0, 0];
        doc.strokeWidth = Math.max(2, fontSize * 0.06);
        doc.strokeOverFill = false;
      }
      doc.text = '';
      textProp.setValue(doc);

      // Typewriter reveal: each word's characters appear one by one across
      // that word's own spoken duration, so the text is timed exactly to speech.
      var typed = '';
      for (var w = 0; w < grp.words.length; w++) {
        var word = grp.words[w];
        var chars = word.word;
        var dur = Math.max(word.end - word.start, 0.001);
        var n = chars.length;
        for (var c = 0; c < n; c++) {
          var t = word.start + (dur * (c + 1)) / n;
          var frameDoc = textProp.value;
          frameDoc.text = typed + chars.substring(0, c + 1);
          textProp.setValueAtTime(t, frameDoc);
        }
        typed += chars + (w < grp.words.length - 1 ? ' ' : '');
      }
    }

    app.endUndoGroup();
    return JSON.stringify({ success: true, count: data.groups.length });
  } catch (e) {
    if (undoStarted) {
      try { app.endUndoGroup(); } catch (e2) {}
    }
    return JSON.stringify({ error: e.toString() + (e.line ? ' (line ' + e.line + ')' : '') });
  }
}

function wordsToPreview(words) {
  var text = '';
  for (var i = 0; i < words.length && i < 4; i++) {
    text += (i > 0 ? ' ' : '') + words[i].word;
  }
  return text;
}
