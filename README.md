# F1 Info & Tickets

Seminar project for **Razvoj softvera II** (FIT Mostar), student Aida Ušanović (IB220012).

Formula 1 information system with ticket sales:

- **Desktop app (Windows, Flutter)**: administration of drivers, teams and line-ups, races, results (48-hour entry window), ticket offers, users and all reference data, plus reports (download as PDF and print).
- **Mobile app (Android, Flutter)**: race calendar and results, driver and constructor standings, favourites, ticket purchase with a cart and **PayPal** (sandbox), QR tickets, notifications and **recommended races**.
- **Backend**: ASP.NET Core 8 Web API, SQL Server (database `220012`), RabbitMQ and a separate worker service that sends emails.

## Running the system

Requirements: Docker Desktop, plus an Android emulator (AVD) for the mobile app.

1. In the repository root run:

   ```
   docker compose up --build
   ```

   This starts SQL Server, RabbitMQ, the Web API and the email worker. On first start the API applies the migrations and seeds the database. Configuration is in `.env`.

2. Extract the builds from `fit-build-2026-10-19.zip` in the repository root (password: `fit`).
   - **Windows**: run `f1_info_and_tickets_frontend/build/windows/x64/runner/Release/f1_info_and_tickets_frontend.exe` (API on `http://localhost:5174`).
   - **Android**: drag `f1_info_and_tickets_frontend/build/app/outputs/flutter-apk/app-release.apk` onto the AVD to install it (API on `http://10.0.2.2:5174`).

   A different API address can be set at build time: `flutter build ... --dart-define=API_BASE_URL=http://host:port`.

| Service | Address |
| --- | --- |
| Web API / Swagger | http://localhost:5174/swagger |
| RabbitMQ management | http://localhost:15672 (user and password: `RABBITMQ_USER` / `RABBITMQ_PASS` in `.env`) |
| SQL Server | `localhost,1433` (user `sa`, password `DB_SA_PASSWORD` in `.env`) |

## Login credentials

| App | Username | Password | Role |
| --- | --- | --- | --- |
| Desktop | `desktop` | `test` | Admin |
| Mobile | `mobile` | `test` | User |

The desktop app accepts only administrators and the mobile app only customers. New customers can register in the mobile app.

## PayPal sandbox (mobile payment)

In the mobile app: **Tickets** → pick a race → choose a ticket type and quantity → **Cart** → **Checkout**. The PayPal page opens inside the app; sign in with the sandbox buyer account:

| Email | Password |
| --- | --- |
| `sb-v47m1b53353350@personal.example.com` | `TKWRs8<%` |

After the payment the tickets (with QR codes) are in **Profile → My tickets**, a notification is created and a confirmation email is sent by the worker through RabbitMQ.

## Recommender system

Recommended races are shown on the mobile **Home** screen ("Recommended for you"). The algorithm, the path to the main logic (`F1Info&Tickets.Services/Services/RecommenderService.cs`) and screenshots are described in [recommender-dokumentacija.pdf](recommender-dokumentacija.pdf).

## Project structure

| Folder | Content |
| --- | --- |
| `F1Info&Tickets.Model` | Requests, responses, search objects, messaging contracts |
| `F1Info&Tickets.Services` | EF Core database, migrations, seed, business logic, recommender, PayPal |
| `F1Info&Tickets.WebAPI` | REST API, JWT authentication, Swagger |
| `F1Info&Tickets.Worker` | RabbitMQ consumer that sends emails (SMTP) |
| `f1_info_and_tickets_frontend` | Flutter desktop (admin) and mobile (customer) app |
