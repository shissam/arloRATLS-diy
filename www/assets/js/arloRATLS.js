const weekday = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];

var currentPage = libraryDate("");

function libraryDate(pick) { 
  d = (pick == "" ? new Date() : new Date(pick))

  return d.getFullYear() + 
    "-" + ((d.getMonth()+1) < 10 ? '0' : '') + (d.getMonth()+1) + 
    "-" + ((d.getDate()) < 10 ? '0' : '') + (d.getDate());
}

function convertDateForIos(date) {
    var arr = date.split(/[- :]/);
    date = new Date(arr[0], arr[1]-1, arr[2], arr[3], arr[4], arr[5]);
    return date;
}

function dowOn(aDate) {
  let d = convertDateForIos(aDate + " 00:00:00");
  return weekday[d.getDay()];
}

function decrDate() {
  let d = convertDateForIos(document.getElementById('libDate').value + " 00:00:00");
  d.setDate(d.getDate() - 1);
  currentPage = libraryDate (d.toString());
  loadLibraryPage(currentPage);
}

function incrDate() {
  let d = convertDateForIos(document.getElementById('libDate').value + " 00:00:00");
  d.setDate(d.getDate() + 1);
  currentPage = libraryDate (d.toString());
  loadLibraryPage(currentPage);
}

function dateExtend() {
  currentPage = document.getElementById('libDate').value;
  loadLibraryPage(currentPage);
}

function playVideo(did,vid) {

  var element = document.getElementById(did);
  element.innerHTML = 
'<video class="video_player" width="100%" controls autoplay playsinline> \
	<source src="' + vid + '" type="video/mp4"  /><!-- Safari / iOS, IE9 --> \n \
	<source src="https://clips.vorwaerts-gmbh.de/VfE.webm"      type="video/webm" /><!-- Chrome10+, Ffx4+, Opera10.6+ --> \n \
	<source src="https://clips.vorwaerts-gmbh.de/VfE.ogv"       type="video/ogg"  /><!-- Firefox3.6+ / Opera 10.5+ --> \n \
</video>'
}

function loadLibraryPage(pgDate) {
  var xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function() {
    if (this.readyState == 4) {
      document.getElementById("libDate").value = pgDate;
      document.getElementById("dow").innerHTML = dowOn(pgDate);
      if (this.status == 200) {
        document.getElementById("libView").innerHTML = this.responseText;
        document.body.scrollTop = 0;
        document.documentElement.scrollTop = 0;
      } else if (this.status == 404) {
        document.getElementById("libView").innerHTML = '<div style="display: table-row;"> <div style="width: 75%; display: table-cell;border: 5px outset white;"> <a href="#testPattern"></a><p id="testPattern"><img width="100%" src="assets/diyTEST.jpg" alt="No Videos Here">&nbsp;</img></p> </div> <div style="display: table-cell;border: 5px outset black; vertical-align: top; padding: 15px;"> <p style="font-size:30px;">No Videos</p> <p style="font-size:30px;">00:00</p> <p style="font-size:30px;">00:00</p> </div> </div>';
      }
    }
  };
  pg = "library/" + pgDate + "/lib" + pgDate + ".txt";
  xhttp.open("GET", pg, true);
  xhttp.send();
}

