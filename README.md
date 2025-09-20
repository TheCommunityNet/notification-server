# ComnetWebsocket

A Phoenix WebSocket application for real-time communication and notifications.

## Features

- Real-time WebSocket connections
- Notification tracking system
- PostgreSQL database integration
- Docker containerization
- Phoenix LiveView support

## Prerequisites

- Docker and Docker Compose
- PostgreSQL 14+ (running locally or on a server)
- Git

## Quick Start with Docker Compose

### 1. Clone the Repository

```bash
git clone <repository-url>
cd comnet_websocket
```

### 2. Set Up PostgreSQL Database

Make sure you have PostgreSQL running locally or have access to a PostgreSQL server. Create the database:

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database and user
CREATE DATABASE cn_websocket;
CREATE USER forge WITH PASSWORD 'secret';
GRANT ALL PRIVILEGES ON DATABASE cn_websocket TO forge;
\q
```

### 3. Environment Configuration

Create a `.env` file in the project root with the following variables:

```bash
# Database Configuration
DATABASE_URL=ecto://forge:secret@localhost:5432/cn_websocket

# Phoenix Configuration
PHX_HOST=localhost
PORT=4000
SECRET_KEY_BASE=your_secret_key_here

# Optional: Generate a secret key with: mix phx.gen.secret
# SECRET_KEY_BASE=$(mix phx.gen.secret)
```

### 4. Start the Application

```bash
# Start the Phoenix application
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 5. Database Setup

The application will automatically run database migrations on startup. If you need to run them manually:

```bash
# Run migrations
docker-compose exec websocket /app/bin/comnet_websocket eval "ComnetWebsocket.Release.migrate()"

# Seed the database
docker-compose exec websocket /app/bin/comnet_websocket eval "ComnetWebsocket.Release.seed()"
```

### 6. Access the Application

- **Web Application**: http://localhost:4000
- **Live Dashboard**: http://localhost:4000/dashboard (development only)

## Development Setup

If you prefer to run the application locally without Docker:

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 28+
- PostgreSQL 12+
- Node.js 18+ (for assets)

### Setup

1. **Install dependencies**:
   ```bash
   mix setup
   ```

2. **Configure database**:
   Update `config/dev.exs` with your PostgreSQL credentials:
   ```elixir
   config :comnet_websocket, ComnetWebsocket.Repo,
     username: "your_username",
     password: "your_password",
     hostname: "localhost",
     database: "cn_websocket_dev"
   ```

3. **Start the server**:
   ```bash
   mix phx.server
   ```

## Docker Compose Services

### websocket
- **Image**: Built from local Dockerfile
- **Port**: 4000
- **Environment**: Production mode
- **Database**: Connects to external PostgreSQL

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `ecto://forge:secret@localhost:5432/cn_websocket` |
| `PHX_HOST` | Phoenix host | `localhost` |
| `PORT` | Application port | `4000` |
| `SECRET_KEY_BASE` | Phoenix secret key | Required |
| `POOL_SIZE` | Database connection pool size | `10` |

## API Endpoints

- `GET /` - Home page
- `GET /dashboard` - Live dashboard (development only)
- `WebSocket /socket` - WebSocket endpoint for real-time communication

## Database Schema

The application includes the following main entities:

- **Notifications**: Real-time notification system
- **Notification Tracking**: Tracks notification delivery and status

## Troubleshooting

### Common Issues

1. **Database Connection Errors**:
   - Ensure PostgreSQL is running locally: `pg_isready -h localhost -p 5432`
   - Check database credentials in `.env`
   - Verify database exists: `psql -U forge -d cn_websocket -h localhost`

2. **Port Already in Use**:
   - Change the port in `.env`: `PORT=4001`
   - Or stop conflicting services

3. **Permission Errors**:
   - Ensure Docker has proper permissions
   - Try running with `sudo` if necessary

### Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs websocket

# Follow logs in real-time
docker-compose logs -f websocket
```

## Production Deployment

For production deployment:

1. **Set up production PostgreSQL database**:
   - Ensure you have a production PostgreSQL server running
   - Create the database and user with appropriate permissions
   - Configure network access and security settings

2. **Create production environment file**:
   ```bash
   # Create .env.prod file
   cat > .env.prod << EOF
   DATABASE_URL=ecto://username:password@your-db-host:5432/your_production_db
   PHX_HOST=your-domain.com
   PORT=4000
   SECRET_KEY_BASE=$(mix phx.gen.secret)
   POOL_SIZE=20
   EOF
   ```

3. **Build and run with production environment**:
   ```bash
   # Build the production image
   docker build -t comnet-websocket:prod .

   # Run with production environment
   docker run -d \
     --name comnet-websocket \
     --env-file .env.prod \
     -p 4000:4000 \
     comnet-websocket:prod
   ```

4. **Alternative: Use docker-compose with production environment**:
   ```bash
   # Set environment file
   export ENV_FILE=.env.prod
   
   # Run with production settings
   docker compose --env-file .env.prod up -d
   ```

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
- [Ecto Database Library](https://hexdocs.pm/ecto/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
