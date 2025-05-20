import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import browser from './routes/browser.ts'
import auth from './routes/auth.ts'
import classes from './routes/class.ts'

const app = new Hono();

app.route('/browser', browser);
app.route('/auth', auth);
app.route('/class', classes);

serve({
  fetch: app.fetch,
  port: 3000
}, (info) => {
  console.log(`Server is running on http://localhost:${info.port}`)
});
