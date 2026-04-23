import { useEffect, useRef } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { fetchReminders } from '../store/slices/reminderSlice';

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

export default function useReminderNotifications() {
  const dispatch = useDispatch();
  const { reminders } = useSelector((s) => s.reminders);
  const notifiedIds = useRef(new Set());

  // Ask for permission once on mount
  useEffect(() => { requestPermission(); }, []);

  // Check due reminders every minute
  useEffect(() => {
    const check = () => {
      if (Notification.permission !== 'granted') return;
      const now = Date.now();
      reminders.forEach((r) => {
        if (r.isCompleted || notifiedIds.current.has(r.id)) return;
        const due = new Date(r.reminderDate).getTime();
        const diff = due - now;
        // Fire if due within the next 60s, or was due within the last 60s
        if (diff <= LOOK_AHEAD_MS && diff >= -LOOK_BACK_MS) {
          notifiedIds.current.add(r.id);
          fireNotification(r);
        }
      });
    };

    check(); // run immediately on reminders change
    const id = setInterval(check, POLL_INTERVAL);
    return () => clearInterval(id);
  }, [reminders]);

  // Periodically re-fetch so new reminders created elsewhere show up
  useEffect(() => {
    const id = setInterval(() => dispatch(fetchReminders()), FETCH_INTERVAL);
    return () => clearInterval(id);
  }, [dispatch]);
}
