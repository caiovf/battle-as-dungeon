extends RefCounted
## Ajustes para o navegador no celular: tela cheia, trava em paisagem e áreas seguras (notch).
## Fora do navegador tudo aqui é ignorado.

const JS_SETUP := """
(function(){
  if (window.__mr) return;
  var st = {wantFs: false, auto: true};
  window.__mr = st;
  var d = document, el = d.documentElement;
  function fsOn(){ return !!(d.fullscreenElement || d.webkitFullscreenElement); }
  function canFs(){ return !!(d.fullscreenEnabled || d.webkitFullscreenEnabled); }
  function lock(){ try { if (screen.orientation && screen.orientation.lock) screen.orientation.lock('landscape').catch(function(){}); } catch(e){} }
  function enter(){
    if (fsOn() || !canFs()) { lock(); return; }
    var p = el.requestFullscreen ? el.requestFullscreen({navigationUI: 'hide'}) : (el.webkitRequestFullscreen ? el.webkitRequestFullscreen() : null);
    if (p && p.then) p.then(lock).catch(function(){}); else lock();
  }
  function exit(){
    if (d.exitFullscreen) d.exitFullscreen().catch(function(){}); else if (d.webkitExitFullscreen) d.webkitExitFullscreen();
  }
  // o navegador só aceita tela cheia dentro de um toque: o pedido feito pelo jogo é cumprido no próximo toque
  function onTouch(){
    if (st.wantFs === 'off') { st.wantFs = false; exit(); return; }
    if (st.wantFs || (st.auto && isMobile())) { st.wantFs = false; st.auto = false; enter(); }
  }
  function isMobile(){ return /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) || (navigator.maxTouchPoints > 1 && /Macintosh/.test(navigator.userAgent)); }
  d.addEventListener('touchend', onTouch, true);
  d.addEventListener('pointerup', onTouch, true);
  d.addEventListener('click', onTouch, true);
  st.request = function(){ st.wantFs = true; enter(); };
  st.leave = function(){ st.wantFs = 'off'; exit(); };
  st.fsOn = fsOn;
  st.canFs = canFs;
  st.isMobile = isMobile;
  st.isIOS = function(){ return /iPhone|iPad|iPod/i.test(navigator.userAgent) || (navigator.maxTouchPoints > 1 && /Macintosh/.test(navigator.userAgent)); };
  st.standalone = function(){ return !!(window.navigator.standalone || (window.matchMedia && matchMedia('(display-mode: fullscreen), (display-mode: standalone)').matches)); };
  // áreas seguras (notch do iPhone deitado)
  var probe = d.createElement('div');
  probe.style.cssText = 'position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;padding-left:env(safe-area-inset-left);padding-right:env(safe-area-inset-right);padding-bottom:env(safe-area-inset-bottom)';
  d.body.appendChild(probe);
  st.safe = function(){
    var cs = getComputedStyle(probe);
    return [parseFloat(cs.paddingLeft) || 0, parseFloat(cs.paddingRight) || 0, parseFloat(cs.paddingBottom) || 0, window.innerWidth || 1];
  };
})();
"""


static func on() -> bool:
	return OS.has_feature("web")


static func setup() -> void:
	if on():
		JavaScriptBridge.eval(JS_SETUP, true)


static func _q(expr: String, def = null):
	if not on():
		return def
	var v = JavaScriptBridge.eval("(function(){try{return %s}catch(e){return null}})()" % expr, true)
	return def if v == null else v


static func is_mobile() -> bool:
	if on():
		return bool(_q("window.__mr && window.__mr.isMobile()", false))
	return OS.has_feature("mobile")


static func is_ios() -> bool:
	return bool(_q("window.__mr && window.__mr.isIOS()", false))


static func can_fullscreen() -> bool:
	return bool(_q("window.__mr && window.__mr.canFs()", false))


static func is_fullscreen() -> bool:
	return bool(_q("window.__mr && (window.__mr.fsOn() || window.__mr.standalone())", false))


static func request_fullscreen() -> void:
	_q("window.__mr && window.__mr.request()")


static func leave_fullscreen() -> void:
	_q("window.__mr && window.__mr.leave()")


## Margens seguras em pixels da tela do jogo: [esquerda, direita, baixo].
static func safe_insets(view_w: float) -> Array:
	var v = _q("window.__mr ? window.__mr.safe().join(',') : ''", "")
	if str(v) == "":
		return [0.0, 0.0, 0.0]
	var p = str(v).split(",")
	if p.size() < 4:
		return [0.0, 0.0, 0.0]
	var k = view_w / maxf(1.0, float(p[3]))
	return [float(p[0]) * k, float(p[1]) * k, float(p[2]) * k]
