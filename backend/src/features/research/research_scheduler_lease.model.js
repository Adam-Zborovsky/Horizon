'use strict';

// Persistent, short-lived leadership record for the source-only daily
// scheduler. This is deliberately separate from ResearchRun: lease ownership
// is operational coordination, while runs retain the durable idempotency and
// execution state needed for recovery and audit.
const mongoose = require('mongoose');

const researchSchedulerLeaseSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  owner: { type: String, required: true, maxlength: 160 },
  expires_at: { type: Date, required: true, index: true },
}, {
  timestamps: false,
  strict: 'throw',
  collection: 'research_scheduler_leases',
});

// Expired records are eligible for takeover immediately through the CAS
// filter. Mongo's TTL monitor only reclaims them later; it is not relied on
// for correctness.
researchSchedulerLeaseSchema.index({ expires_at: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.models.ResearchSchedulerLease
  || mongoose.model('ResearchSchedulerLease', researchSchedulerLeaseSchema);
