// Background push runs here, not in Dart. Version is pinned by hand — after a
// pub upgrade, check it against firebase_core_web's supportedFirebaseJsSdkVersion.
importScripts("https://www.gstatic.com/firebasejs/12.17.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.17.0/firebase-messaging-compat.js");

// Copied from lib/firebase_options.dart, which a service worker cannot import.
// A wrong messagingSenderId here fails silently: getToken() just returns null.
firebase.initializeApp({
  apiKey: "AIzaSyDALkEOjlTnn4HoHYZxtlYYc7rLf3uoqkM",
  authDomain: "client-website-test-prod.firebaseapp.com",
  projectId: "client-website-test-prod",
  storageBucket: "client-website-test-prod.firebasestorage.app",
  messagingSenderId: "151988331110",
  appId: "1:151988331110:web:a4192fa474e8f235aac3a7",
});

// Mirrors AppRoutes. Kept in step by hand — a service worker cannot import Dart.
const DEEP_LINKABLE = ["/dashboard", "/alerts"];
const ID_IN_PATH = ["/alerts"];

/// Rejects anything that would climb out of, or add to, the named route.
function isSafeSegment(value) {
  return (
    !value.includes("/") &&
    !value.includes("?") &&
    !value.includes("#") &&
    value !== "." &&
    value !== ".."
  );
}

/// DeepLinkParser again, for web: a background tap never reaches Dart.
function locationFor(data) {
  const route = data && data.route;
  if (!route || !DEEP_LINKABLE.includes(route)) {
    return null;
  }

  const id = data.id;
  const needsId = ID_IN_PATH.includes(route);
  const idInPath = needsId && id;

  // A `<path>/:id` route names nothing without an id, so reject it here.
  if (needsId && !idInPath) {
    return null;
  }

  if (idInPath && !isSafeSegment(id)) {
    return null;
  }

  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(data)) {
    if (key === "route" || !value) continue;
    if (idInPath && key === "id") continue;
    query.append(key, value);
  }

  const path = idInPath ? `${route}/${id}` : route;
  const search = query.toString();
  // Flutter web keeps its location after '#', so the link has to go there.
  return `/#${path}${search ? `?${search}` : ""}`;
}

// Registered before firebase.messaging(): listeners fire in that order.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  // Without this the SDK's own handler also runs and opens a second tab on
  // the dashboard, which looks exactly like the deep link being ignored.
  event.stopImmediatePropagation();

  // The SDK nests the message under FCM_MSG; a data-only push arrives flat.
  const raw = event.notification.data || {};
  const data = (raw.FCM_MSG && raw.FCM_MSG.data) || raw.data || raw;

  const location = locationFor(data);
  const target = new URL(location || "/", self.location.origin).href;

  event.waitUntil(
    clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((windows) => {
        const open = windows.find((c) =>
          c.url.startsWith(self.location.origin),
        );

        if (!open) {
          return clients.openWindow(target);
        }

        // client.navigate() is not allowed: FCM registers this worker on a
        // different scope, so it never controls the page. index.html listens
        // for this message and moves itself instead.
        //
        // Posted before focus(), which rejects without user activation and
        // would otherwise skip this line entirely.
        open.postMessage({ deepLink: target });

        // Best-effort: the page already has the location, so a refused focus
        // costs the user one tab switch, not the deep link.
        return open.focus().catch(() => {});
      }),
  );
});

// Last, so the handler above wins the click. The SDK still draws the banner.
firebase.messaging();
