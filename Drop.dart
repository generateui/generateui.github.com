#import('dart:html');
#import('dart:json');

class Drop {
  String oldSection;
  String oldPage;

  Drop() {
    window.on.hashChange.add((e) => loadFromHash());
    loadFromHash();
  }

  loadFromHash() {
    if (window.location.hash == "") {
      showPage("welcome", null);
    } else {
      List<String> splitted = window.location.hash.split("/");
      String section = splitted[0].substring(1);
      String uri = null;
      if (splitted.length == 2) {
        String page = splitted[1];
        String hash = hashFromUri(page);
        uri = "${section}/${page}";
        showPage(uriWithoutHash(uri), hash);
        if (oldPage != page && oldSection != section) {
          showMetaPage(uri);
        }
        oldPage = page;
      } else {
        uri = "${section}";
        String hash = hashFromUri(section);
        showPage(uriWithoutHash(uri), hash);
        if (section != oldSection) {
          showMetaPage(uri);
        }
      }
      oldSection=section;
    }
  }

  void changeHash(String hash) {
    String loc;
    if (uriHasHash(window.location.toString())) {
      loc = window.location.toString();
      int pos = loc.lastIndexOf("hash=");
      loc = loc.substring(0, pos+5);
      loc = "${loc}${hash}";
    } else {
      loc = "${window.location.toString()}?hash=${hash}";
    }
    window.location.assign(loc);
  }

  bool uriHasHash(String uri) {
    return uri.contains("hash=");
  }

  String hashFromUri(String uri) {
    List<String> splitted = uri.split("hash=");
    if (splitted.length == 2) {
      return splitted[1];
    } else {
      return null;
    }
  }

  String uriWithoutHash(String page) {
    if (uriHasHash(page)) {
      List<String> splitted = page.split("hash=");
      if (splitted[0].endsWith("?")) {
        return splitted[0].substring(0, splitted[0].length-2);
      } else {
        return splitted[0];
      }
    } else {
      return page;
    }
  }

  showPage(String relativeUri, String hash) {
    if (hash == null) {
      XMLHttpRequest req = new XMLHttpRequest.get("${relativeUri}.html", (oh) {
        print(oh.status);
        document.query("#content").innerHTML = oh.responseText;
      });
      req.on.error.add((er) => showError()); // does not seem to work :(
    } else { // Get versioned contents
      https://raw.github.com/generateui/generateui.github.com/6b855a0983dfbb0253b16ef2e77249f03f52949b/about.html
      String uri = "https://raw.github.com/generateui/generateui.github.com";
      XMLHttpRequest req = new XMLHttpRequest.get("${uri}/${hash}/${relativeUri}.html", (oh) {
        print(oh.status);
        document.query("#content").innerHTML = oh.responseText;
      });
    }
  }

  showError() {
    Element error = document.query("#error");
    error.style.display = "block";
    document.query("#content").innerHTML = error.innerHTML;
  }
  showMetaPage(String relativeUri) {
    String ghuri = "https://api.github.com";
    String metareq = "/repos/generateui/generateui.github.com/commits?path=${relativeUri}.html";
    XMLHttpRequest req = new XMLHttpRequest.get("${ghuri}${metareq}", (oh) {
      List data = JSON.parse(oh.responseText);
      StringBuffer sb = new StringBuffer();
      for (var d in data) {
        sb.add("""<h4>${escape(d["commit"]["message"])}</h4>""");
        String sdate = d["commit"]["author"]["date"];
        sdate = sdate.substring(0, 10);
        Date date = new Date.fromString(sdate);
        int daysago = new Date.now().difference(date).inDays;
        String durationString = "";
        if (daysago == 0) {
          durationString = "Today";
        } else if (daysago == 1) {
          durationString = "1 day ago";
        } else {
          durationString = "${daysago} days ago";
        }
        sb.add("<p><span>${durationString}, </span>");
        String hashString = d["sha"];
        String shortHashString = hashString.substring(0,10);
        sb.add("<samp class=hash id=${hashString}>${shortHashString}</samp></p><hr>");
      }
      Element mcchanges = document.query("#metacontent-changes");
      mcchanges.innerHTML = sb.toString();

      mcchanges = document.query("#metacontent-changes");

      for (Element se in mcchanges.queryAll(".hash")) {
        se.on.mouseOver.add((e) {
          changeHash(se.id);
        });
      }

      StringBuffer sb2 = new StringBuffer();
      sb.add("<span>Last edited ${data[0]["committer"]["date"]}</span>");
      document.query("#metacontent-summary").innerHTML = sb2.toString();
    });
  }
  String escape(String html) {
    String result = html.replaceAll("&", "&amp;");
    result = result.replaceAll("<", "&lt;");
    result = result.replaceAll(">", "&gt;");
    return result;
  }
}

void main() {
  new Drop();
}