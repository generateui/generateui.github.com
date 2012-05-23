#import('dart:html');
//#source('Comments.tmpl');
#source('DComment.dart');

class Drop {
  Drop() {
    window.on.hashChange.add((e) => loadFromHash());
    loadFromHash();
  }

  void loadFromHash() {
    if (window.location.hash == "") {
      showPage("welcome");
    } else {
      List<String> splitted = window.location.hash.split("/");
      String section = splitted[0].substring(1);
      if (splitted.length == 2) {
        showPage("${section}/${splitted[1]}");
      } else {
        showPage("${section}");
      }
    }
  }

  showPage(String relativeUri) {
    XMLHttpRequest req = new XMLHttpRequest.get("${relativeUri}.html", (oh) {
      print(oh.status);
      document.query("#content").innerHTML = oh.responseText;
    });
    req.on.error.add((er) => showError()); // does not seem to work :(
  }
  showError() {
    Element error = document.query("#error");
    error.style.display = "block";
    document.query("#content").innerHTML = error.innerHTML;
  }
}

void main() {
  new Drop();
}