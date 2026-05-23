# Pawly — Project & App Overview

## What it is

**Pawly** is an all-in-one iOS pet care companion app. It helps pet owners track health, schedule care, store medical documents, and get instant AI vet guidance — all in one clean, friendly interface.

Tagline candidates:
- *"Everything your pet needs, right in your pocket."*
- *"Smart pet care. Simple."*
- *"Your pet's health, always in your hands."*

---

## Target audience

- Pet owners with dogs, cats, rabbits, birds, or exotic pets
- Multi-pet households
- First-time pet owners who need guidance on care routines
- People who travel with pets and need documents on hand
- Anyone who wants to be a more proactive, informed pet parent

Supported species: Dog · Cat · Rabbit · Bird · Fish · Hamster · Horse · Snake · Lizard · Turtle · Frog · Guinea Pig · Ferret · Hedgehog · Chinchilla · Goat · Sheep · Pig · Chicken

---

## Core features

### 1. Today (Home)
The daily dashboard. Shows a greeting with the active pet's name, today's pending care tasks, upcoming reminders, and a mood/quick log shortcut. Multi-pet households can switch between pets via a top carousel. A floating **+** button opens a Quick Log sheet to log meals, weight, mood, symptoms, and notes on the fly.

### 2. Track
Full health tracking hub with three tabs:

**Health** — Log weight over time with a chart, track mood entries, and view care history.

**Reminders** — Smart recurring reminder system covering:
  - Medications
  - Vaccinations
  - Deworming / Tick & Flea treatments
  - Vet checkups
  - Grooming / Baths
  - Weight checks
  - Custom reminders

**Vet** — Dedicated vet visit manager. Schedule future vet visits, mark visits as done (with a confirmation step for future dates), view full vet visit history including notes. Overdue visits are flagged clearly.

### 3. Vault (Document Safe)
End-to-end encrypted secure document storage for pet records:
- Vaccination certificates
- Medical records
- Insurance documents
- Microchip registration
- Prescriptions
- Passport / travel paperwork

Features: document upload, OCR scanning, search, expiry reminders, travel paperwork generator, biometric/passcode lock per document.

**Free tier:** Up to 10 documents.
**Paid tier:** Unlimited documents + OCR + expiry alerts + travel paperwork.

### 4. PawMD (AI Vet Doctor)
An AI-powered vet consultation chat powered by **Groq + LLaMA 3.3 70B**.

The AI persona is **Dr. Ruff** — a vet with 20 years of experience who texts like a friend: direct, specific, no fluff, no AI buzzwords. Triage responses are categorised into:
- **Monitor at home** — mild, watch and wait
- **See vet within 24h** — vomiting, lethargy, limping, not eating
- **See vet now** — emergency (collapse, seizure, bleeding, can't breathe)

Context-aware: the AI knows the active pet's name, species, and age before the conversation starts.

### 5. Discover
Educational content hub:

**DIY Hygiene Library** — Step-by-step guides for home grooming, dental care, nail trimming, ear cleaning, bathing, litter maintenance, and cage hygiene. Filterable by species and difficulty. Supports embedded video guides.

**Recipes** — Vet-reviewed home-cooked meal recipes filtered by species and dietary needs (grain-free, high-protein, etc.).

---

## Onboarding

Multi-step onboarding flow:
1. Welcome screen
2. Pet details — name, species, breed, DOB/age, sex, weight
3. Spayed/neutered status
4. Indoor/outdoor toggle (for cats)
5. Health history — known conditions, allergies
6. Account creation (email/password via Supabase)

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| Platform | iOS 17+ (SwiftUI) |
| Local DB | SwiftData |
| Cloud / Auth | Supabase (Postgres + Auth) |
| AI | Groq API — LLaMA 3.3 70B Versatile |
| Push notifications | UNUserNotificationCenter (rich actions) |
| Biometric auth | LocalAuthentication (Face ID / Touch ID) |
| OCR | Vision framework |
| Design system | Custom (PawlyColors, PawlyFont, Spacing, Radius) |

---

## Design system

**Palette**
- Cream / Canvas background — warm off-white
- Forest green — primary action color
- Peach — secondary accent, health actions
- Navy — PawMD / AI section
- Sage — recipes / nutrition
- Ink / Slate — typography hierarchy

**Style**
- Glassmorphic floating tab bar
- Rounded card UI with subtle shadows
- Warm, pastel, approachable — not clinical
- SF Symbols throughout
- Haptic feedback on key interactions

---

## Subscription model

| Feature | Free | Paid |
|---------|------|------|
| Pets | Unlimited | Unlimited |
| Reminders | Unlimited | Unlimited |
| Health tracking | Full | Full |
| PawMD AI chat | Full | Full |
| Discover content | Full | Full |
| Vault documents | 10 max | Unlimited |
| OCR document scanning | — | Yes |
| Expiry reminders | — | Yes |
| Travel paperwork | — | Yes |

---

## Landing page key messages

1. **Hero** — "Your pet's health, right in your pocket" + screenshot of home/today screen
2. **Feature 1** — Never miss a dose. Smart reminders for every care task.
3. **Feature 2** — Dr. Ruff is in. Get real vet guidance instantly, 24/7.
4. **Feature 3** — Every record, safe and searchable. The Vault keeps all your pet's documents encrypted and always with you.
5. **Feature 4** — Learn as you go. DIY guides, recipes, and expert tips.
6. **Social proof / trust** — "Vet-reviewed content", "End-to-end encrypted", "No data sold"
7. **CTA** — Download on the App Store

---

## App name options (if branding is still open)

| Name | Tone |
|------|------|
| **Pawly** | Friendly, memorable, pet-specific |
| **PetVault** | Serious, document-focused |
| **PawMD** | AI-forward, health-focused |
| **Nuzzle** | Warm, emotional |
| **CarePaw** | Action-oriented |

Current app uses **Pawly** with **PawMD** as the AI sub-brand.
