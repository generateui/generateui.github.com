#import('dart:html');
//#source('Comments.tmpl');
#source('DComment.dart');

/** A drop for everyone in the cloud */
class Drop {

  Skeleton() {
  }

  void run() {
    final req = new XMLHttpRequest.get('article1.html', 
        (r) => document.query("#content").innerHTML = r.responseText);
  }
}

void main() {
  new Drop().run();
}