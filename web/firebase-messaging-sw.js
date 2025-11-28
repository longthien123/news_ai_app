// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBNmCIhulpe03hvzkw6KBJ0NdhUHR9PF_s",
  authDomain: "news-ai-f53f7.firebaseapp.com",
  projectId: "news-ai-f53f7",
  storageBucket: "news-ai-f53f7.firebasestorage.app",
  messagingSenderId: "656068145943",
  appId: "1:656068145943:web:66d4a3d9c6a2dc09c6ebe8",
  measurementId: "G-MS7Y47YL0K"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
