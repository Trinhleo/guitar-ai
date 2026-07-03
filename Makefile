.PHONY: test migrate run smoke tidy frontend-test frontend-run docker-up docker-down

test:
	cd backend && GO_ENV=test go test ./... -count=1

migrate:
	cd backend && go run ./cmd/server migrate

run:
	cd backend && go run ./cmd/server

smoke:
	./backend/scripts/smoke.sh

tidy:
	cd backend && go mod tidy

frontend-test:
	cd frontend/apps/app_web && flutter test

frontend-run:
	cd frontend/apps/app_web && flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

docker-up:
	docker compose up -d --build

docker-down:
	docker compose down
