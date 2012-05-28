#import('dart:html');
#import('dart:json');

/** Location hash is the # in the URI bar of the browser, while the git version
is represented by a hash */
class Drop {
  String oldSection;
  String oldPage;
  String oldVersion;
  static String versionParameter = "version=";

  Drop() {
    // Change the page when the location's hash has changed
    window.on.hashChange.add((e) => loadFromHash());
    window.on.message.add(renderVersionedPage, false);
    window.location.assign("${window.location.toString()}#welcome");
  }

  loadFromHash() {
    List<String> splitted = window.location.hash.split("/");
    String section = splitted[0].substring(1);
    String uri = null;
    if (splitted.length == 2) { // Section and a page
      String page = splitted[1];
      String version = null;
      version = versionFromUri(page);
      uri = "${section}/${page}";
      showPage(uriWithoutVersion(uri), version);
      if (oldPage != page && oldSection != section) { // only change metapage if actual page changed
        showMetaPage(uri);
      }
      oldPage = page;
      oldSection = section;
      oldVersion = version;
    } else { // A page at the root only
      String version = versionFromUri(section);
      section = uriWithoutVersion(section);
      showPage(section, version);
      if (section != oldSection) {
        showMetaPage(section);
      }
      oldSection = section;
      oldVersion = version;
    }
  }

  void changeVersion(String version) {
    String newLocation;
    if (uriHasVersion(window.location.toString())) {
      newLocation = window.location.toString();
      int pos = newLocation.lastIndexOf(versionParameter);
      newLocation = newLocation.substring(0, pos+versionParameter.length);
      newLocation = "${newLocation}${version}";
    } else {
      newLocation = "${window.location.toString()}?${versionParameter}${version}";
    }
    window.location.assign(newLocation);
  }

  bool uriHasVersion(String uri) {
    return uri.contains(versionParameter);
  }

  String versionFromUri(String uri) {
    if (uriHasVersion(uri)) {
      List<String> splitted = uri.split(versionParameter);
      if (splitted.length == 2) {
        return splitted[1].substring(0, 40);
      } else {
        return null;
      }
    } else {
        return null;
    }
  }

  String uriWithoutVersion(String page) {
    if (uriHasVersion(page)) {
      List<String> splitted = page.split(versionParameter);
      if (splitted[0].endsWith("?")) {
        return splitted[0].substring(0, splitted[0].length-1);
      } else {
        return splitted[0];
      }
    } else {
      return page;
    }
  }

  showPage(String relativeUri, String hash) {
    if (hash == null) { // No hash, assume latest version
      print(relativeUri);
      XMLHttpRequest req = new XMLHttpRequest.get("${relativeUri}.html", (oh) {
        document.query("#content").innerHTML = oh.responseText;
      });
      req.on.error.add(showError); // does not seem to work :(
    } else { // Get versioned contents
      String ghuri = "https://api.github.com";
      String metareq = "repos/generateui/generateui.github.com/git/trees/${hash}";

      XMLHttpRequest req = new XMLHttpRequest.get("${ghuri}/${metareq}?recursive=1", (oh) {
        String sha=null;
        Map data = JSON.parse(oh.responseText);
        for (var item in data["tree"]) {
          if (item["path"] == "${relativeUri}.html") {
            sha = item["sha"];
          }
        }
        String blobreq = "repos/generateui/generateui.github.com/git/blobs/";
        XMLHttpRequest breq = new XMLHttpRequest.get("${ghuri}/${blobreq}${sha}", (oh2) {
          Map data2 = JSON.parse(oh2.responseText);
          String x = decode(data2["content"]);
          document.query("#content").innerHTML = x;
        });
      });

    }
  }

  showError(e) {
    Element error = document.query("#error");
    error.style.display = "block";
    document.query("#content").innerHTML = error.innerHTML;
  }

  renderVersionedPage(MessageEvent e) {
    var data = JSON.parse(e.data);
    document.query("#content").innerHTML = data;//["data"];
  }

  showMetaPage(String relativeUri) {
    String ghuri = "https://api.github.com";
    String metareq = "/repos/generateui/generateui.github.com/commits?path=${relativeUri}.html";
    XMLHttpRequest req = new XMLHttpRequest.get("${ghuri}${metareq}", (oh) {
      List data = JSON.parse(oh.responseText);
      StringBuffer sb = new StringBuffer();
      sb.add("<ol>");
      for (var d in data) {
        sb.add("""<li class=meta><span class=meta-change-message>${escape(d["commit"]["message"])}</span>""");
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
        sb.add("<p class=meta><span class=meta>${durationString}, </span>");
        String hashString = d["sha"];
        String shortHashString = hashString.substring(0,10);
        sb.add("""<samp class="hash meta" id=${hashString}>${shortHashString}</samp></p></li>""");
      }
      sb.add("</ol>");
      Element mcchanges = document.query("#metacontent-changes");
      mcchanges.innerHTML = sb.toString();

      mcchanges = document.query("#metacontent-changes");

      for (Element se in mcchanges.queryAll("li.meta")) {
        se.on.mouseOver.add((e) {
          String id = se.query(".hash").id;
          changeVersion(id);
        });
      }

      StringBuffer sb2 = new StringBuffer();
      //sb.add("<span>Last edited ${data[0]["committer"]["date"]}</span>");
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

/** Base64 transfer decoding for MIME (RFC 2045). */
String decode(String data) {
  List<int> result = new List<int>();
  int padCount = 0;
  int charCount = 0;
  int value = 0;
  for (int i = 0; i < data.length; i++) {
    int char = data.charCodeAt(i);
    if (65 <= char && char <= 90) {  // "A" - "Z".
      value = (value << 6) | char - 65;
      charCount++;
    } else if (97 <= char && char <= 122) { // "a" - "z".
      value = (value << 6) | char - 97 + 26;
      charCount++;
    } else if (48 <= char && char <= 57) {  // "0" - "9".
      value = (value << 6) | char - 48 + 52;
      charCount++;
    } else if (char == 43) {  // "+".
      value = (value << 6) | 62;
      charCount++;
    } else if (char == 47) {  // "/".
      value = (value << 6) | 63;
      charCount++;
    } else if (char == 61) {  // "=".
      value = (value << 6);
      charCount++;
      padCount++;
    }
    if (charCount == 4) {
      result.add((value & 0xFF0000) >> 16);
      if (padCount < 2) {
        result.add((value & 0xFF00) >> 8);
      }
      if (padCount == 0) {
        result.add(value & 0xFF);
      }
      charCount = 0;
      value = 0;
    }
  }
  return new String.fromCharCodes(result);
}

void main() {
  new Drop();
}