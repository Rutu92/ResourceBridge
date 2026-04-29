# Resource Bridge

> **Donation is broken — not by lack of willingness, but by lack of connection.**

Donors don't know which NGOs need what. NGOs can't reach the right donors. Damaged items never get a second chance. The gap isn't generosity — it's infrastructure.

**Resource Bridge** is an AI-powered donation and repair routing platform built for the Google Solution Challenge 2026. It connects contributors, NGOs, and repairers in one seamless flow — making donations smarter, faster, and more rewarding for everyone involved.

[![Download APK](https://img.shields.io/badge/Download-APK-7C3AED?style=for-the-badge)](https://drive.google.com/file/d/1r3UUiKsXq8om3nkWO4JDzni5cktEHZQs/view?usp=sharing)
[![Demo Video](https://img.shields.io/badge/Watch-Demo-FF5733?style=for-the-badge)](https://canva.link/ts7u5heurtjckoa)
[![Try It](https://img.shields.io/badge/Try-App-0F766E?style=for-the-badge)](https://appdistribution.firebase.dev/i/e58b3b7bd5172353)

---

## The Problem

- People want to donate but don't know which NGO needs what
- NGOs struggle because donors can't find them
- Damaged items get discarded when they could be repaired and reused
- Donors feel no motivation — *"what do I get out of this?"*

---

## How It Works

1. **Contributor uploads** a photo + description of an item (in any language)
2. **Gemini AI checks condition** — good, repairable, or unsuitable — and translates the description to English
3. **NGOs that need the item** get matched and can accept or reject
4. **If damaged**, the NGO sends a repair request — any available repairer can pick it up
5. **All parties communicate** via in-app chat
6. **Everyone earns reward points** — contributors, NGOs, and repairers

---

## Features

### Gemini Vision AI
Analyses item photos to classify condition — usable, repairable, or unsuitable. Validates descriptions and auto-translates from any language to English.

### Smart Item Matching
Matches donated items in real-time to NGOs that have specifically listed that requirement.

### In-App Chat
Contributor ↔ NGO and NGO ↔ Repairer — all coordination happens inside the app, zero external tools needed.

### Rewards Engine

| Action | Points |
|---|---|
| Upload an item | +10 |
| Item delivered to NGO | +50 |
| Repair completed | +75 |
| NGO accepts an item | +20 |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart, SDK ≥ 3.0) |
| UI | Antigravity by Google · Stitch by Google · Material Design |
| AI / ML | Gemini 2.0 Flash Lite |
| Database | Cloud Firestore · Firebase Realtime Database |
| Auth & Storage | Firebase Authentication · Firebase Storage |
| Cloud | Google Cloud Platform via Firebase |

---

## User Roles

| Role | Responsibility |
|---|---|
| Contributor | Uploads items, earns points on delivery |
| NGO | Posts requirements, accepts donations, requests repairs |
| Repairer | Picks up repair jobs, earns points on completion |

---

## Future Roadmap

- Live item tracking — real-time GPS map view of donation in transit
- AI-powered NGO recommendation — Gemini auto-suggests the best NGO match
- Repairer marketplace — ratings, skills, and specializations
- Reward redemption portal — exchange points for vouchers and impact certificates
- NGO inventory dashboard — analytics and demand forecasting
- Multi-language UI — Hindi, Marathi, Tamil and more

---

*Google Developer Groups — Solution Challenge 2026 · Team InfinityLoop*
