# FundMind Web Frontend (Next.js)

This folder contains the web-based frontend for FundMind, built using Next.js 14, TypeScript and TailwindCSS.

## Features

- **Dashboard & Budget Cards** – displays budget categories and remaining balance with progress bars.
- **CSV Import** – upload CSV files of transactions and preview the parsed data before saving.
- **PDF Export** – export budget summaries to a PDF file via the `/api/export-pdf` endpoint.
- **Responsive Design** – built with TailwindCSS, ready for desktop and mobile.
- **Future Integrations** – placeholders for AI budget recommendations, Notion sync, and multi-language (PL/EN).

To run the frontend locally:

```bash
npm install
npm run dev
```

This frontend is currently decoupled from the backend; API routes and database integration are prepared for future development.
