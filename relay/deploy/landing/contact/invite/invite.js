// Minimal static helper for the /contact/invite landing page.
//
// The page is served by the relay's reverse-proxy vhost on the same sub-domain
// as the relay (e.g. https://sync.example.tld/contact/invite?v=1&c=...). The
// invitation payload is contained entirely in the query string and is NEVER
// transmitted to the server: this script rewrites the "Open in app" link and
// the displayed copy-paste link from `window.location.search` on the client.
(function () {
  'use strict';

  var search = window.location.search || '';

  // Only forward query strings that look like an invitation payload, so we
  // don't trick anyone into opening arbitrary deep links through this page.
  var params = new URLSearchParams(search);
  var version = params.get('v');
  var payload = params.get('c');

  if (!version || !payload) {
    return;
  }

  var canonicalSearch = '?v=' + encodeURIComponent(version) +
    '&c=' + encodeURIComponent(payload);

  var deepLink = 'compartarenta://contact/invite' + canonicalSearch;

  var openButton = document.getElementById('open-app');
  if (openButton) {
    openButton.setAttribute('href', deepLink);
  }

  var linkBox = document.getElementById('link-box');
  if (linkBox) {
    linkBox.textContent = deepLink;
  }
})();
