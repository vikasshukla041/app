// Builds data/portfolio_chart.json: mock portfolio candles for the 1D, 1W, 1M and 1Y chart views.
// Run from mock_api/: node scripts/build_portfolio_chart.js
import { writeFileSync, mkdirSync } from 'node:fs';

// Numbers fixed by the app design.
const FIRST_CLOSE = 124429.70; // 2025-09-29, one year back
const LAST_CLOSE = 142850.20; // 2026-09-28 16:40, the value on screen now
const YEAR_HIGH = 144120.00; // "High" label on the 1Y view
const PEAK_DAY = '2026-09-08';

// Money in and out is not profit; these sum to zero so the design's +18,420.50 stays true.
const CASH_FLOWS = [
  { date: '2025-12-15', amount: 2000, type: 'deposit' },
  { date: '2026-03-16', amount: 1500, type: 'deposit' },
  { date: '2026-06-15', amount: -3500, type: 'withdrawal' },
];

// Same seed, same file, so the chart never reshuffles between runs.
function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const random = mulberry32(42);
function normal() {
  const u = Math.max(random(), 1e-12);
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * random());
}
const round2 = (x) => Math.round(x * 100) / 100;
const pad = (n) => String(n).padStart(2, '0');
const isoDay = (d) => `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;

// Weekdays only: the market is shut at the weekend, so the value does not move.
const days = [];
for (let d = new Date(Date.UTC(2025, 8, 29)); d <= new Date(Date.UTC(2026, 8, 28)); d.setUTCDate(d.getUTCDate() + 1)) {
  const weekday = d.getUTCDay();
  if (weekday !== 0 && weekday !== 6) days.push(isoDay(d));
}
const n = days.length;
const indexOf = (day) => days.indexOf(day);

// Market-only value as a smooth trend, three sell-offs, a late-summer peak, and daily noise.
const dips = [
  { at: indexOf('2025-11-20'), depth: 0.055, width: 7 },
  { at: indexOf('2026-03-10'), depth: 0.065, width: 8 },
  { at: indexOf('2026-06-05'), depth: 0.045, width: 6 },
];
const peak = indexOf(PEAK_DAY);
// Noise that keeps pulling back to the trend, so it wiggles day to day but never wanders off.
const walk = [0];
for (let i = 1; i < n; i++) walk.push(walk[i - 1] * 0.9 + normal() * 0.006);
const logFirst = Math.log(FIRST_CLOSE);
const logLast = Math.log(LAST_CLOSE);
const shape = (i) => {
  let s = 0;
  for (const dip of dips) s -= dip.depth * Math.exp(-(((i - dip.at) / dip.width) ** 2));
  s += 0.008 * Math.exp(-(((i - peak) / 9) ** 2));
  return s;
};
const logMarket = [];
for (let i = 0; i < n; i++) {
  const t = i / (n - 1);
  // Pin both ends exactly: the bridge removes whatever the noise and shape add at day 0 and the last day.
  const bridge = walk[i] - t * walk[n - 1] + shape(i) - (1 - t) * shape(0) - t * shape(n - 1);
  logMarket.push(logFirst + t * (logLast - logFirst) + bridge);
}

// Account value = market value + money deposited so far.
const flowByDay = new Map(CASH_FLOWS.map((f) => [f.date, f.amount]));
let deposited = 0;
const dailyClose = days.map((day, i) => {
  deposited += flowByDay.get(day) ?? 0;
  if (i === 0) return FIRST_CLOSE;
  if (i === n - 1) return LAST_CLOSE;
  return round2(Math.exp(logMarket[i]) + deposited);
});

// Squeeze only the tops so no close gets near the design's 1Y high; the rest of the curve is untouched.
const SQUEEZE_FROM = 140000;
const TOP_CLOSE = 142900;
const highestClose = Math.max(...dailyClose.slice(1, n - 1));
if (highestClose > TOP_CLOSE) {
  const factor = (TOP_CLOSE - SQUEEZE_FROM) / (highestClose - SQUEEZE_FROM);
  for (let i = 1; i < n - 1; i++) {
    if (dailyClose[i] > SQUEEZE_FROM) dailyClose[i] = round2(SQUEEZE_FROM + (dailyClose[i] - SQUEEZE_FROM) * factor);
  }
}

// Lift the days around the peak so its close sits just under the 1Y high, making that high believable.
const PEAK_CLOSE = 143650;
const lift = PEAK_CLOSE - dailyClose[peak];
for (let i = peak - 8; i <= peak + 8; i++) {
  dailyClose[i] = round2(dailyClose[i] + lift * Math.exp(-(((i - peak) / 3.5) ** 2)));
}

// Every day is built from 5-minute bars, so the daily, hourly and 5-minute views always agree.
const MARKET_OPEN = 9 * 60;
const FULL_DAY_BARS = 102; // 09:00 to 17:30
const LAST_DAY_BARS = 92; // 09:00 to 16:40, the market is still open
function buildDay(open, close, bars) {
  const sigma = 0.00035 * open;
  const steps = [0];
  for (let k = 1; k <= bars; k++) steps.push(steps[k - 1] + normal() * sigma);
  const path = [open];
  for (let k = 1; k <= bars; k++) {
    const t = k / bars;
    path.push(open + t * (close - open) + (steps[k] - t * steps[bars]));
  }
  path[bars] = close;
  const candles = [];
  for (let k = 0; k < bars; k++) {
    const o = round2(path[k]);
    const c = round2(path[k + 1]);
    const h = round2(Math.max(o, c) + Math.abs(normal()) * sigma * 0.4);
    const l = round2(Math.min(o, c) - Math.abs(normal()) * sigma * 0.4);
    candles.push({ minute: MARKET_OPEN + k * 5, open: o, high: h, low: l, close: c });
  }
  return candles;
}

const bars = [];
for (let i = 0; i < n; i++) {
  const previous = i === 0 ? FIRST_CLOSE * 0.998 : dailyClose[i - 1];
  // Overnight gap; a deposit or withdrawal lands before the market opens.
  const open = round2(previous * (1 + Math.max(-0.0019, Math.min(0.0019, normal() * 0.0008))) + (flowByDay.get(days[i]) ?? 0));
  bars.push(buildDay(open, dailyClose[i], i === n - 1 ? LAST_DAY_BARS : FULL_DAY_BARS));
}

const summarise = (list) => ({
  open: list[0].open,
  high: Math.max(...list.map((b) => b.high)),
  low: Math.min(...list.map((b) => b.low)),
  close: list[list.length - 1].close,
});

const daily = days.map((day, i) => ({ time: day, ...summarise(bars[i]) }));

// Only one day may reach the design's 1Y high, and it reaches it exactly.
for (const candle of daily) {
  if (candle.time === PEAK_DAY) candle.high = YEAR_HIGH;
  else if (candle.high >= YEAR_HIGH) candle.high = round2(Math.max(candle.open, candle.close, YEAR_HIGH - 0.01));
}

// CEST (+02:00) covers every day that has hourly or 5-minute data.
const stamp = (day, minute) => `${day}T${pad(Math.floor(minute / 60))}:${pad(minute % 60)}:00+02:00`;

const hourly = [];
for (let i = n - 5; i < n; i++) {
  const byHour = new Map();
  for (const bar of bars[i]) {
    const hour = Math.floor(bar.minute / 60) * 60;
    if (!byHour.has(hour)) byHour.set(hour, []);
    byHour.get(hour).push(bar);
  }
  for (const [hour, list] of byHour) hourly.push({ time: stamp(days[i], hour), ...summarise(list) });
}

const intraday = bars[n - 1].map((bar) => ({
  time: stamp(days[n - 1], bar.minute),
  open: bar.open,
  high: bar.high,
  low: bar.low,
  close: bar.close,
}));

const data = {
  currency: 'EUR',
  timezone: 'Europe/Berlin',
  asOf: stamp(days[n - 1], MARKET_OPEN + LAST_DAY_BARS * 5),
  previousClose: daily[n - 2].close,
  daily,
  hourly,
  intraday,
  cashFlows: CASH_FLOWS,
};

mkdirSync(new URL('../data/', import.meta.url), { recursive: true });
writeFileSync(new URL('../data/portfolio_chart.json', import.meta.url), JSON.stringify(data, null, 2) + '\n');

// Checks, so a wrong number is caught here and never reaches the app.
const valid = (c) => c.low <= Math.min(c.open, c.close) && c.high >= Math.max(c.open, c.close);
const flowsTotal = CASH_FLOWS.reduce((sum, f) => sum + f.amount, 0);
const yearChange = round2(daily[n - 1].close - daily[0].close - flowsTotal);
const dayChange = round2(intraday[intraday.length - 1].close - data.previousClose);
const lastDayHours = hourly.filter((h) => h.time.startsWith(days[n - 1]));
const lastDayFromHours = summarise(lastDayHours);
const agree =
  lastDayFromHours.open === daily[n - 1].open &&
  lastDayFromHours.close === daily[n - 1].close &&
  intraday[0].open === daily[n - 1].open &&
  intraday[intraday.length - 1].close === daily[n - 1].close;
const yearHighDay = daily.reduce((best, c) => (c.high > best.high ? c : best));
console.log('candles           daily', daily.length, '| hourly', hourly.length, '| 5-min', intraday.length);
console.log('last close        daily', daily[n - 1].close, '| hourly', hourly[hourly.length - 1].close, '| 5-min', intraday[intraday.length - 1].close);
console.log('1Y change (market)', yearChange, `(${((yearChange / daily[0].close) * 100).toFixed(1)}%)`);
console.log('1Y high / low     ', yearHighDay.high, 'on', yearHighDay.time, '/', Math.min(...daily.map((c) => c.low)));
console.log('1D change         ', dayChange, `(${((dayChange / data.previousClose) * 100).toFixed(2)}%) vs previous close`, data.previousClose);
console.log('valid OHLC        ', [...daily, ...hourly, ...intraday].every(valid));
console.log('views agree       ', agree);
