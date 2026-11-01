const zod = require('zod');
const dotenv = require('dotenv');

dotenv.config();

const envSchema = zod.object({
  PORT: zod.string().default('8181'),
  NODE_ENV: zod.enum(['development', 'production', 'test']).default('development'),
  MONGODB_URI: zod.string().url(),
  API_PREFIX: zod.string().default('/api/v1'),
  N8N_WEBHOOK_URL: zod.string().url().optional(),
  AUTOMATION_SERVICE_TOKEN: zod.string().min(1).optional(),
  AUTOMATION_SERVICE_SCOPES: zod.string().min(1).optional(),
  AUTOMATION_OWNER_ID: zod.string().min(1).optional(),
  AUTOMATION_SERVICE_TOKEN_EXPIRES_AT: zod.string().datetime().optional(),
  JWT_SECRET: zod.string(),
  JWT_EXPIRES_IN: zod.string().default('30d'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', parsed.error.format());
  process.exit(1);
}

module.exports = parsed.data;
