import { useEffect, useRef } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchReminders } from '../store/slices/reminderSlice';
import api from '../api/axios';

const LOOK_AHEAD_MS = 60_000;   // fire within 1 minute of due time
const LOOK_BACK_MS  = 60_000;   // don't fire for reminders >1 min overdue (stale)
const POLL_INTERVAL = 60_000;   // check every minute
const FETCH_INTERVAL = 5 * 60_000; // re-fetch from server every 5 min

function requestPermission() {
  if (!('Notification' in window)) return;
  if (Notification.permission === 'default') Notification.requestPermission();
}

function fireNotification(reminder) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  const n = new Notification(`⏰ ${reminder.title}`, {
    body: reminder.note || `Tap to view your reminder`,
    icon: '/favicon.ico',
    badge: '/favicon.ico',
    tag: reminder.id, // deduplicates: same tag replaces previous
  });
  // Auto-close after 8 seconds
  setTimeout(() => n.close(), 8000);
}

function isDueNow(n, now) {
  const scheduled = new Date(n.scheduledAt);
  const { repeatType } = n;

  if (repeatType === 'none') {
    const diff = scheduled.getTime() - now;
    return diff <= LOOK_AHEAD_MS && diff >= -LOOK_BACK_MS;
  }

  const cur = new Date(now);
  const hh = scheduled.getHours();
  const mm = scheduled.getMinutes();
  const dayOfWeek = scheduled.getDay();
  const dayOfMonth = scheduled.getDate();

  const withinMinute = cur.getHours() === hh && cur.getMinutes() === mm;

  if (repeatType === 'daily') return withinMinute;
  if (repeatType === 'weekly') return cur.getDay() === dayOfWeek && withinMinute;
  if (repeatType === 'monthly') return cur.getDate() === dayOfMonth && withinMinute;
  return false;
}

function fireAdminNotification(n) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;
  const notif = new Notification(`📢 ${n.title}`, {
    body: n.note || 'Message from BuxBux',
    icon: '/favicon.ico',
    tag: `admin_${n.id}`,
  });
  setTimeout(() => notif.close(), 10000);
}

export default function useReminderNotifications() {
  const dispatch = useDispatch();
  const { reminders } = useSelector((s) => s.reminders);
  const notifiedIds = useRef(new Set());
  const adminNotifiedIds = useRef(new Set());

  // Ask for permission once on mount
  useEffect(() => { requestPermission(); }, []);

  // Check due user reminders every minute
  useEffect(() => {
    const check = () => {
      if (Notification.permission !== 'granted') return;
      const now = Date.now();
      reminders.forEach((r) => {
        if (r.isCompleted || notifiedIds.current.has(r.id)) return;
        const due = new Date(r.reminderDate).getTime();
        const diff = due - now;
        if (diff <= LOOK_AHEAD_MS && diff >= -LOOK_BACK_MS) {
          notifiedIds.current.add(r.id);
          fireNotification(r);
        }
      });
    };

    check();
    const id = setInterval(check, POLL_INTERVAL);
    return () => clearInterval(id);
  }, [reminders]);

  // Poll admin notifications every minute; server handles one-time mark-as-read
  useEffect(() => {
    const checkAdmin = async () => {
      if (Notification.permission !== 'granted') return;
      try {
        const res = await api.get('/notifications/admin');
        const now = Date.now();
        res.data.forEach((n) => {
          // One-time notifications: backend already marks them read after fetch,
          // so just show them. Repeating ones still need the timing check.
          if (n.repeatType !== 'none' && !isDueNow(n, now)) return;
          // Deduplicate within the current session
          if (adminNotifiedIds.current.has(n.id)) return;
          adminNotifiedIds.current.add(n.id);
          fireAdminNotification(n);
        });
      } catch (_) {}
    };

    checkAdmin();
    const id = setInterval(checkAdmin, POLL_INTERVAL);
    return () => clearInterval(id);
  }, []);

  // Periodically re-fetch user reminders so new ones show up
  useEffect(() => {
    const id = setInterval(() => dispatch(fetchReminders()), FETCH_INTERVAL);
    return () => clearInterval(id);
  }, [dispatch]);
}
