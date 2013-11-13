
library styleproc_element;

import 'dart:html';
import 'dart:js' as djs;
import 'dart:async';

import 'package:polymer/polymer.dart';

class _CachedStyle {
  StyleElement style;
  String text;
  _CachedStyle(this.style);
}

// This should not exist and is a horrible workaround because of
// https://groups.google.com/a/dartlang.org/forum/#!topic/web-ui/AsdANftHuzQ
bool _isDart() => document.getElementsByTagName("script").where((s) => s.src.endsWith(".dart.js")).isEmpty;

abstract class StyleProcessor implements Polymer {

  String _shimShadowDomStyling(String txt) {
    if (djs.context == null) return txt;

    var platform = djs.context['Platform'];
    if (platform == null) return txt;

    var shadowCss = platform['ShadowCSS'];
    if (shadowCss == null) return txt;

    var shimShadowDOMStyling2 = shadowCss['shimShadowDOMStyling2'];
    if (shimShadowDOMStyling2 == null) return txt;

//    if (js.context.window.ShadowDOMPolyfill == null) return txt;

    return shimShadowDOMStyling2.apply(shadowCss, [txt, localName]);
  }

  Future<StyleElement> _compileStyle(String txt, [StyleElement style]) {
    if (style == null) {
      style = new StyleElement()
        ..type = "text/css"
      ;
      shadowRoot.append(style);
    }

    return compileStyleText(txt).then((css) {
      style.text = _shimShadowDomStyling(css);
      return style;
    },
    onError: (e) {
      window.console.log(e.toString());
      return style;
    });
  }

  Future<_CachedStyle> _compileStyleHTTP(Element e, [_CachedStyle cache]) {
    String path = e.attributes["src"];
    if (e.attributes.containsKey("path") && _isDart())
      path = e.attributes["path"] + "/" + path;
    return HttpRequest.getString(path).then((String text) {
      StyleElement style = null;
      if (cache != null) {
        if (cache.text == text)
          return cache;
        window.console.info("Reloading " + e.attributes["src"]);
        style = cache.style;
      }
      return _compileStyle(text + "\n" + e.text, style).then((StyleElement el) {
        if (cache == null)
          cache = new _CachedStyle(el);
        cache.text = text;
        return cache;
      });
    },
    onError: (err) {
      window.console.log("Could not load " + e.attributes["src"]);
    });
  }

  Future<dynamic> _compileStyleElement(Element e) {
    Future<_CachedStyle> ret = _compileStyleHTTP(e);

    if (e.attributes.containsKey("monitor")) {
      int period = int.parse(e.attributes["monitor"], onError: (_) => 0);
      if (period > 0)
        ret = ret.then((_CachedStyle cache) =>
            new Timer.periodic(new Duration(seconds: period), (_) => _compileStyleHTTP(e, cache))
        );
    }

    return ret;
  }

  void compileStyle() {
    ensureFoucPrevented();

    this.classes.add("styleproc-wait");

    List<Future> futures = new List();

    this.shadowRoot.querySelectorAll(styleElementName).forEach((Element e) {
      e.remove();
      Future fut;
      if (e.attributes.containsKey("src")) {
        fut = _compileStyleElement(e);
      }
      else {
        fut = _compileStyle(e.text);
      }
      futures.add(fut);
    });

    Future.wait(futures).then((e) {
      this.classes.remove("styleproc-wait");
    });
  }

  StyleElement foucStyle = null;

  void ensureFoucPrevented() {
    if (foucStyle == null) {
      foucStyle = new StyleElement()
        ..type = "text/css"
        ..text = _shimShadowDomStyling("""
            $styleElementName { display: none; }
            .styleproc-wait { display: none; }
          """)
      ;
      shadowRoot.append(foucStyle);
    }
  }

  String get styleElementName;

  Future<String> compileStyleText(String txt);
}

abstract class StyleProcessorElement extends PolymerElement with StyleProcessor {

  StyleProcessorElement.created() : super.created() {}

  void shadowRootReady(ShadowRoot root, Element template) {
    super.shadowRootReady(root, template);
    compileStyle();
  }
}
