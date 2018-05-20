/*
 * This script overwrites the XMLHttpRequest object in order to track the number of outstanding
 * requests in window.app.activeXhrRequests. It also calls the toggleWait() function that
 * displays a progress cursor when the count is more than 0 and removes the cursor when it is 0.
 * Variable "delay" is configurable in ms to prevent imediate toggling of the curson on, which 
 * would appear as flickering in the event several requests start and complete quickly in series. 
 */
window.app = {};
window.app.showActivity;
window.app.activeXhrRequests = 0;
var delay = 250;
var open = window.XMLHttpRequest.prototype.open;
var send = window.XMLHttpRequest.prototype.send;

// Check the active XHR count and set the wait
function toggleWait() {
  var waitActive = document.getElementById('waitLayer') ? true : false;
  // Active requests, wait not active, and timeout not yet set
  if(window.app.activeXhrRequests && !waitActive && !window.app.showActivity) {
      // Use a timeout to prevent flickering
      window.app.showActivity = setTimeout(function(){
        window.app.showActivity = null;
        if(window.app.activeXhrRequests > 0) {
          // Turn on the overlay
          toggleWaitOverlay(true);          
        } else {
          // Active requests finished before we rendered the wait. 
          // Call toggleWait() again to cleanup.
          toggleWait();
        }
      }, delay);
  } else if(waitActive && window.app.activeXhrRequests === 0) {
    // Cleanup the activity timer
    if(window.app.showActivity) {
      clearTimeout(window.app.showActivity);
      window.app.showActivity = null;
    }
    // Turn off the overlay
    toggleWaitOverlay(false);
  }
}

// Handles DOM functions for showing/removing the wait layer
function toggleWaitOverlay(state) {
  var wait = state ? document.createElement("div") : document.getElementById('waitLayer');
  if(state) {
    wait.id = 'waitLayer';
    wait.style.zIndex = 100;
    wait.style.width = '100%';
    wait.style.height = '100%';
    wait.style.position = 'fixed';
    wait.style.top = '0px';
    wait.style.cursor = 'progress';
    document.body.appendChild(wait);
  } else if(wait) {
    wait.remove();
  }
}

// Override XMLHttpRequest to track active XHR count
function openReplacement(method, url, async, user, password) {  
  this._url = url;
  return open.apply(this, arguments);
}

function sendReplacement(data) {  
  if(this.onreadystatechange) {
    this._onreadystatechange = this.onreadystatechange;
  }
  window.app.activeXhrRequests++;
  toggleWait();
  this.onreadystatechange = onReadyStateChangeReplacement;
  return send.apply(this, arguments);
}

function onReadyStateChangeReplacement() {  
  if(this.readyState === 4) {
    window.app.activeXhrRequests--;
    toggleWait();
  }
  if(this._onreadystatechange) {
    return this._onreadystatechange.apply(this, arguments);
  }
}

window.XMLHttpRequest.prototype.open = openReplacement;  
window.XMLHttpRequest.prototype.send = sendReplacement;