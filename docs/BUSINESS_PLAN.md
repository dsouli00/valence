# VALENCE — Business Plan

*Version 1.0 — April 2026*

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Company Overview](#2-company-overview)
3. [Market Opportunity](#3-market-opportunity)
4. [Competitive Landscape](#4-competitive-landscape)
5. [Business Model & Pricing](#5-business-model--pricing)
6. [Unit Economics](#6-unit-economics)
7. [Financial Projections (3 Years)](#7-financial-projections-3-years)
8. [Operations Plan](#8-operations-plan)
9. [Team & Hiring Plan](#9-team--hiring-plan)
10. [Risk Analysis & Mitigation](#10-risk-analysis--mitigation)
11. [Funding Strategy](#11-funding-strategy)
12. [Exit Strategy](#12-exit-strategy)

---

## 1. Executive Summary

**Company:** Valence  
**Product:** B2B2C SaaS fitness coaching platform  
**Model:** Coach-pays subscription (freemium → paid); client app is free, coach pays for the seat  
**Stage:** Pre-revenue, MVP complete, beta launch imminent  
**Ask (Seed):** $400,000 to fund 18 months of runway and reach $30k MRR  

### The Opportunity in One Paragraph

There are an estimated **1.2 million fitness coaches** worldwide. The vast majority run their businesses across 5–7 fragmented tools: WhatsApp for messaging, Google Sheets for tracking, Instagram for marketing, PDF emails for plans, and Fitbit/MyFitnessPal for data they never fully see. The two dominant platforms (Trainerize and TrueCoach) were acquired by corporate giant ABC Fitness in 2021 and 2022 respectively — they have since raised prices, slowed innovation, and drifted away from the solo coach. This has opened a **massive white space** for a modern, AI-first, beautiful alternative. Valence is that alternative.

### The Business in Three Numbers

| Metric | Value |
|--------|-------|
| Target market (US + UK + AUS addressable coaches) | ~400,000 coaches |
| SOM (realistically reachable in 3 years) | 10,000 coaches |
| Revenue at 10k coaches (20% Pro + 5% Elite) | **$1.19M MRR / $14.3M ARR** |

---

## 2. Company Overview

### Mission
To be the operating system for the coach-client relationship — making fitness coaching scalable, data-driven, and human.

### Vision
A world where every fitness coach runs a thriving, data-informed business, and every client stays accountable to their goals.

### What We Build
Valence is a **dual-sided SaaS platform**:
- **Coach app:** Client roster dashboard, workout plan builder, nutrition tracking oversight, AI-powered nudges, business analytics
- **Client app:** Daily workout logging, meal photo AI analysis, water/sleep/weight tracking, streak gamification, coach feedback loop

### Business Structure
- Delaware C-Corp (standard for VC-backed SaaS)
- Headquarters: Remote-first (founder-led)
- Core markets: USA, UK, Australia, Canada (English-speaking, high-density fitness cultures)

### Traction (Pre-Launch)
- MVP fully built (Flutter + Firebase)
- Beta invite list: 80+ coaches on waitlist
- Pilot coaches confirmed: 12 coaches with real client books
- App Store presence: iOS + Android (TestFlight / internal track)

---

## 3. Market Opportunity

### Industry Context

The global health and wellness coaching market was valued at **$6.3 billion in 2023** and is projected to grow to **$10.7 billion by 2028** (CAGR 11.1%). Within that, personal fitness coaching is the largest sub-segment.

**Key drivers:**
- Post-COVID acceleration of remote/online coaching (up 312% since 2019)
- 73% of coaches report they now coach at least some clients fully online
- Consumer spending on personal training up 9.4% YoY (IHRSA 2024)
- AI adoption creating expectation of smarter tools

### Coach Market Size

| Geography | Certified Fitness Coaches | Online (addressable) |
|-----------|--------------------------|----------------------|
| United States | ~340,000 | ~170,000 |
| United Kingdom | ~65,000 | ~35,000 |
| Australia | ~45,000 | ~20,000 |
| Canada | ~30,000 | ~15,000 |
| Europe (rest) | ~200,000 | ~80,000 |
| **Total addressable (English-first)** | **~680,000** | **~320,000** |

### TAM / SAM / SOM

| Market | Definition | Size |
|--------|-----------|------|
| **TAM** (Total Addressable Market) | All fitness coaches globally willing to pay for software | $850M/year |
| **SAM** (Serviceable Addressable Market) | English-speaking online coaches (320k), ~$49 ARPU average | $188M/year |
| **SOM** (Serviceable Obtainable Market) | Realistic 3-year capture: 10,000 paid coaches | $5.9M–$14.3M ARR |

### Why Now

1. **Incumbent vacuum:** TrueCoach (acquired 2022) and Trainerize (acquired 2021) both went corporate. Coach communities on Reddit, Facebook Groups, and Discord are full of complaints about price hikes, broken features, and poor support.
2. **AI moment:** Coaches are actively asking for AI food analysis and AI-written nudge templates. No existing tool does this well.
3. **Mobile-first generation:** The next wave of coaches (Gen Z, 22–30 years old) expects an app, not a web dashboard with a clunky mobile experience.
4. **Streaks and gamification:** Consumer apps (Duolingo, Strava, Whoop) have trained clients to expect gamification. No coaching tool delivers this.

---

## 4. Competitive Landscape

### Direct Competitors

| Platform | Price | Strengths | Weaknesses | Valence Edge |
|----------|-------|-----------|-----------|--------------|
| **TrueCoach** | $19.99–$89/mo | Simple, coach-beloved brand (pre-acquisition) | Corporate-owned, stagnant, no AI, limited client experience | AI nudges, beautiful client app, streak gamification |
| **Trainerize** | $5–$250/mo | Feature-rich, integrations, large user base | Overwhelmingly complex, outdated UX, steep learning curve | 15-min onboarding vs 2-hour onboarding |
| **My PT Hub** | £25–£125/mo | UK market penetration, nutrition module | Clunky UI, limited analytics, no AI | Modern design, AI food analysis |
| **CoachRx** | $49/mo | Clean UI, growing | Workout-only, no nutrition/lifestyle tracking | Full-stack: workouts + nutrition + lifestyle in one |
| **PTminder** | $20–$30/mo | Scheduling focus, invoicing | Not a coaching tool — admin tool | Coaching-first, not admin-first |
| **Google Sheets + WhatsApp** | Free | Flexible, zero cost | Zero accountability data, no client experience | Structure + data + experience |

### Indirect Competitors (Fragmented Stack)
- **Notion** — document-based plans (no real-time logging)
- **MyFitnessPal** — nutrition only; no coach visibility
- **Strava** — activity only; no nutrition, no coach dashboard
- **Mindbody** — scheduling + payments; not a coaching intelligence tool

### Competitive Moat (Why We Win Long-Term)

1. **Network effect:** When a coach invites 15 clients, those 15 clients are now on Valence. If a client's next coach also uses Valence, they keep their history. The more coaches on platform, the stickier the client side.
2. **Data flywheel:** More logs → better AI food models → better AI nudge timing → higher adherence → better coach retention → more coaches.
3. **Brand:** Valence is positioned as the *premium* choice. TrueCoach is becoming the "budget but reliable" option. We own the premium lane.
4. **Switching cost:** A coach who has 12 weeks of client history, custom exercise library, and templates on Valence has high switching friction. Migration is painful.

### Positioning Matrix

```
            HIGH COMPLEXITY
                  |
          Trainerize
                  |
  BUDGET ---------|--------- PREMIUM
                  |          
                  |    [VALENCE]
          TrueCoach
                  |
             LOW COMPLEXITY
```

Valence owns the **Premium + Low Complexity** quadrant — currently unoccupied by a strong competitor.

---

## 5. Business Model & Pricing

### Coach-Pays SaaS (Primary Model)

The coach is the buyer. The client app is free for clients (no payment, no friction to adoption). This mirrors how Calendly works — one paying user generates multiple free users, who then become future paying users themselves when they eventually start coaching.

| Tier | Price | Client Limit | Target Segment |
|------|-------|-------------|----------------|
| **Free** | $0/mo | 5 clients | Solo coaches testing, micro-coaches |
| **Coach Pro** | $49/mo ($490/yr) | Unlimited | Scaling coaches (5–50 clients) |
| **Coach Elite** | $199/mo ($1,990/yr) | Unlimited | Gyms, teams, multi-coach orgs |

### Revenue Model Logic

- **Free tier:** Acquisition tool. Zero revenue but zero-friction entry. Target: 80% of coaches on free.
- **Pro tier:** Core revenue engine. 20% of coaches. $49 × 20% = $9.80 ARPU across total coach base.
- **Elite tier:** Upsell for established businesses. 5% of coaches. High-value, high-retention.

### Future Revenue Streams (Year 2+)

| Stream | Model | Year 2 Target |
|--------|-------|--------------|
| Client Premium ($9.99/mo) | Individual clients pay for AI meal plans, advanced progress | $30k ARR |
| Coach Marketplace | Coaches sell workout programs; Valence takes 30% | $20k ARR |
| Gym White-Label | Custom branding + multi-coach dashboard | $50k ARR |
| Data Insights (B2B) | Anonymized aggregate fitness trend reports to brands | $15k ARR |
| API Access (Elite add-on) | Integrate with gym management software | Included in Elite |

### Pricing Rationale

- **$49/mo** is strategically priced below TrueCoach's top tier ($89/mo) but above their entry point — it's the "obvious upgrade" price.
- At $49/mo, if a coach has just 10 clients paying $150/month, Valence costs them **3.3% of revenue**. This is an easy sell.
- Annual billing (10-month equivalent) reduces churn and improves cash flow. Target: 40% of Pro coaches on annual plans.

---

## 6. Unit Economics

### Customer Acquisition Cost (CAC) by Channel

| Channel | Expected CAC | Notes |
|---------|-------------|-------|
| Organic / Word of mouth | $0–$15 | Coaches refer coaches |
| Content marketing (SEO) | $30–$60 | 90-day lag; compounding returns |
| YouTube tutorials | $20–$50 | High-intent viewers |
| Instagram / TikTok influencer | $80–$150 | Fitness coach audience |
| Facebook/Instagram Ads | $120–$200 | Targeted to coaches |
| Google Ads | $80–$160 | "fitness coach software" keyword |
| Referral program | $25–$45 | Incentivized invites |
| Fitness education partnerships | $30–$70 | Certified trainer course add-ons |

**Blended CAC target (Year 1):** $75  
**Blended CAC target (Year 2, with SEO compounding):** $55

### Lifetime Value (LTV)

Assumptions:
- Monthly churn rate: 3.5% (industry benchmark for early-stage B2B SaaS: 3–5%)
- Average retention: 29 months (1 / 0.035)
- Pro tier gross margin: 91% ($49 – ~$4.50 infra/support cost = $44.50 GM)

| Tier | Monthly GM | Avg Months Retained | LTV |
|------|-----------|--------------------|----|
| Pro | $44.50 | 29 | **$1,290** |
| Elite | $185 | 36 | **$6,660** |
| Blended (weighted) | $57 | 29 | **$1,660** |

### LTV:CAC Ratio

| Scenario | LTV | CAC | LTV:CAC |
|----------|-----|-----|---------|
| Year 1 (blended) | $1,660 | $75 | **22:1** |
| Year 2 (blended) | $1,780 | $55 | **32:1** |

> Industry standard for healthy SaaS: LTV:CAC > 3:1. We're targeting 22:1 in Year 1 — primarily because our organic and content channels have near-zero CAC.

### Payback Period

- $75 CAC ÷ $44.50/month gross margin = **1.7 months payback**
- This is exceptionally fast. Most SaaS companies target < 12 months. We're at < 2 months.

### Why Unit Economics Are So Strong

1. **Coaches bring clients for free.** Every coach who signs up invites 5–20 clients. Zero acquisition cost for those clients.
2. **Low infrastructure cost.** Firebase pricing scales per usage. At 1,000 coaches with 15 clients each = 15,000 daily active users: estimated Firebase cost ~$800/month.
3. **Zero sales team required at scale.** PLG (product-led growth) — coaches sign up, get value, convert on their own.

---

## 7. Financial Projections (3 Years)

### Assumptions

- Launch: Q2 2026 (50 beta coaches, free tier only)
- First paid conversions: Month 3
- Monthly new coach signups: 200 → 500 → 1,200 by Month 18
- Free-to-Pro conversion rate: 20%
- Pro-to-Elite upgrade rate: 5% of Pro coaches
- Monthly Pro churn: 3.5%
- Monthly Elite churn: 2.0%
- Annual billing adoption: 35% of Pro, 50% of Elite

### MRR Build — Year 1

| Month | Total Coaches | Pro Coaches | Elite Coaches | MRR |
|-------|--------------|-------------|--------------|-----|
| 1 | 50 | 0 | 0 | $0 |
| 2 | 150 | 0 | 0 | $0 |
| 3 | 300 | 15 | 0 | $735 |
| 4 | 500 | 30 | 1 | $1,669 |
| 5 | 750 | 55 | 2 | $3,093 |
| 6 | 1,000 | 90 | 4 | $5,206 |
| 7 | 1,300 | 130 | 7 | $7,763 |
| 8 | 1,650 | 180 | 10 | $10,770 |
| 9 | 2,050 | 240 | 13 | $14,527 |
| 10 | 2,500 | 310 | 17 | $18,933 |
| 11 | 3,000 | 395 | 22 | $23,695 |
| 12 | 3,600 | 495 | 28 | $29,945 |

**End of Year 1: ~$30k MRR = $360k ARR**

### MRR Build — Year 2

| Quarter | Total Coaches | Pro | Elite | MRR |
|---------|--------------|-----|-------|-----|
| Q1 Y2 | 5,000 | 700 | 42 | $42,538 |
| Q2 Y2 | 7,000 | 1,000 | 62 | $61,238 |
| Q3 Y2 | 9,500 | 1,400 | 85 | $84,815 |
| Q4 Y2 | 12,000 | 1,800 | 110 | $109,270 |

**End of Year 2: ~$110k MRR = $1.3M ARR**

### MRR Build — Year 3

| Quarter | Total Coaches | Pro | Elite | MRR |
|---------|--------------|-----|-------|-----|
| Q1 Y3 | 16,000 | 2,400 | 145 | $146,255 |
| Q2 Y3 | 21,000 | 3,200 | 190 | $194,810 |
| Q3 Y3 | 27,000 | 4,100 | 240 | $249,490 |
| Q4 Y3 | 34,000 | 5,200 | 310 | $318,590 |

**End of Year 3: ~$320k MRR = $3.8M ARR**

### 3-Year P&L Summary

| | Year 1 | Year 2 | Year 3 |
|-|--------|--------|--------|
| **Revenue** | $215,000 | $950,000 | $2,800,000 |
| Infrastructure (Firebase, hosting) | ($18,000) | ($55,000) | ($140,000) |
| Third-party APIs (Gemini AI, RevenueCat) | ($12,000) | ($40,000) | ($110,000) |
| App Store fees (30% on in-app) | ($8,000) | ($35,000) | ($90,000) |
| **Gross Profit** | **$177,000 (82%)** | **$820,000 (86%)** | **$2,460,000 (88%)** |
| Sales & Marketing | ($95,000) | ($280,000) | ($500,000) |
| Personnel (founder + 2 hires Y2) | ($120,000) | ($320,000) | ($650,000) |
| Tools, legal, admin | ($25,000) | ($50,000) | ($80,000) |
| **EBITDA** | **($63,000)** | **$170,000** | **$1,230,000** |

> Note: Year 1 loss is intentional — investing in growth. Profitable from Month 18 onwards.

### Cash Flow Planning

- Seed raise: $400,000 at launch
- Runway at $33k/month burn: **12 months**
- Break-even month: **Month 20** (organic growth + revenue exceeds burn)
- Series A trigger: $100k MRR (expected Month 24)

---

## 8. Operations Plan

### Technology Infrastructure

| Service | Provider | Monthly Cost (at scale) |
|---------|----------|------------------------|
| Backend | Firebase (Firestore, Functions, Storage, Auth) | $800–$3,000 |
| AI (Food Analysis) | Google Gemini 1.5 Flash | $50–$400 |
| Push Notifications | Firebase FCM | $0 (included) |
| Payments | RevenueCat | 1% of revenue (or $119/mo flat) |
| Error Monitoring | Firebase Crashlytics | $0 |
| Email | SendGrid (via Firebase Extension) | $20–$100 |
| App Distribution | App Store + Google Play + Firebase Hosting | $100/year |

**Total infrastructure at 3,600 coaches, 50,000 clients:** ~$2,500/month

### Customer Support

**Month 1–6 (founder-led):**
- Intercom chat widget in app (coach-only)
- 24h response SLA for Pro, 4h for Elite
- FAQ / knowledge base (Notion-hosted initially)
- Monthly coach community call (Zoom, record and post)

**Month 7–18 (first hire — support/success):**
- Hire 1 part-time customer success person
- Automated onboarding email sequence (7 days)
- In-app coach walkthrough overlay
- Loom video library (feature tutorials)

### Legal & Compliance

- **Terms of Service + Privacy Policy:** Written by attorney, reviewed before App Store submission
- **GDPR:** Data export button for EU users, 30-day deletion SLA
- **HIPAA:** Fitness data is not PHI under HIPAA — no medical data collected (confirmed with legal)
- **App Store compliance:** No user-generated content moderation issues (closed platform, coach-invite only)
- **Data storage:** US-East Firebase region by default; EU coaches directed to EU region instance

### Quality & Reliability

- Target uptime: 99.9% (Firebase SLA covers this)
- Deploy frequency: Weekly releases via Firebase App Distribution
- Crash rate target: < 0.5% of sessions
- Automated tests: Unit tests for all business logic, integration tests for Firestore writes
- Beta testing: TestFlight (iOS) + Internal Track (Android) before every release

---

## 9. Team & Hiring Plan

### Current State (Founder-Led)

| Role | Person | Responsibility |
|------|--------|---------------|
| CEO / Product | Founder | Vision, product decisions, fundraising, key partnerships |
| CTO / Lead Engineer | Founder (or technical co-founder) | Flutter app, Firebase backend, Cloud Functions |

> For a solo technical founder: the first 6 months are fully feasible alone given the MVP is complete. The platform is Firebase-hosted, so there is no DevOps burden.

### Hiring Roadmap

**Month 6 — First Hire: Growth Marketer ($3,500/mo)**
- Own content marketing (blog, YouTube, social)
- Manage community (Facebook group, coach Discord)
- Run paid ad experiments
- Key metric: 500 new coach signups/month

**Month 12 — Second Hire: Customer Success Manager ($4,000/mo)**
- Onboard Pro coaches personally (1-on-1 calls)
- Monitor churn risk signals
- Gather feature requests
- Run coach community events
- Key metric: < 3% monthly Pro churn

**Month 18 — Third Hire: Software Engineer ($7,000/mo)**
- Take over Firebase Cloud Functions
- Build out web dashboard features
- Support Elite/API tier integrations
- Key metric: Feature shipping velocity ×2

**Month 24 — Post Series A: Scale Team**
- Head of Sales (outbound to gyms for Elite tier)
- Second Engineer (mobile)
- Design / Brand (UI polish, marketing assets)
- Data Analyst (business intelligence, churn models)

### Founder Profile Requirements

If solo:
- Must be able to write production Flutter code
- Must be able to communicate a vision to coaches/investors
- Must be willing to be "head of everything" for 12–18 months

If co-founding:
- Ideal split: CEO (business/product/marketing) + CTO (Flutter/Firebase)
- Avoid splitting equally: one person holds final decision on product, one on tech

---

## 10. Risk Analysis & Mitigation

### Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| ABC Fitness (Trainerize parent) launches competing product | Medium | High | Move fast, own brand loyalty, build community moat |
| Low free-to-paid conversion (<10%) | Medium | High | Monthly in-app paywall prompts, onboarding email sequence, feature limitations |
| High churn (>6%/month) | Medium | High | Invest in customer success early, track leading indicators |
| App Store rejection (Apple policy changes) | Low | High | Comply strictly with HIG, no dark patterns, no fake reviews |
| Firebase price increase | Low | Medium | Architecture is Firebase-agnostic (can migrate to Supabase/PlanetScale with 2–3 month effort) |
| AI food analysis inaccuracy complaints | Medium | Medium | Coach override feature, confidence badges, manual entry always available |
| Competitor undercuts on price | Medium | Low | Pricing is not our moat — experience, AI, and brand are |
| Regulatory (GDPR, Australia Privacy Act) | Low | Medium | Privacy Policy in place, data export built in Phase 9 |
| Founder burnout (solo) | Medium | High | Hire CSM by Month 12; take 1 day/week completely off |

### Key Risks Deep-Dived

#### Risk 1: ABC Fitness Competitive Response
ABC Fitness owns Trainerize AND TrueCoach. They could lower prices or copy features. **Counter-strategy:**
- Valence's brand positioning is "premium indie tool" — the same way indie apps beat corporate apps on App Store. Coaches prefer working with companies that care about them over faceless corporations.
- Build community so tight that coaches become advocates — harder to peel away with a price cut.
- Move fast. Valence ships weekly. Corporate SaaS ships quarterly.

#### Risk 2: Free-to-Paid Conversion Below Target
If conversion is 10% instead of 20%, MRR at Month 12 is ~$15k instead of $30k.  
**Counter-strategy:**
- Hard limit at 5 clients enforced (no "soft" warnings, hard block)
- Personal outreach at Day 14 to coaches with 3+ clients: "You're halfway to your limit — let's talk"
- Offer 30-day Pro trial at Day 7 to reduce commitment anxiety

#### Risk 3: High Monthly Churn
If churn is 6%+ instead of 3.5%, average retention drops from 29 months to 17 months, cutting LTV nearly in half.  
**Counter-strategy:**
- Onboarding call for every Pro coach within 48h of upgrade
- Week 2 and Week 4 check-in emails with product tips
- "Health score" dashboard (internal): flag coaches with < 2 active clients as churn risk
- Exit survey required on cancellation → fix top 3 reasons

---

## 11. Funding Strategy

### Seed Round: $400,000

**Use of funds:**
| Category | Amount | Duration |
|----------|--------|---------|
| Founder salary (18 months) | $90,000 | Living wage during growth phase |
| Marketing & growth (ads, content, tools) | $120,000 | CAC experiments + SEO + community |
| First hire (Growth Marketer, Month 6) | $63,000 | $3,500/mo × 18 months |
| Infrastructure & tools | $42,000 | Firebase, SendGrid, RevenueCat, etc. |
| Legal (ToS, Privacy, incorporation) | $15,000 | One-time |
| App Store developer accounts | $200 | One-time |
| Events, PR, partnerships | $20,000 | Fitness industry events, press |
| Reserve / contingency | $49,800 | Buffer |
| **Total** | **$400,000** | |

**Runway:** 18 months  
**Break-even:** Month 20 (organic revenue exceeds monthly burn)  
**Series A trigger:** $100k MRR (Month 22–26 depending on growth rate)

### Investor Profile

- **Target:** Pre-seed/seed-stage angels and micro-VCs focused on B2B SaaS, health tech, or consumer apps
- **Sweet spot:** $25k–$100k check sizes; 6–8 investors in the round
- **Strategic angels to pursue:** Former fitness SaaS founders, successful indie app builders, health/wellness fund GPs
- **Not a fit:** Late-stage VCs, revenue-focused funds (no revenue yet), funds with no health/fitness expertise

### Comparable Exits / Benchmarks

| Company | Description | Outcome |
|---------|------------|---------|
| TrueCoach | Fitness coaching SaaS | Acquired by ABC Fitness (2022) ~$30M |
| Trainerize | Fitness coaching SaaS | Acquired by ABC Fitness (2021) ~$55M |
| Mindbody | Gym/studio management | Acquired by Vista Equity (2019) $1.9B |
| TrainHeroic | Team sports coaching | Acquired by TrainHeroic/Outside Inc |
| MyFitnessPal | Consumer nutrition | Sold to Francisco Partners (2020) $345M |

### Non-Dilutive Options (Parallel Track)

- **App Store revenue:** Self-sustaining before seed if organic growth hits $10k MRR
- **Grants:** SBIR (Small Business Innovation Research) for AI + health tech — up to $150k non-dilutive
- **Accelerators:** YC (W or S batch), Techstars, 500 Startups — provide $125k–$500k + network

---

## 12. Exit Strategy

### Strategic Acquirer Landscape

Valence is an attractive acquisition target at scale for:

| Acquirer Type | Example | Why They'd Acquire |
|---------------|---------|-------------------|
| Fitness SaaS platforms | ABC Fitness, Mindbody | Add AI-first coaching product to portfolio |
| Gym management software | ClubReady, Jonas Software | Coaching intelligence layer for gyms |
| Consumer fitness apps | Whoop, Strava, Garmin | Coach-side complement to athlete data |
| Health insurance / wellness | Hinge Health, Sword Health | Preventive fitness with coach accountability |
| Sports nutrition brands | Herbalife, ON, Myprotein | Direct channel to coach-recommended clients |

### Acquisition Price Model

At $5M ARR with 88% gross margins and strong growth:
- SaaS multiples in health/fitness: 5–10× ARR
- **Expected range: $25M–$50M**

At $15M ARR (aggressive Year 4):
- **Expected range: $75M–$150M**

### IPO / Stand-Alone Path

If the gym white-label business hits $5M ARR alongside the coaching SaaS, Valence becomes a full B2B2C health platform. Stand-alone path requires $20M ARR+ and 70%+ gross margins (already achieved). IPO window would be 7–10 years post-founding.

---

*Last updated: April 2026*
