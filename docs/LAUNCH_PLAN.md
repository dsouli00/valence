# 🚀 Valence — Complete Launch Plan
> **Author:** Founder (dsouli00)
> **Date:** May 2026
> **Status:** Pre-launch — product built, zero customers

---

## ⚡ Honest Idea Rating & Success Probability

### Rating: **7.5 / 10**

| Factor | Score | Reason |
|---|---|---|
| Problem clarity | 9/10 | Coaches genuinely struggle with WhatsApp/spreadsheet chaos |
| Market size (GCC + global fitness) | 8/10 | $100B+ fitness industry, growing fast in GCC |
| Product readiness | 8/10 | App is built and functional |
| Competitive differentiation | 6/10 | TrueCoach, PT Distinction, Trainerize already exist — you need to out-execute locally |
| Founder-market fit | 7/10 | Technical + trilingual + local insight |
| Funding situation | 5/10 | No money is hard but not fatal at this stage |
| Payment infrastructure (Tunisia) | 4/10 | Real obstacle — solvable but requires creative workarounds |
| Go-to-market (no personal brand) | 5/10 | No online presence is a disadvantage — needs a strategy around it |

### Honest Probability of Success

| Milestone | Probability | Why |
|---|---|---|
| Get 5 paying coaches in 90 days | **55%** | Doable with daily outreach — depends entirely on execution |
| Reach 20 paying coaches in 6 months | **35%** | Requires product-market fit signal + retention |
| Survive to 12 months (ramen profitable) | **25%** | Most founders quit around month 4-6 when growth stalls |
| Reach GCC market with 50+ coaches | **15%** | Requires Tunisia success first + payment infrastructure |
| Build a real company (100+ coaches) | **8%** | Hard, but not impossible — requires at least one growth channel |

> **Why is success probability lower than the idea rating?**
> Because the idea is solid, but execution without funding, without an online presence, in a country with broken payment rails, with no team, as a first-time founder — those are very real compounding risks. The 8% at full scale is not pessimism — most SaaS companies never reach 100 customers. But you only need to outperform the average, and the fact that you've already built the product puts you ahead of 80% of people who never ship anything.

---

## 📌 Your Situation Summary

| Item | Status |
|---|---|
| Product | ✅ Built (Flutter mobile app) |
| Target customer | ✅ Fitness coaches |
| Business model | ✅ B2B SaaS (coaches pay monthly) |
| Languages | ✅ Arabic, French, English |
| Location | 🇹🇳 Tunisia |
| Online presence | ❌ None (by choice — privacy) |
| Funding | ❌ Zero |
| Work experience | ❌ None formal (PFE + mobile apps) |
| Legal structure | ❌ Not yet registered |
| Payment infrastructure | ❌ Not yet set up |
| Existing coach contacts | ⚠️ Some (not confirmed as clients yet) |
| GCC ambition | ✅ Qatar, UAE, KSA, then global |

---

## 🗺️ The Complete Step-by-Step Plan

---

## PHASE 0 — Foundation (Week 1–2)

### Step 0.1 — Fix the security issue in the codebase
> **Why:** The Gemini API key is hardcoded. If anyone sees the code, you lose money and potentially get locked out.

- Move the Gemini API key to a backend function (Firebase Cloud Function or a simple API proxy)
- Never commit API keys directly in the Flutter code
- Check all other hardcoded secrets and move them

**How to do it:**
1. Create a Firebase Cloud Function that wraps the Gemini API call
2. Call that function from the app instead of calling Gemini directly
3. Remove the key from the Flutter code entirely
4. Rotate the old key immediately in Google AI Studio

---

### Step 0.2 — Register as Auto-Entrepreneur (Tunisia)
> **Why:** You need to be legal from day 1. This takes 1–2 days and almost no money.

**Documents needed:**
- CIN (national ID)
- RNE registration at the nearest Commerce Tribunal (Tribunal de commerce)
- CNSS affiliation form

**Cost:** ~30–80 TND in fees

**Process:**
1. Go to the nearest APII office or Commerce Tribunal
2. Fill out the auto-entrepreneur registration form
3. Get your matricule fiscal (tax number)
4. This allows you to legally issue invoices to Tunisian clients

> ⚠️ **Important:** Auto-entrepreneur status has a revenue cap (currently ~100,000 TND/year). Once you exceed this, upgrade to SUARL.

---

### Step 0.3 — Create a Simple Landing Page
> **Why:** When you DM coaches, they will Google you. You need something to show.

**What the landing page needs (minimum):**
- Name: Valence
- Tagline: "La plateforme qui remplace WhatsApp pour les coachs fitness" (or in Arabic)
- 3 bullet points: what it does for the coach
- 1 short screen recording (Loom or screen capture — 90 seconds max)
- A "Demander un accès gratuit" button that sends an email or opens WhatsApp

**Free tools to build it:**
- Carrd.co (free tier, very fast to set up)
- Or Notion public page
- Or a simple HTML page hosted on GitHub Pages (you can do this yourself in 1 hour)

**Languages:** French first (Tunisian coaches), then Arabic

---

### Step 0.4 — Create Your Outreach Assets

**Asset 1: Screen recording demo**
- Record 90 seconds of the app
- Show: coach dashboard → client list → client detail → macros + logs
- No music, no effects. Just narrate in French or Darija.
- Upload to Google Drive or YouTube (unlisted)

**Asset 2: Your pitch message (DM template)**
```
Salam [prénom],

Je vois que tu fais du coaching en ligne — je suis en train de lancer Valence, une app qui remplace les notes WhatsApp et les sheets pour le suivi des clients.

Tes clients loggent leurs repas et workouts directement, toi tu vois tout en temps réel sur un dashboard.

Je cherche 5 coachs en Tunisie pour tester gratuitement pendant 2 semaines. Pas d'engagement.

Intéressé(e) ? Je t'envoie l'accès aujourd'hui.
```

**Asset 3: List of 50 Tunisian fitness coaches**
- Go to Instagram
- Search: "coach fitness Tunisie", "coach nutrition Tunisie", "transformation corporal Tunisie", "coach sportif Tunis"
- Look for coaches with **1,000–30,000 followers** (smaller = more responsive)
- Coaches who post client results, check-ins, or food logs
- Create a simple spreadsheet: Name, Instagram handle, follower count, DM sent (Y/N), Response (Y/N/No), Status

---

## PHASE 1 — First Customers (Week 2–8)

### Step 1.1 — Reach Out to Contacts First
> **Why:** Warm contacts are 5x more likely to convert than cold DMs.

**Action:**
1. Write down every person you know (university, gym, family circle, neighborhood) who is a fitness coach OR knows one
2. Send them a WhatsApp message — not a pitch, a question:
   > "Salam, je travaille sur une app pour les coachs fitness — tu connais des coachs qui gèrent leurs clients sur WhatsApp/sheets ? Je veux leur parler 10 minutes."
3. If they know someone, ask for an introduction
4. Then pitch that coach directly

---

### Step 1.2 — Cold Instagram Outreach (50 coaches)
> **Why:** You have no online presence, so you reach out — not the other way around.

**Daily routine:**
- Message 5–10 coaches per day
- Use the template from Step 0.4
- Track responses in your spreadsheet
- Follow up once after 3 days if no reply

**Expected results (realistic):**
- 50 messages sent
- 10–15 open / reply
- 5–8 interested in the free pilot
- 2–4 actually set up and use it with clients

---

### Step 1.3 — Onboard Pilots Manually (High Touch)
> **Why:** Your first 5 coaches are your most important relationships. They will refer you or destroy you.

**For each pilot coach:**
1. Personally set up their coach account
2. Walk them through the dashboard (WhatsApp call or voice note walkthrough)
3. Give them their invite link for clients
4. Check back after 3 days: "Comment ça se passe ?"
5. Fix anything that confuses them immediately

**Your goal:** Make these coaches feel like they have a personal assistant, not just an app.

---

### Step 1.4 — Convert Pilots to Paying (Week 5–6)
> **Timing:** After 2 weeks of free use

**Conversation:**
> "Tu as pu tester l'app avec tes clients — est-ce que ça t'a aidé ? Je vais lancer le plan payant maintenant. Pour les premiers coachs c'est 79 TND/mois au lieu de 99 TND."

**If they say yes:**
- Send a simple PDF invoice (you can make one in Canva or Google Docs)
- They pay by bank transfer to your account
- You confirm payment and keep their access active

**If they say they want more features first:**
- Ask: "C'est quoi la chose la plus importante qui te manque ?"
- Note it. If 3 coaches say the same thing, build it.

**If they say no:**
- Ask why. This is data, not failure.

---

### Step 1.5 — Collect Payment Manually
> **Why:** There is no Stripe in Tunisia. Manual collection is the professional solution at your stage.

**For Tunisian coaches:**
- Bank transfer (virement bancaire)
- D17, Flouci, or PayLib (Tunisian mobile payment apps)
- Cash (if local)

**Process:**
1. Send PDF invoice with your name, matricule fiscal, amount, and your bank details
2. They transfer the money
3. You confirm and keep their access active in the app
4. Keep a simple record in a spreadsheet (Date, Coach name, Amount, Status)

---

## PHASE 2 — Stabilize & Grow (Month 2–4)

### Step 2.1 — Fix the Top 3 Problems
> After your first 5 coaches use the app, you will have a clear list of what doesn't work.

**How to track problems:**
- After each coach conversation, write down every complaint, confusion, or request
- After 5 coaches, rank by frequency
- Build the top 3 most-requested features or fixes
- Ship them quickly (you are the dev — use this advantage)

---

### Step 2.2 — Create Simple Documentation
> **Why:** You cannot personally onboard every coach forever.

**What to create:**
1. A 3-minute video: "Comment configurer ton compte coach Valence"
2. A 2-minute video: "Comment inviter tes clients"
3. A simple FAQ page (Google Doc or Notion — free)

**Languages:** French first, then Arabic when you expand to GCC

---

### Step 2.3 — Upgrade to SUARL
> **When:** Once you have 3+ paying coaches and recurring revenue

**Why SUARL:**
- Can issue formal invoices
- Needed for B2B contracts
- Can open a business bank account
- Protects your personal assets

**How:**
1. Find a notaire in Tunis
2. Prepare: CIN, proof of address, initial capital (minimum 1,000 TND)
3. Sign the statuts (articles of association)
4. Register at the RNE
5. Get your company's tax number (matricule fiscal entreprise)

**Cost:** ~500–1,500 TND total (notaire fees + registration fees)

---

### Step 2.4 — Open a Payoneer Account
> **Why:** When GCC coaches want to pay you, bank transfer from UAE to Tunisia is slow and expensive. Payoneer is the standard tool for Tunisian freelancers/startups receiving international payments.

**How:**
1. Go to payoneer.com
2. Register as a Tunisian individual or company
3. Verify your identity (CIN + bank details)
4. You get a US/EU bank account number that clients can wire to
5. You withdraw to your Tunisian bank account

**Alternative:** Wise (formerly TransferWise) — also works for receiving USD/EUR

---

### Step 2.5 — Build Referral System (Informal)
> **Why:** You have no online presence. Your best marketing is happy coaches telling other coaches.

**Action:**
- After a coach has used the app for 1 month and is happy:
  > "Si tu connais un autre coach qui galère avec WhatsApp, envoie-lui mon contact. Je lui offre le premier mois gratuit, et toi tu as 1 mois gratuit aussi."
- This is a simple word-of-mouth referral system. No code needed.

---

## PHASE 3 — First GCC Test (Month 4–6)

> **Condition to enter Phase 3:** You have at least 5 paying Tunisian coaches and the app is stable.

### Step 3.1 — Prepare GCC-Ready Assets

**Language:**
- Translate your DM template and landing page to Arabic (formal/Gulf dialect for KSA, neutral for UAE)
- Keep the English version for international coaches

**Pricing for GCC:**
- 29 USD/month per coach (introductory)
- 39 USD/month standard
- Annual plan: 299 USD (saves ~3 months)

---

### Step 3.2 — Find GCC Fitness Coaches

**Instagram searches:**
- "fitness coach Dubai", "كوتش لياقة دبي", "personal trainer Riyadh", "مدرب شخصي قطر"
- "online fitness coach UAE", "transformation coach KSA"

**Who to target:**
- 5,000–50,000 followers
- Coaches who post client check-ins, food logs, or transformation posts
- Coaches who clearly manage multiple clients online

**Outreach message (English):**
```
Hi [name],

I noticed you're managing online coaching clients — I built Valence, an app that replaces WhatsApp/spreadsheets for client tracking.

Your clients log meals and workouts in the app, you see everything in real-time on your dashboard.

I'm offering 5 coaches a free 2-week pilot. No commitment. Interested?
```

---

### Step 3.3 — Handle GCC Payments

**Option A (now):** They pay to your Payoneer account via bank transfer or card
**Option B (later):** UAE entity with Stripe (see Phase 4)

---

### Step 3.4 — Goal for Phase 3

- 5 GCC coaches on free pilot
- 2–3 converting to paid (29 USD/month each)
- This gives you proof of concept for international market

---

## PHASE 4 — GCC Serious (Month 6–12)

> **Condition:** 15+ paying coaches total (Tunisia + GCC combined)

### Step 4.1 — Apply for Tunisia Startup Label (Startup Act 2019)

> Tunisia's Startup Act is one of the best in Africa. It gives you real advantages.

**Benefits:**
- 8-year tax exemption (pays no corporate tax for 8 years)
- Right to open foreign currency accounts in Tunisian banks
- Access to state-funded programs and grants
- Easier to attract talent (employees can get stock options legally)
- Signal of legitimacy for GCC partnerships

**Requirements to apply:**
- Must be a registered Tunisian company (SUARL qualifies)
- Must be in an innovative/digital sector (you qualify)
- Must have a pitch deck and basic business plan
- Apply at: [startup.gov.tn](https://startup.gov.tn)

**What to prepare:**
1. A 10-slide pitch deck (problem, solution, market, product, traction, team, ask)
2. Financial projections for 3 years (even rough ones are fine)
3. Evidence of traction (paying customers, user numbers)

---

### Step 4.2 — Consider UAE Free Zone Company
> **Why:** UAE entity = access to Stripe, checkout.com, all global payment processors. This unlocks international payments at scale.

**Cost:** 8,000–15,000 AED (~2,000–4,000 USD) for registration + license + bank account

**Popular options:**
- Dubai Multi Commodities Centre (DMCC)
- Meydan Free Zone (cheaper, ~5,000 AED)
- Sharjah Media City (Shams) — cheapest option (~5,750 AED/year)

> ⚠️ **Do NOT do this now.** Only relevant when you have 20+ coaches and want automated card payments.

---

### Step 4.3 — Establish Arabic-First Marketing

Since you will not build a personal brand, the product itself must do the selling. Options:

**A. Valence Instagram account (not your personal account)**
- Post coach testimonials (with permission)
- Post "before/after workflow" content (screenshot of WhatsApp chaos vs. Valence dashboard)
- Post tips for coaches on managing clients
- This account is for Valence, not for you personally

**B. Coach partnership / ambassador**
- Find 1 GCC coach who loves the product and let them post about it
- Give them 3 months free in exchange
- Their audience trusts them more than any ad

---

## PHASE 5 — Scale (12+ Months)

> **Condition:** 30+ coaches, recurring MRR, proven acquisition channel

### Step 5.1 — Identify Your Growth Channel
One of these will work better than others — you'll know by month 6:
- Instagram cold DM (your current strategy)
- Referrals from existing coaches
- Gym partnerships
- Coach communities / Facebook groups
- Arabic YouTube creators in fitness space

**Double down on whatever is working. Stop what isn't.**

---

### Step 5.2 — Pricing Increase
Once you have product-market fit:
- Tunisia: 99 TND/month → 149 TND/month for new coaches
- GCC: 39 USD/month → 49–59 USD/month

Existing coaches keep their price. This is called a grandfather clause and builds loyalty.

---

### Step 5.3 — Consider Your First Hire
When managing 30+ coaches manually becomes too much:
- First hire: a part-time customer support / onboarding person
- Could be a friend or recent graduate in Tunisia
- Pay: 500–700 TND/month part-time
- Their job: onboard new coaches, answer questions, follow up on payments

---

### Step 5.4 — Fundraising (Optional)
> Only if you want to grow faster than revenue allows. Not required.

**Where to look in Tunisia/MENA:**
- Flat6Labs Tunisia (accelerator — takes equity but gives training + network)
- ANCE (Agence nationale pour l'emploi et le travail indépendant) — grants for young founders
- Wamda Capital, BECO Capital (GCC VCs interested in Arab SaaS)
- AngelList for angel investors

> ⚠️ **Important:** You said you don't want investor pressure. That's valid. You can build a profitable bootstrap company at 30–50 coaches without raising money. Only raise if you want to scale fast to 1,000+ coaches in 2 years.

---

## 💰 Money: Realistic Revenue Projections

### Tunisia market

| Coaches | Monthly Revenue | Annual Revenue |
|---|---|---|
| 5 coaches × 79 TND | 395 TND/month | ~4,700 TND/year |
| 10 coaches × 99 TND | 990 TND/month | ~11,900 TND/year |
| 20 coaches × 99 TND | 1,980 TND/month | ~23,760 TND/year |
| 30 coaches × 99 TND | 2,970 TND/month | ~35,640 TND/year |

> 30 coaches in Tunisia = ~ramen profitable for 1 person in Tunis

### GCC market (mixed)

| Coaches | Monthly Revenue |
|---|---|
| 5 GCC × 29 USD + 10 TN × 99 TND | ~290 USD + 990 TND |
| 20 GCC × 39 USD + 20 TN × 99 TND | ~780 USD + 1,980 TND |
| 50 GCC × 49 USD | ~2,450 USD/month |

> 50 GCC coaches = ~2,500 USD/month = sustainable solo company

---

## 🔑 Key Risks and Mitigations

| Risk | Probability | Mitigation |
|---|---|---|
| Coaches don't pay (payment friction) | High | Manual collection via bank transfer from day 1 |
| Coaches sign up but don't actually use it | Medium | High-touch onboarding, follow up daily in first week |
| A competitor copies your idea | Low (short term) | First-mover + local language + trust |
| You run out of motivation | Medium | Get your first payment — money is the strongest motivator |
| Firebase costs grow with users | Low (at this stage) | Free tier handles hundreds of users easily |
| GCC coaches don't trust a Tunisian startup | Medium | Let the product speak. Have a professional demo ready. |
| App crashes or has bugs with real users | Medium | Fix fast — your advantage is you're the dev |

---

## 📅 90-Day Action Calendar

### Week 1
- [ ] Fix hardcoded API key (security)
- [ ] Register as auto-entrepreneur
- [ ] Open Payoneer account
- [ ] Create landing page (Carrd or GitHub Pages)
- [ ] Record 90-second product demo video
- [ ] Build list of 50 Tunisian coaches on Instagram

### Week 2
- [ ] DM all existing contacts who might know coaches
- [ ] Start cold DM campaign: 10 coaches/day
- [ ] Create simple invoice template (Canva/Google Docs)
- [ ] Set up spreadsheet to track outreach and pipeline

### Week 3–4
- [ ] Onboard first 5 pilots (manually and personally)
- [ ] Daily check-in with each pilot
- [ ] Log every bug, complaint, and feature request
- [ ] Continue DM outreach: 5 coaches/day

### Week 5–6
- [ ] Convert pilots to paying (79 TND/month)
- [ ] Collect first payment (bank transfer)
- [ ] Build top 3 most-requested features
- [ ] Follow up with non-responsive coaches from week 2

### Week 7–8
- [ ] Reach 10 coaches (paid or active pilots)
- [ ] Create onboarding video (3 minutes)
- [ ] Create FAQ document
- [ ] Start SUARL registration process

### Month 3
- [ ] 10+ paying coaches
- [ ] SUARL completed
- [ ] Start GCC research (coaches, pricing, Arabic assets)
- [ ] Informal referral program launched

### Month 4–5
- [ ] First GCC cold DM campaign (Arabic + English)
- [ ] Payoneer ready for international payments
- [ ] 5 GCC pilots

### Month 6
- [ ] 15–20 total paying coaches
- [ ] Apply for Tunisia Startup Label (if eligible)
- [ ] Review: what acquisition channel is working?

---

## 🧠 Mindset Notes

**You asked for honest truth, so here it is:**

1. **The hardest month will be month 2–3.** Pilots won't convert easily, you'll fix bugs, coaches won't respond. This is normal. Push through.

2. **No online presence is a real disadvantage, but not fatal.** The Valence brand account on Instagram can replace your personal brand. The product demo replaces your face.

3. **You are not behind.** You are 22–23 years old with a working product. Most people your age have neither. The window is open.

4. **Selling is a skill, not a personality trait.** It feels uncomfortable at first. After 50 DMs you will be good at it.

5. **One paying customer changes everything.** Not because of the money. Because it proves someone values what you built enough to pay for it. That feeling is what keeps you going.

---

## 📞 Resources

### Tunisia
- APII (Agence de Promotion de l'Industrie et de l'Innovation): [apii.tn](https://www.apii.tn)
- RNE (Registre National des Entreprises): [rne.tn](https://www.rne.tn)
- Startup Act applications: [startup.gov.tn](https://startup.gov.tn)
- Flat6Labs Tunisia: [flat6labs.com/tunis](https://flat6labs.com/tunis)

### Payments
- Payoneer: [payoneer.com](https://www.payoneer.com)
- Wise: [wise.com](https://wise.com)
- D17 (Tunisia): [d17.tn](https://d17.tn)
- Flouci (Tunisia): available on App Store / Play Store

### Tools (Free)
- Landing page: [carrd.co](https://carrd.co)
- Screen recording: OBS Studio (free) or Loom (free tier)
- Invoice template: Canva → search "invoice"
- Pipeline tracking: Google Sheets (free)
- Email: Gmail Business (free) or Zoho Mail (free with custom domain)

---

*Last updated: May 2026. This document is a living plan — update it as you learn.*
