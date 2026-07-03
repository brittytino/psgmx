# PSGMX Department OS

> **Official Software**: Built by the Department of Computer Applications (MCA), PSG College of Technology.

Welcome to **PSGMX**, the completely self-sustaining, AI-augmented Department Operating System. This repository contains the source code for the centralized platform that empowers students, alumni, and faculty to collaborate efficiently.

## Core Pillars

### 1. Token Lineage Network
At the heart of PSGMX is the **Token Identity** (e.g., `25MX301`). By shedding arbitrary usernames, students and alumni are bound together in a generational hierarchy. A student (`25MX301`) is inherently linked to their seniors (`24MX301`, `23MX301`) allowing for automatic mentorship connections and lineage-based broadcasting.

### 2. The Knowledge Brain
A central, searchable vector-indexed database where students and alumni inject **Survival Guides, Interview Experiences, and Project Architectures**. This ensures institutional memory never dies.

### 3. Artificial Intelligence (The AI Senior)
Powered by Google Gemini and a proprietary RAG (Retrieval-Augmented Generation) pipeline, the **AI Senior** directly taps into the Knowledge Brain to answer complex questions (e.g., "How do I prepare for Zoho placements?") using only verified department data.

### 4. Collaboration Marketplace
Alumni and students can post requests for project collaborators or job openings, utilizing granular visibility controls to restrict posts to the department or just their specific lineage network.

---

## Architecture

- **Framework**: Next.js 14 App Router (React, TypeScript)
- **Database**: MongoDB (Mongoose)
- **Styling**: Tailwind CSS (Neo-Dark Glassmorphic UI)
- **AI Integration**: `@google/genai` (Gemini 2.5 Flash)

---

## Deployment

The system is highly optimized to run as a single process and requires no third-party microservices.

```bash
# 1. Install dependencies
npm install

# 2. Configure Environment
# Copy .env.example to .env and set your MONGO_URI and GEMINI_API_KEY

# 3. Build & Run
npm run build
npm run start
```

*Built by MCA Students, for MCA Students.*
